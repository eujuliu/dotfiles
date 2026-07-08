function nvm --description "Simple Node version manager for fish shell"
    set -g NODEVM "$HOME/.node"
    set -g NODEVM_VERSIONS "$NODEVM/versions"
    set -g NODEVM_DEFAULT "$NODEVM/default"

    set -l cmd $argv[1]

    function __install
        set -l ver $argv[1]
        if test -z "$ver"
            echo "Missing version. Example: nvm install 24.18.0" >&2
            return 1
        end

        if not string match -rq '^[0-9]+\.[0-9]+\.[0-9]+$' -- $ver
            echo "Version must be X.Y.Z (without leading v)" >&2
            return 1
        end

        set -l arch ""
        switch (uname -m)
            case x86_64 amd64
                set arch x64
            case aarch64 arm64
                set arch arm64
            case armv7l
                set arch armv7l
            case '*'
                echo "Unsupported architecture: "(uname -m) >&2
                return 1
        end

        set -l platform linux
        set -l tarball "node-v$ver-$platform-$arch.tar.xz"
        set -l url "https://nodejs.org/dist/v$ver/$tarball"

        mkdir -p "$NODEVM_VERSIONS"
        or return 1

        set -l dest "$NODEVM_VERSIONS/$ver"
        if test -d "$dest"
            echo "Version $ver already installed at $dest"
            return 0
        end

        set -l tmpdir (mktemp -d)
        or begin
            echo "Failed to create temp dir" >&2
            return 1
        end

        set -l tarpath "$tmpdir/$tarball"

        echo "Downloading $url ..."
        curl -fL "$url" -o "$tarpath"
        if test $status -ne 0
            echo "Download failed for $url" >&2
            rm -rf "$tmpdir"
            return 1
        end

        mkdir -p "$dest"
        tar -xJf "$tarpath" -C "$tmpdir"
        if test $status -ne 0
            echo "Extraction failed" >&2
            rm -rf "$tmpdir" "$dest"
            return 1
        end

        set -l extracted "$tmpdir/node-v$ver-$platform-$arch"
        if not test -d "$extracted"
            echo "Unexpected archive layout" >&2
            rm -rf "$tmpdir" "$dest"
            return 1
        end

        cp -R "$extracted/"* "$dest/"
        if test $status -ne 0
            echo "Failed to install files to $dest" >&2
            rm -rf "$tmpdir" "$dest"
            return 1
        end

        rm -rf "$tmpdir"

        if test -x "$dest/bin/node" -a -x "$dest/bin/npm" -a -x "$dest/bin/npx"
            echo "Installed Node $ver in $dest"
        else
            echo "Install incomplete (node/npm/npx missing in $dest/bin)" >&2
            return 1
        end
    end

    switch "$cmd"
        case '' help -h --help
            echo "Usage:"
            echo "  nvm list"
            echo "  nvm install <version>"
            echo "  nvm use <version> [--default]"
            echo "  nvm current"
            return 0

        case list
            set -l json (curl -fsSL "https://nodejs.org/dist/index.json")

            if test $status -ne 0
                echo "Failed to fetch versions from nodejs.org" >&2
                return 1
            end

            set -l installed

            for dir in $NODEVM_VERSIONS/*
                if test -d "$dir"
                    set installed $installed (basename "$dir")
                end
            end

            set -l ver (
                begin
                    printf "%-10s %-10s %-12s %-10s %s\n" \
                        "Installed" "Version" "LTS" "Security" "Date"

                    echo $json | jq -r '
                        .[] |
                        [
                            .version[1:],
                            (if .lts then "lts/" + .lts else "None" end),
                            (if .security then "Secure" else "InSecure" end),
                            .date
                        ] |
                        @tsv
                    ' | while read -l vers lts security date
                        if  contains -- $vers $installed 
                          set mark "☒"
                        else
                          set mark "☐"
                        end

                        printf "%-10s %-10s %-12s %-10s %s\n" \
                            "$mark" "$vers" "$lts" "$security" "$date"
                    end
                end |
                fzf \
                    --header-lines=1 \
                    --height=20 \
                    --layout=reverse \
                    --border \
                    --cycle \
                    --info=inline |
                awk '{print $2}'
            )

            if test -n "$ver"
                __install $ver
            end
            return $status

        case install
            set -l ver $argv[2]
            __install $ver

        case use
            set -l ver $argv[2]
            set -l opt $argv[3]

            if test -z "$ver"
                echo "Missing version. Example: nvm use 24.18.0 [--default]" >&2
                return 1
            end

            set -l src "$NODEVM_VERSIONS/$ver"
            if not test -d "$src"
                echo "Version $ver is not installed. Run: nvm install $ver" >&2
                return 1
            end

            mkdir -p "$NODEVM"
            ln -sfn "$src" "$NODEVM_DEFAULT"
            or begin
                echo "Failed to set current symlink" >&2
                return 1
            end

            if test "$opt" = --default
                ln -sfn "$src" "$NODEVM_VERSIONS/default"
                or begin
                    echo "Failed to set default symlink" >&2
                    return 1
                end
                echo "Default set: $NODEVM_VERSIONS/default -> $src"
            end

            set -l cleaned
            for p in $PATH
                if string match -rq "^$NODEVM/.*/bin\$" -- $p
                    continue
                end
                if test "$p" = "$NODEVM_DEFAULT/bin"
                    continue
                end
                set cleaned $cleaned $p
            end
            set -gx PATH "$NODEVM_DEFAULT/bin" $cleaned

            echo "Now using Node $ver"
            node -v

        case current
            if test -L "$NODEVM_DEFAULT"
                echo "current -> "(readlink "$NODEVM_DEFAULT")
                if test -x "$NODEVM_DEFAULT/bin/node"
                    "$NODEVM_DEFAULT/bin/node" -v
                end
            else
                echo "No active version set"
                return 1
            end

        case '*'
            echo "Unknown command: $cmd" >&2
            return 1
    end
end
