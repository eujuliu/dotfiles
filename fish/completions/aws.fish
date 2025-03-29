function __fish_aws_completions
    set -lx COMP_LINE (commandline -cp)
    set -lx COMP_POINT (string length -- $COMP_LINE)
    string split -- '\n' -- (aws_completer) | string trim
end

complete --command aws --arguments '(__fish_aws_completions)'
