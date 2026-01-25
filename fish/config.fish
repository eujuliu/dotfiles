if status is-interactive
    # Commands to run in interactive sessions can go here
end

# pnpm
set -gx PNPM_HOME "/home/julio/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end

set -gx LIBVIRT_DEFAULT_URI "qemu:///system"
set -gx EDITOR nvim

set -gx PATH bin $PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH
set -gx JAVA_HOME /usr/lib/jvm/default

# NodeJS
set -gx PATH node_modules/.bin $PATH

# Go
set -g GOPATH $HOME/go
set -gx PATH $GOPATH/bin $PATH

# Aliases
alias vi nvim
alias tt taskwarrior-tui
alias jail ~/.config/scripts/ai-jail
alias oc "~/.config/scripts/ai-jail opencode"

# opencode
fish_add_path /home/julio/.opencode/bin

starship init fish | source

# load_nvm >/dev/stderr

fish_add_path /home/julio/.spicetify
