function set_node_symlinks
    sudo ln -sf $(nvm which default) /usr/local/bin/node
    sudo ln -sf ~/.nvm/versions/node/$(nvm version default)/bin/npm /usr/local/bin/npm
    sudo ln -sf ~/.nvm/versions/node/$(nvm version default)/bin/npx /usr/local/bin/npx
end
