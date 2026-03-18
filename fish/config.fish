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
set -gx PATH /home/julio/.opencode/bin $PATH
set -gx PATH $HOME/.local/share/nvim/mason/bin $PATH
set -gx PATH /opt/cuda/bin $PATH

# ALIASES

alias vi nvim
alias tt taskwarrior-tui
alias jail ~/.config/scripts/ai-jail
alias oc "~/.config/scripts/ai-jail opencode"

# # >>> conda initialize >>>
# # !! Contents within this block are managed by 'conda init' !!
# if test -f /usr/bin/conda
#     eval /usr/bin/conda "shell.fish" hook $argv | source
# else
#     if test -f "/usr/etc/fish/conf.d/conda.fish"
#         . "/usr/etc/fish/conf.d/conda.fish"
#     else
#         set -x PATH /usr/bin $PATH
#     end
# end
# # <<< conda initialize <<<

starship init fish | source

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/julio/.lmstudio/bin
# End of LM Studio CLI section
