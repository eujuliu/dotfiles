if status is-interactive
    # Commands to run in interactive sessions can go here
end

fish_add_path $HOME/.local/bin

set -x GOPATH $HOME/go
set -x PATH $PATH $GOPATH/bin
set -x LIBVIRT_DEFAULT_URI "qemu:///system"

starship init fish | source

# pnpm
set -gx PNPM_HOME "/home/julio/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

alias vi "nvim"
alias tt "taskwarrior-tui"
