set -g PATH $HOME/.pyenv/bin $PATH
status --is-interactive; and source (pyenv init --path | psub)
status --is-interactive; and source (pyenv init - | psub)
