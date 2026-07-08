if status is-interactive
    # Commands to run in interactive sessions can go here
end

# pnpm
set -gx PNPM_HOME "/home/julio/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end

# qemu
set -gx LIBVIRT_DEFAULT_URI "qemu:///system"

# envs
set -gx EDITOR nvim
set -gx THEME (gsettings get org.gnome.desktop.interface color-scheme)
set -gx DEBUGINFOD_URLS "https://debuginfod.archlinux.org"

# Java
set -gx JAVA_HOME /usr/lib/jvm/default

# Go
set -g GOPATH $HOME/go
# set -gx PATH $GOPATH/bin $PATH

# PATH

set -gx PATH /home/julio/.spicetify $PATH
set -gx PATH bin $PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH
set -gx PATH $GOPATH/bin $PATH
set -gx PATH node_modules/.bin $PATH
set -gx PATH $GOPATH/bin $PATH
set -gx PATH $HOME/.local/share/nvim/mason/bin $PATH
set -gx PATH /opt/cuda/bin $PATH

# NOMA
if test -L "$HOME/node/current"
    if not contains -- "$HOME/node/current/bin" $PATH
        set -gx PATH "$HOME/node/current/bin" $PATH
    end
else if test -L "$HOME/node/versions/default"
    ln -sfn "$HOME/node/versions/default" "$HOME/node/current"
    if not contains -- "$HOME/node/current/bin" $PATH
        set -gx PATH "$HOME/node/current/bin" $PATH
    end
end

# ALIASES

alias vi nvim
alias tt taskwarrior-tui

starship init fish | source
