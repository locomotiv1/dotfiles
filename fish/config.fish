set -g fish_greeting

# if status is-interactive        \
#     starship init fish | source  \   this was overriting my prompt with: "~via v21.6.1" for some reason and i couldn't change it
# end                               \

# List Directory
alias ls="lsd"
alias l="ls -l"
alias la="ls -a"
alias lla="ls -la"
alias lt="ls --tree"

# Handy change dir shortcuts
abbr .. 'cd ..'
abbr ... 'cd ../..'
abbr .3 'cd ../../..'
abbr .4 'cd ../../../..'
abbr .5 'cd ../../../../..'

# Always mkdir a path (this doesn't inhibit functionality to make a single dir)
abbr mkdir 'mkdir -p'

# Fixes "Error opening terminal: xterm-kitty" when using the default kitty term to open some programs through ssh
alias ssh='kitten ssh'
fish_add_path /home/kacper/.spicetify

# Created by `pipx` on 2024-03-26 14:18:16
set PATH $PATH /home/kacper/.local/bin
