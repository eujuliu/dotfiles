function taskmd --description 'Import Markdown tasks to Taskwarrior'
    set -l script_path "$HOME/.config/scripts/taskmd.sh"

    bash $script_path $argv
end
