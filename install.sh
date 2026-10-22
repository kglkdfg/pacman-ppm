#!/usr/bin/env bash

# ==============================================================================
#  ppm (Pacman Package Manager Wrapper)
#  Copyright (C) 2026 kglkdfg
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program. If not, see <https://gnu.org>.
# ==============================================================================

set -e
USER_NAME=$(whoami)

# --- 1. ОПРЕДЕЛЕНИЕ ТЕКУЩЕЙ ОБОЛОЧКИ ---
PARENT_PROC=$(ps -p $PPID -o comm=)

case "$PARENT_PROC" in
    *zsh*)  CURRENT_SHELL="zsh" ;;
    *fish*) CURRENT_SHELL="fish" ;;
    *bash*) CURRENT_SHELL="bash" ;;
    *)      CURRENT_SHELL="unknown" ;;
esac

echo "🚀 Starting PPM installer from shell: $PARENT_PROC"
echo "👤 Target user: $USER_NAME"

# --- 2. БАЗОВАЯ ПРОВЕРКА ПАКЕТОВ ---
echo "📦 Checking required dependencies..."
sudo pacman -S --needed --noconfirm paru coreutils

# --- 3. ТОЧЕЧНАЯ НАСТРОЙКА ПОД ТЕКУЩУЮ ОБОЛОЧКУ ---
PPM_SH_CODE="
# Custom minimal package manager (ppm)
ppm() {
    if [[ \"\$1\" == \"install\" ]]; then
        shift; sudo pacman -S \"\$@\"
    elif [[ \"\$1\" == \"remove\" ]]; then
        shift; sudo pacman -Rns \"\$@\"
    elif [[ \"\$1\" == \"update\" ]]; then
        sudo pacman -Syu
    elif [[ \"\$1\" == \"search\" ]]; then
        shift; pacman -Ss \"\$@\"
    elif [[ \"\$1\" == \"clean\" ]]; then
        sudo pacman -Sc
    elif [[ \"\$1\" == \"build\" ]]; then
        shift; paru -S \"\$@\"
    else
        echo \"Использование: ppm [install|remove|update|search|clean|build] пакет\"
    fi
}"

if [ "$CURRENT_SHELL" = "bash" ]; then
    echo "🛠️ Configuring PPM for Bash..."
    if ! grep -q "ppm()" "$HOME/.bashrc"; then
        echo "$PPM_SH_CODE" >> "$HOME/.bashrc"
    fi

elif [ "$CURRENT_SHELL" = "zsh" ]; then
    echo "🛠️ Configuring PPM for Zsh..."
    if ! grep -q "ppm()" "$HOME/.zshrc"; then
        echo "$PPM_SH_CODE" >> "$HOME/.zshrc"
        echo "compdef '_arguments \"1:Action:(install remove update search clean build)\" \"*:Package:_packages\"' ppm 2>/dev/null" >> "$HOME/.zshrc"
    fi

elif [ "$CURRENT_SHELL" = "fish" ]; then
    echo "🐟 Configuring PPM for Fish..."
    FISH_DIR="$HOME/.config/fish/functions"
    mkdir -p "$FISH_DIR" "$HOME/.config/fish/completions"

    # Функция Fish
    cat << 'EOF' > "$FISH_DIR/ppm.fish"
function ppm --description 'Custom minimal package manager'
    set action $argv
    set -e argv

    switch $action
        case install; sudo pacman -S $argv
        case remove;  sudo pacman -Rns $argv
        case update;  sudo pacman -Syu
        case search;  pacman -Ss $argv
        case clean;   sudo pacman -Sc
        case build;   paru -S $argv
        case '*'
            echo "Использование: ppm [install|remove|update|search|clean|build] пакет"
    end
end
EOF

    # Автодополнение Fish
    cat << 'EOF' > "$HOME/.config/fish/completions/ppm.fish"
complete -c ppm -f
complete -c ppm -n "__fish_use_subcommand" -a "install remove update search clean build" -d 'Действие'
complete -c ppm -n "__fish_seen_subcommand_from install remove search build" -a "(__fish_print_packages)" -d 'Пакет'
EOF

else
    echo "⚠️ Could not safely determine your shell. Installation aborted for security reasons."
    exit 1
fi

echo "✅ PPM installation completed successfully! Please restart your terminal."
