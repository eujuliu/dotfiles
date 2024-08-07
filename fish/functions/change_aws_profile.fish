function change_aws_profile
    set profiles (aws configure list-profiles)

    if test (count $profiles) -eq 0
        echo "No AWS profiles found."
        return 1
    end

    set selected_profile (printf '%s\n' $profiles | fzf --prompt="Select AWS profile: ")

    if test -z "$selected_profile"
        echo "No profile selected."
        return 1
    end

    export AWS_PROFILE=$selected_profile
    echo "AWS profile changed to $AWS_PROFILE"
end