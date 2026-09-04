#!/bin/bash

append_line_once() {
    local file_path="$1"
    local line_to_add="$2"

    touch "$file_path"
    if ! grep -Fqx "$line_to_add" "$file_path" 2>/dev/null; then
        printf '%s\n' "$line_to_add" >> "$file_path"
    fi
}

install_oh_my_zsh_if_missing() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "   - Oh My Zsh already installed, skipping"
        return 0
    fi

    RUNZSH=no CHSH=no sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended
}

ensure_downloads_dir() {
    mkdir -p "$HOME/Downloads"
}
