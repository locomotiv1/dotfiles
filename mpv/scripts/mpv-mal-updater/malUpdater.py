import hashlib
import json
import os
import re
import sys
import time
import webbrowser
from collections.abc import Iterator
from dataclasses import dataclass
from typing import Any
import requests
from guessit import guessit

@dataclass
class SeasonEpisodeInfo:
    season_id: int | None
    season_title: str | None
    progress: int | None
    episodes: int | None
    relative_episode: int | None

@dataclass
class AnimeInfo:
    anime_id: int | None
    anime_name: str | None
    current_progress: int | None
    total_episodes: int | None
    file_progress: int | None
    current_status: str | None
    mal_id: int | None = None

    def __iter__(self) -> Iterator[Any]:
        return iter((self.anime_id, self.anime_name, self.current_progress, self.total_episodes, self.file_progress, self.current_status, self.mal_id))

@dataclass
class FileInfo:
    name: str
    episode: int
    year: str
    file_format: str | None

    def __iter__(self) -> Iterator[Any]:
        return iter((self.name, self.episode, self.year, self.file_format))

class MALUpdater:
    MAL_API_URL: str = "https://api.myanimelist.net/v2"
    AUTH_PATH: str = os.path.join(os.path.dirname(__file__), "mal_auth.json")
    CACHE_PATH: str = os.path.join(os.path.dirname(__file__), "cache.json")
    OPTIONS: dict[str, Any] = {"excludes": ["country", "language"]}
    CACHE_REFRESH_RATE: int = 24 * 60 * 60
    CORRECTED_CACHE_REFRESH_RATE: int = 28 * 24 * 60 * 60
    CACHE_MODE: str = "NORMAL"
    _CHARS_TO_REPLACE: str = r'\/:!*?"<>|._-'
    CLEAN_PATTERN: str = rf"(?: - Movie)|[{re.escape(_CHARS_TO_REPLACE)}](?!\s*\d)"
    VERSION_REGEX: re.Pattern[str] = re.compile(r"(E\d+)v\d")

    def __init__(self, options: dict[str, Any]) -> None:
        self.access_token: str | None = self.load_access_token()
        self.options: dict[str, Any] = options
        self._cache: dict[str, Any] | None = None
        
        try:
            hours = float(self.options.get("CACHE_REFRESH_RATE", self.CACHE_REFRESH_RATE // 3600))
            self.CACHE_REFRESH_RATE = int(hours * 3600)
        except Exception:
            pass
        self.CACHE_MODE = str(self.options.get("CACHE_MODE", self.CACHE_MODE)).upper()

    def load_access_token(self) -> str | None:
        try:
            if not os.path.exists(self.AUTH_PATH):
                return None
            with open(self.AUTH_PATH, encoding="utf-8") as f:
                auth_data = json.load(f)
            return auth_data.get("access_token")
        except Exception as e:
            print(f"Error reading access token: {e}")
            return None

    def _hash_path(self, path: str) -> str:
        return hashlib.sha256(path.encode("utf-8")).hexdigest()

    def cache_to_file(self, path: str, guessed_name: str, absolute_progress: int, result: AnimeInfo) -> None:
        dir_hash = self._hash_path(os.path.dirname(path))
        cache = self.load_cache()
        existing_entry = cache.get(dir_hash, {})
        is_corrected = bool(existing_entry.get("corrected", False))
        anime_id, _, current_progress, total_episodes, relative_progress, current_status, mal_id = result
        now = time.time()
        ttl_refresh_rate = self.CORRECTED_CACHE_REFRESH_RATE if is_corrected else self.CACHE_REFRESH_RATE
        cache[dir_hash] = {
            "guessed_name": guessed_name,
            "anime_id": anime_id,
            "mal_id": mal_id or anime_id,
            "current_progress": current_progress,
            "relative_progress": f"{absolute_progress}->{relative_progress}",
            "total_episodes": total_episodes,
            "current_status": current_status,
            "corrected": is_corrected,
            "ttl": now + ttl_refresh_rate,
        }
        self.save_cache(cache)

    def check_and_clean_cache(self, path: str, guessed_name: str) -> dict[str, Any] | None:
        cache = self.load_cache()
        now = time.time()
        changed = False
        for k, v in list(cache.items()):
            if v.get("ttl", 0) < now:
                cache.pop(k, None)
                changed = True
        dir_hash = self._hash_path(os.path.dirname(path))
        entry = cache.get(dir_hash)
        
        if entry and entry.get("guessed_name") == guessed_name:
            apply_sliding = self.CACHE_MODE == "SLIDING" or entry.get("corrected", False)
            if apply_sliding:
                refresh_rate = self.CORRECTED_CACHE_REFRESH_RATE if entry.get("corrected", False) else self.CACHE_REFRESH_RATE
                if entry.get("ttl", 0) <= now + (refresh_rate // 2):
                    entry["ttl"] = now + refresh_rate
                    cache[dir_hash] = entry
                    changed = True
            if changed:
                self.save_cache(cache)
            return entry
        if changed:
            self.save_cache(cache)
        return None

    def load_cache(self) -> dict[str, Any]:
        if self._cache is None:
            try:
                if not os.path.exists(self.CACHE_PATH):
                    self._cache = {}
                else:
                    with open(self.CACHE_PATH, encoding="utf-8") as f:
                        self._cache = json.load(f)
            except Exception:
                self._cache = {}
        assert self._cache is not None
        return self._cache

    def save_cache(self, cache: dict[str, Any]) -> None:
        try:
            with open(self.CACHE_PATH, "w", encoding="utf-8") as f:
                json.dump(cache, f, ensure_ascii=False, indent=2)
            self._cache = cache
        except Exception as e:
            print(f"Failed saving cache.json: {e}")

    def refresh_access_token(self) -> bool:
        print("Access token expired. Attempting to refresh...")
        try:
            with open(self.AUTH_PATH, encoding="utf-8") as f:
                auth_data = json.load(f)
            client_id = auth_data.get("client_id")
            refresh_token = auth_data.get("refresh_token")
            data = {
                "client_id": client_id,
                "grant_type": "refresh_token",
                "refresh_token": refresh_token,
            }
            response = requests.post("https://myanimelist.net/v1/oauth2/token", data=data)
            if response.status_code == 200:
                token_data = response.json()
                auth_data["access_token"] = token_data["access_token"]
                auth_data["refresh_token"] = token_data["refresh_token"]
                with open(self.AUTH_PATH, "w", encoding="utf-8") as f:
                    json.dump(auth_data, f, indent=4)
                self.access_token = token_data["access_token"]
                return True
            return False
        except Exception:
            return False

    def make_api_request(self, endpoint: str, method: str = "GET", data: dict[str, Any] | None = None, is_retry: bool = False) -> dict[str, Any] | None:
        headers = {"Authorization": f"Bearer {self.access_token}"}
        url = f"{self.MAL_API_URL}/{endpoint}"
        try:
            if method == "GET":
                response = requests.get(url, headers=headers, params=data, timeout=10)
            elif method in {"PATCH", "POST", "PUT"}:
                headers["Content-Type"] = "application/x-www-form-urlencoded"
                response = requests.patch(url, headers=headers, data=data, timeout=10)
            else:
                return None
            
            if response.status_code == 401 and not is_retry:
                if self.refresh_access_token():
                    return self.make_api_request(endpoint, method, data, is_retry=True)
            if response.status_code in {200, 201, 204}:
                return response.json() if response.text else {}
            
            print(f"API request failed: {response.status_code} - {response.text}")
            return None
        except Exception as e:
            return None

    def fix_filename(self, path_parts: list[str]) -> list[str]:
        path_parts[-1] = re.sub(self.CLEAN_PATTERN, " ", path_parts[-1])
        path_parts[-1] = " ".join(path_parts[-1].split())
        match = self.VERSION_REGEX.search(path_parts[-1])
        if match:
            episode = match.group(1)
            path_parts[-1] = path_parts[-1].replace(match.group(0), episode)
        return path_parts

    def parse_filename(self, filepath: str) -> FileInfo:
        path_parts = self.fix_filename(filepath.replace("\\", "/").split("/"))
        filename = path_parts[-1]
        guessed_name, season, part, year = "", "", "", ""
        remaining: list[int] = []

        guess = guessit(filename, self.OPTIONS)
        episode = guess.get("episode", None)
        season = guess.get("season", "")
        part = str(guess.get("part", ""))
        year = str(guess.get("year", ""))
        file_format = None
        
        other = guess.get("other", "")
        if other == "Original Animated Video":
            file_format = "OVA"
        elif other == "Original Net Animation":
            file_format = "ONA"

        if guess.get("episode_title", "").isdigit() and "episode" not in guess:
            episode = int(guess.get("episode_title"))
        if isinstance(episode, list):
            remaining = episode[:-1]
            episode = episode[-1]
        if isinstance(season, list):
            if episode is None and len(season) > 1:
                episode = season[-1]
            season = season[0]

        episode = episode or 1
        season = str(season)
        keys = list(guess.keys())
        episode_index = keys.index("episode") if "episode" in guess else 1
        season_index = keys.index("season") if "season" in guess else -1
        title_in_filename = "title" in guess and (episode_index > 0 and (season_index > 0 or season_index == -1))
        
        if title_in_filename:
            guessed_name = guess["title"]
        else:
            for depth in [2, 3]:
                folder_guess = guessit(path_parts[-depth], self.OPTIONS) if len(path_parts) > depth - 1 else None
                if folder_guess:
                    guessed_name = str(folder_guess.get("title", ""))
                    season = season or str(folder_guess.get("season", ""))
                    part = part or str(folder_guess.get("part", ""))
                    year = year or str(folder_guess.get("year", ""))
                    if guessed_name:
                        break
        
        if not guessed_name:
            raise Exception("Couldn't find title in filename.")
            
        if remaining:
            guessed_name += " " + " ".join(str(ep) for ep in remaining)
        if season and (int(season) > 1 or part):
            guessed_name += f" Season {season}"
        
        episode_title_index = keys.index("episode_title") if "episode_title" in guess else 99
        if part and keys.index("part") < episode_title_index:
            guessed_name += f" Part {part}"
            
        return FileInfo(guessed_name, episode, year, file_format)

    def get_anime_info_and_progress(self, file_info: FileInfo) -> AnimeInfo:
        name, file_progress, _year, _file_format = file_info
        endpoint = "anime"
        params = {"q": name, "limit": 5, "fields": "id,title,num_episodes,my_list_status"}
        response = self.make_api_request(endpoint, method="GET", data=params)
        
        if not response or "data" not in response or not response["data"]:
            raise Exception("Couldn't find an anime from this title.")
            
        first_result = response["data"][0]["node"]
        mal_id = first_result["id"]
        title = first_result["title"]
        total_episodes = first_result.get("num_episodes")
        
        current_progress = None
        current_status = None
        my_list_status = first_result.get("my_list_status")
        
        if my_list_status:
            current_progress = my_list_status.get("num_episodes_watched")
            current_status = my_list_status.get("status")
            
        return AnimeInfo(mal_id, title, current_progress, total_episodes, file_progress, current_status, mal_id)

    def handle_filename(self, filename: str) -> None:
        file_info = self.parse_filename(filename)
        cache_entry = self.check_and_clean_cache(filename, file_info.name)
        result = None

        if cache_entry:
            left, right = cache_entry.get("relative_progress", "0->0").split("->")
            offset = int(left) - int(right)
            relative_episode = file_info.episode - offset
            if 1 <= relative_episode <= (cache_entry.get("total_episodes") or 999):
                result = AnimeInfo(
                    cache_entry["anime_id"],
                    cache_entry["guessed_name"],
                    cache_entry["current_progress"],
                    cache_entry["total_episodes"],
                    relative_episode,
                    cache_entry["current_status"],
                    cache_entry.get("mal_id", cache_entry["anime_id"])
                )

        if result is None:
            result = self.get_anime_info_and_progress(file_info)

        if result:
            payload = {
                "anime_id": result.anime_id,
                "mal_id": result.mal_id or result.anime_id,
                "anime_name": result.anime_name,
                "episode": result.file_progress,
                "current_progress": result.current_progress,
                "total_episodes": result.total_episodes,
                "current_status": result.current_status,
                "guessed_name": file_info.name,
                "absolute_episode": file_info.episode,
            }
            print(f"INFO:{json.dumps(payload)}")
            if result.current_progress is not None:
                self.cache_to_file(filename, file_info.name, file_info.episode, result)

    def update_episode_count(self, result: AnimeInfo) -> AnimeInfo:
        anime_id, anime_name, current_progress, total_episodes, file_progress, current_status, mal_id = result
        if anime_id is None:
            raise Exception("Anime ID missing.")

        if current_progress is None and current_status is None:
            if self.options.get("ADD_ENTRY_IF_MISSING", False):
                initial_status = "watching"
                if file_progress == total_episodes and self.options.get("SET_TO_COMPLETED_AFTER_LAST_EPISODE_CURRENT", False):
                    initial_status = "completed"
                self._save_media_list_entry(anime_id, initial_status, file_progress, False)
                osd_message(f'Added "{anime_name}" to your list.')
                return AnimeInfo(anime_id, anime_name, file_progress, total_episodes, file_progress, initial_status, mal_id)
            raise Exception("Anime not on your list.")

        status_to_set = None
        is_rewatching = False

        if current_status == "completed" and file_progress == 1 and self.options.get("SET_COMPLETED_TO_REWATCHING_ON_FIRST_EPISODE", False):
            status_to_set = "watching"
            is_rewatching = True
        elif current_status in {"watching", "plan_to_watch", "on_hold"}:
            if file_progress and current_progress is not None and file_progress <= current_progress:
                raise Exception("Episode not new. Skipping update.")
            status_to_set = "watching"
        else:
            raise Exception(f"Status '{current_status}' is unmodifiable.")

        if file_progress == total_episodes and self.options.get("SET_TO_COMPLETED_AFTER_LAST_EPISODE_CURRENT", False):
            status_to_set = "completed"
            is_rewatching = False

        response = self._save_media_list_entry(anime_id, status_to_set, file_progress, is_rewatching)
        if response and "num_episodes_watched" in response:
            updated_progress = response["num_episodes_watched"]
            updated_status = response["status"]
            osd_message(f'Updated "{anime_name}" to: {updated_progress}')
            return AnimeInfo(anime_id, anime_name, updated_progress, total_episodes, file_progress, updated_status, mal_id)
            
        raise Exception("Failed to update.")

    def _save_media_list_entry(self, anime_id: int, status: str | None, progress: int | None, is_rewatching: bool = False) -> dict[str, Any]:
        endpoint = f"anime/{anime_id}/my_list_status"
        update_data = {}
        if status: update_data["status"] = status
        if progress is not None: update_data["num_watched_episodes"] = progress
        if is_rewatching: update_data["is_rewatching"] = True
        
        return self.make_api_request(endpoint, method="PATCH", data=update_data)

    def update_with_preloaded_info(self, filepath: str, anime_info: dict[str, Any]) -> None:
        result = AnimeInfo(
            anime_id=anime_info.get("anime_id"),
            anime_name=anime_info.get("anime_name"),
            current_progress=anime_info.get("current_progress"),
            total_episodes=anime_info.get("total_episodes"),
            file_progress=anime_info.get("episode"),
            current_status=anime_info.get("current_status"),
            mal_id=anime_info.get("mal_id")
        )
        result = self.update_episode_count(result)
        if result and result.current_progress is not None:
            self.cache_to_file(filepath, anime_info["guessed_name"], anime_info["absolute_episode"], result)

    def correct_anime_id(self, filepath: str, mal_id: int, relative_episode: int | None, target_status: str | None, anime_info: dict[str, Any]) -> None:
        selected_status = target_status if target_status else None
        guessed_name = anime_info.get("guessed_name", "")
        absolute_episode = anime_info.get("absolute_episode", 1)
        existing_anime_id = anime_info.get("anime_id")
        id_changed = existing_anime_id != mal_id
        
        anime_name = anime_info.get("anime_name") or guessed_name
        total_episodes = anime_info.get("total_episodes")
        current_progress = anime_info.get("current_progress")
        current_status = anime_info.get("current_status")

        if id_changed:
            response = self.make_api_request(f"anime/{mal_id}", method="GET", data={"fields": "id,title,num_episodes,my_list_status"})
            if not response:
                raise Exception(f"Could not find anime with MAL ID {mal_id}.")
            
            anime_name = response.get("title", guessed_name)
            total_episodes = response.get("num_episodes")
            entry = response.get("my_list_status")
            current_progress = entry.get("num_episodes_watched") if entry else current_progress
            current_status = entry.get("status") if entry else current_status

        existing_relative_episode = anime_info.get("episode") or absolute_episode
        mapped_relative_episode = max(1, relative_episode if relative_episode and relative_episode > 0 else existing_relative_episode)
        relative_changed = mapped_relative_episode != existing_relative_episode

        status_changed = False
        if selected_status and selected_status != current_status:
            self._save_media_list_entry(mal_id, selected_status, None, False)
            current_status = selected_status
            status_changed = True

        changes = [
            f"ID: {existing_anime_id or '?'}->{mal_id}" if id_changed else None,
            f"Mapped {absolute_episode}->{mapped_relative_episode}" if relative_changed else None,
            f"Status: {current_status}" if status_changed else None,
        ]
        changes = [c for c in changes if c]

        if not changes:
            osd_message("No correction changes detected.")
            return

        dir_hash = self._hash_path(os.path.dirname(filepath))
        cache = self.load_cache()
        existing_entry = cache.get(dir_hash, {})
        
        cache[dir_hash] = {
            "guessed_name": guessed_name,
            "anime_id": mal_id,
            "mal_id": mal_id,
            "current_progress": current_progress,
            "relative_progress": f"{absolute_episode}->{mapped_relative_episode}",
            "total_episodes": total_episodes,
            "current_status": current_status,
            "corrected": True if id_changed else existing_entry.get("corrected", False),
            "ttl": time.time() + self.CORRECTED_CACHE_REFRESH_RATE,
        }
        self.save_cache(cache)
        
        osd_message(f'Corrected "{anime_name}" (ID: {mal_id}) | ' + " | ".join(changes))
        
        print(f"INFO:{json.dumps({**cache[dir_hash], 'episode': mapped_relative_episode, 'absolute_episode': absolute_episode})}")

def osd_message(msg: str) -> None:
    print(f"OSD:{msg}")

def run_action(updater: MALUpdater) -> None:
    action = sys.argv[2]
    filepath = sys.argv[1]
    
    if action == "update_with_info" and len(sys.argv) > 4:
        anime_info_json = json.loads(sys.argv[4])
        updater.update_with_preloaded_info(filepath, anime_info_json)
    elif action == "correct":
        anime_info = json.loads(sys.argv[-1])
        if len(sys.argv) > 7:
            updater.correct_anime_id(filepath, int(sys.argv[4]), int(sys.argv[5]), sys.argv[6], anime_info)
        else:
            updater.correct_anime_id(filepath, int(sys.argv[4]), None, sys.argv[5], anime_info)
    else:
        updater.handle_filename(filepath)

def main() -> None:
    if sys.stdout.encoding != "utf-8":
        try:
            sys.stdout.reconfigure(encoding="utf-8")
            sys.stderr.reconfigure(encoding="utf-8")
        except Exception as e:
            print(f"Couldn't reconfigure: {e}", file=sys.stderr)

    options = {
        "SET_COMPLETED_TO_REWATCHING_ON_FIRST_EPISODE": False,
        "UPDATE_PROGRESS_WHEN_REWATCHING": True,
        "SET_TO_COMPLETED_AFTER_LAST_EPISODE_CURRENT": False,
        "SET_TO_COMPLETED_AFTER_LAST_EPISODE_REWATCHING": True,
        "ADD_ENTRY_IF_MISSING": False,
        "CACHE_REFRESH_RATE": MALUpdater.CACHE_REFRESH_RATE // 3600,
        "CACHE_MODE": MALUpdater.CACHE_MODE,
    }
    
    if len(sys.argv) > 3:
        try:
            user_options = json.loads(sys.argv[3])
            options.update(user_options)
        except Exception:
            pass

    updater = MALUpdater(options)
    try:
        run_action(updater)
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
