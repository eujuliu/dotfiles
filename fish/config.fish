if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -Ux PYENV_ROOT $HOME/.pyenv
fish_add_path $PYENV_ROOT/bin

fish_add_path $HOME/.local/bin

starship init fish | source
pyenv init - fish | source

# pnpm
set -gx PNPM_HOME "/home/julio/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/julio/.lmstudio/bin
# End of LM Studio CLI section

