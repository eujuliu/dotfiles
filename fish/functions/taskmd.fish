function taskmd --description 'Import Markdown tasks to Taskwarrior'
    set -l md_file $argv[1]
    set -l project_name $argv[2]
    set -l script_path "$HOME/.config/scripts/taskmd.sh"

    if not test -f $script_path
        echo "Error: Bash script not found at $script_path"
        echo "Please place the bash script there or edit the function."
        return 1
    end

    if test -z "$md_file"
        echo "Usage: taskmd <markdown_file.md> <project_name (optional)>"
        echo "Example: taskmd tasks.md tasks"
        return 1
    end

    if not test -f $md_file
        echo "Error: File not found: $md_file"
        return 1
    end

    bash $script_path $md_file $project_name
end
