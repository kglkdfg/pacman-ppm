#!/usr/bin/env bash
# PPM installer
# Copyright (C) 2026 kglkdfg
# SPDX-License-Identifier: GPL-3.0-or-later

set -Eeuo pipefail

if [[ "\${EUID}" -eq 0 ]]; then
    echo "Не запускай установщик от root. Запусти его от обычного пользователя." >&2
    exit 1
fi
if ! command -v pacman >/dev/null 2>&1; then
    echo "Ошибка: pacman не найден. Этот установщик предназначен для Arch Linux и производных." >&2
    exit 1
fi
if ! command -v sudo >/dev/null 2>&1; then
    echo "Ошибка: sudo не найден." >&2
    exit 1
fi

CURRENT_SHELL="$(basename -- "\${SHELL:-}")"
echo "🚀 Установка PPM для оболочки: \${CURRENT_SHELL:-неизвестна}"
echo "📦 Проверка зависимостей..."
sudo pacman -S --needed git base-devel

SH_CODE=$(cat <<'PPM_EOF'
# >>> PPM CONFIG >>>
_ppm_usage() {
    echo "Использование: ppm [install|remove|update|search|clean|build] [пакет...]"
    echo "Полное обновление: ppm update full"
}
ppm() {
    if (( $# == 0 )); then _ppm_usage; return 2; fi
    local action="$1"
    shift
    case "$action" in
        install)
            if (( $# == 0 )); then _ppm_usage; return 2; fi
            sudo pacman -S -- "$@"
            ;;
        remove)
            if (( $# == 0 )); then _ppm_usage; return 2; fi
            sudo pacman -Rns -- "$@"
            ;;
        update)
            if [[ "\${1-}" == "full" ]]; then
                if command -v yay >/dev/null 2>&1; then
                    yay -Syu
                else
                    echo "⚠️ yay не найден: обновляю официальные пакеты через pacman."
                    sudo pacman -Syu
                    echo "Для обновления AUR-пакетов отдельно установи yay."
                fi
                if command -v flatpak >/dev/null 2>&1; then flatpak update -y; fi
            else
                sudo pacman -Syu
            fi
            ;;
        search)
            if (( $# == 0 )); then _ppm_usage; return 2; fi
            pacman -Ss "$@"
            ;;
        clean) sudo pacman -Sc ;;
        build)
            if (( $# == 0 )); then _ppm_usage; return 2; fi
            if ! command -v yay >/dev/null 2>&1; then
                echo "Ошибка: yay не установлен. Установи yay отдельно для работы с AUR." >&2
                return 1
            fi
            yay -S -- "$@"
            ;;
        *) _ppm_usage; return 2 ;;
    esac
}
# <<< PPM CONFIG <<<
PPM_EOF
)

case "$CURRENT_SHELL" in
    bash|zsh)
        if [[ "$CURRENT_SHELL" == "bash" ]]; then CONFIG_FILE="$HOME/.bashrc"; else CONFIG_FILE="$HOME/.zshrc"; fi
        touch "$CONFIG_FILE"
        if ! grep -Fq '# >>> PPM CONFIG >>>' "$CONFIG_FILE"; then
            printf '\n%s\n' "$SH_CODE" >> "$CONFIG_FILE"
        fi
        ;;
    fish)
        mkdir -p "$HOME/.config/fish/functions" "$HOME/.config/fish/completions"
        cat > "$HOME/.config/fish/functions/ppm.fish" <<'FISH_EOF'
function ppm --description 'PPM package manager wrapper'
    if test (count $argv) -lt 1
        echo "Использование: ppm [install|remove|update|search|clean|build] [пакет...]"
        return 2
    end
    set -l action $argv[1]
    set -l args $argv[2..-1]
    switch $action
        case install
            if test (count $args) -eq 0; echo "Укажи пакет."; return 2; end
            sudo pacman -S -- $args
        case remove
            if test (count $args) -eq 0; echo "Укажи пакет."; return 2; end
            sudo pacman -Rns -- $args
        case update
            if test "$args[1]" = full
                if command -q yay
                    yay -Syu
                else
                    echo "yay не найден: обновляю официальные пакеты через pacman."
                    sudo pacman -Syu
                    echo "Для AUR установи yay отдельно."
                end
                if command -q flatpak; flatpak update -y; end
            else
                sudo pacman -Syu
            end
        case search
            if test (count $args) -eq 0; echo "Укажи поисковый запрос."; return 2; end
            pacman -Ss $args
        case clean
            sudo pacman -Sc
        case build
            if test (count $args) -eq 0; echo "Укажи пакет."; return 2; end
            if not command -q yay
                echo "Ошибка: yay не установлен. Установи yay отдельно для работы с AUR."
                return 1
            end
            yay -S -- $args
        case '*'
            echo "Неизвестная команда: $action"
            echo "Использование: ppm [install|remove|update|search|clean|build] [пакет...]"
            return 2
    end
end
FISH_EOF
        cat > "$HOME/.config/fish/completions/ppm.fish" <<'FISH_COMP_EOF'
complete -c ppm -f
complete -c ppm -n "__fish_use_subcommand" -a "install remove update search clean build"
FISH_COMP_EOF
        ;;
    *)
        echo "Не удалось определить оболочку: \${CURRENT_SHELL:-пусто}. Поддерживаются Bash, Zsh и Fish." >&2
        exit 1
        ;;
esac

echo "✅ PPM установлен. Перезапусти терминал."
