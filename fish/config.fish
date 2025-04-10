if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -Ux PYENV_ROOT $HOME/.pyenv
fish_add_path $PYENV_ROOT/bin

starship init fish | source
pyenv init - fish | source
