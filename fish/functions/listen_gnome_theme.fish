function listen_gnome_theme --description "Listen for GNOME color-scheme changes"
    set -g current_theme (gsettings get org.gnome.desktop.interface color-scheme)

    gsettings monitor org.gnome.desktop.interface color-scheme | while read -l key value
        set -g current_theme (string replace "'" "" -- $value)
        echo "Theme changed → $current_theme"
    end
end
