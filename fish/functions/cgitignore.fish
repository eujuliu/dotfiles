function cgitignore
    if test (count $argv) -lt 1
        echo "Usage: cgitignore {LANGUAGE}"
        return 1
    end

    set language $argv[1]

    echo "Creating .gitignore for $language..."
    
    curl -LJ https://raw.githubusercontent.com/github/gitignore/refs/heads/main/$language.gitignore >> .gitignore 2>/tmp/curl_error
    
    if test $status -ne 0
        set error_msg (cat /tmp/curl_error)
        echo "Error: Failed to create .gitignore file for $language."
        echo "Curl error: $error_msg"
        rm -f /tmp/curl_error
        return 1
    else
        echo ".gitignore created successfully!"
        rm -f /tmp/curl_error
    end
end