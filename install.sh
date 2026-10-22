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
sudo pacman -S --needed --noconfirm coreutils git base-devel

# --- 3. ТОЧЕЧНАЯ НАСТРОЙКА ПОД ТЕКУЩУЮ ОБОЛОЧКУ ---
PPM_SH_CODE="
# Вспомогательная функция для автоматической установки yay в CachyOS
_ppm_ensure_yay() {
    if ! command -v yay &> /dev/null; then
        echo \"📦 yay не найден. Начинаем автоматическую установку...\"
        sudo pacman -S --needed --noconfirm base-devel git yay
    fi
}

# Custom minimal package manager (ppm)
ppm() {
    if [[ \"\$1\" == \"install\" ]]; then
        shift; sudo pacman -S \"\$@\"
    elif [[ \"\$1\" == \"remove\" ]]; then
        shift; sudo pacman -Rns \"\$@\"
    elif [[ \"\$1\" == \"update\" ]]; then
        if [[ \"\$2\" == \"full\" ]]; then
            echo \"🚀 Запуск ПОЛНОГО обновления системы (Pacman + AUR + Flatpak)...\"
            _ppm_ensure_yay
            yay -Syu --noconfirm

            if ! command -v flatpak &> /dev/null; then
                echo -n \"⚠️ Flatpak не установлен. Хотите скачать его? [y/N]: \"
                read -r answer
                if [[ \"\$answer\" =~ ^[Yy]\$ ]]; then
                    echo \"📦 Установка Flatpak и подключение Flathub...\"
                    sudo pacman -S --noconfirm flatpak
                    flatpak remote-add --if-not-exists flathub https://flathub.org
                    echo \"✅ Flatpak успешно настроен! Настоятельно рекомендуется перезагрузить систему.\"
                else
                    echo \"⏭️ Установка Flatpak пропущена.\"
                fi
            else
                echo \"📦 Обновление пакетов Flatpak...\"
                flatpak update -y
            fi
        else
            echo \"🔄 Запуск стандартного обновления системы...\"
            sudo pacman -Syu
        fi
    elif [[ \"\$1\" == \"search\" ]]; then
        shift; pacman -Ss \"\$@\"
    elif [[ \"\$1\" == \"clean\" ]]; then
        sudo pacman -Sc
    elif [[ \"\$1\" == \"build\" ]]; then
        shift
        _ppm_ensure_yay
        yay -S \"\$@\"
    else
        echo \"Использование: ppm [install|remove|update|search|clean|build] пакет\"
        echo \"Дополнительно: ppm update full — полное обновление всего софта\"
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
function _ppm_ensure_yay
    if not command -v yay > /dev/null
        echo "📦 yay не найден. Начинаем автоматическую установку..."
        sudo pacman -S --needed --noconfirm base-devel git yay
    fi
end

function ppm --description 'Custom minimal package manager'
    if test (count $argv) -lt 1
        echo "Использование: ppm [install|remove|update|search|clean|build] пакет"
        echo "Дополнительно: ppm update full — полное обновление всего софта"
        return 1
    end

    switch $argv[1]
        case install
            sudo pacman -S $argv[2..-1]
        case remove
            sudo pacman -Rns $argv[2..-1]
        case update
            if test "$argv[2]" = "full"
                echo "🚀 Запуск ПОЛНОГО обновления системы (Pacman + AUR + Flatpak)..."
                _ppm_ensure_yay
                yay -Syu --noconfirm

                if not command -v flatpak > /dev/null
                    read -l -P "⚠️ Flatpak не установлен. Хотите скачать его? [y/N]: " answer
                    if string match -ri '^[y]$' $answer
                        echo "📦 Установка Flatpak и подключение Flathub..."
                        sudo pacman -S --noconfirm flatpak
                        flatpak remote-add --if-not-exists flathub https://flathub.org
                        echo "✅ Flatpak успешно настроен! Настоятельно рекомендуется перезагрузить систему."
                    else
                        echo "⏭️ Установка Flatpak пропущена."
                    fi
                else
                    echo "📦 Обновление пакетов Flatpak..."
                    flatpak update -y
                fi
            else
                echo "🔄 Запуск стандартного обновления системы..."
                sudo pacman -Syu
            end
        case search
            pacman -Ss $argv[2..-1]
        case clean
            sudo pacman -Sc
        case build
            _ppm_ensure_yay
            yay -S $argv[2..-1]
        case '*'
            echo "Использование: ppm [install|remove|update|search|clean|build] пакет"
            echo "Дополнительно: ppm update full — полное обновление всего софта"
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
