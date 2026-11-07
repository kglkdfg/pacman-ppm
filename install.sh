#!/usr/bin/env bash

set -euo pipefail

USER_NAME=$(whoami)
PARENT_PROC=$(ps -p "$PPID" -o comm=)

case "$PARENT_PROC" in
    *zsh*)  CURRENT_SHELL="zsh" ;;
    *fish*) CURRENT_SHELL="fish" ;;
    *bash*) CURRENT_SHELL="bash" ;;
    *)      echo "Error: Could not detect shell (parent: $PARENT_PROC). Aborting."; exit 1 ;;
esac

echo "Starting PPM installation for shell: $CURRENT_SHELL"
echo "Target user: $USER_NAME"

echo "Checking base dependencies..."
sudo pacman -S --needed --noconfirm coreutils git base-devel

PPM_SH_CODE='
_ppm_ensure_yay() {
    if ! command -v yay &> /dev/null; then
        echo "yay not found. Building from AUR..."
        sudo pacman -S --needed --noconfirm base-devel git
        local tmpdir
        tmpdir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
        (cd "$tmpdir/yay" && makepkg -si --noconfirm)
        rm -rf "$tmpdir"
        echo "yay installed successfully."
    fi
}

ppm() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: ppm [install|remove|update|search|clean|build] package"
        echo "Extra: ppm update full — full system upgrade"
        return 1
    fi

    case "$1" in
        install)
            shift; sudo pacman -S "$@"
            ;;
        remove)
            shift; sudo pacman -Rns "$@"
            ;;
        update)
            if [[ "${2:-}" == "full" ]]; then
                echo "Starting FULL system upgrade (Pacman + AUR + Flatpak)..."
                _ppm_ensure_yay
                yay -Syu --noconfirm

                if ! command -v flatpak &> /dev/null; then
                    read -r -p "Flatpak is not installed. Install? [y/N]: " answer
                    if [[ "$answer" =~ ^[Yy]$ ]]; then
                        echo "Installing Flatpak and adding Flathub..."
                        sudo pacman -S --noconfirm flatpak
                        flatpak remote-add --if-not-exists flathub https://flathub.org
                        echo "Flatpak configured. Reboot recommended."
                    else
                        echo "Skipping Flatpak installation."
                    fi
                else
                    echo "Updating Flatpak packages..."
                    flatpak update -y
                fi
            else
                echo "Starting standard system upgrade..."
                sudo pacman -Syu
            fi
            ;;
        search)
            shift; pacman -Ss "$@"
            ;;
        clean)
            sudo pacman -Sc
            ;;
        build)
            shift
            _ppm_ensure_yay
            yay -S "$@"
            ;;
        *)
            echo "Unknown command: $1"
            echo "Usage: ppm [install|remove|update|search|clean|build] package"
            return 1
            ;;
    esac
}'

if [ "$CURRENT_SHELL" = "bash" ]; then
    echo "Configuring PPM for Bash..."
    if ! grep -q "ppm()" "$HOME/.bashrc"; then
        echo "$PPM_SH_CODE" >> "$HOME/.bashrc"
    fi
    RC_FILE="$HOME/.bashrc"
elif [ "$CURRENT_SHELL" = "zsh" ]; then
    echo "Configuring PPM for Zsh..."
    if ! grep -q "ppm()" "$HOME/.zshrc"; then
        echo "$PPM_SH_CODE" >> "$HOME/.zshrc"
        echo "compdef '_arguments \"1:Action:(install remove update search clean build)\" \"*:Package:_packages\"' ppm 2>/dev/null" >> "$HOME/.zshrc"
    fi
    RC_FILE="$HOME/.zshrc"
elif [ "$CURRENT_SHELL" = "fish" ]; then
    echo "Configuring PPM for Fish..."
    FISH_DIR="$HOME/.config/fish/functions"
    mkdir -p "$FISH_DIR" "$HOME/.config/fish/completions"

    cat << 'EOF' > "$FISH_DIR/ppm.fish"
function _ppm_ensure_yay
    if not command -v yay > /dev/null
        echo "yay not found. Building from AUR..."
        sudo pacman -S --needed --noconfirm base-devel git
        set -l tmpdir (mktemp -d)
        git clone https://aur.archlinux.org/yay.git $tmpdir/yay
        pushd $tmpdir/yay
        makepkg -si --noconfirm
        popd
        rm -rf $tmpdir
        echo "yay installed successfully."
    end
end

function ppm --description 'Pacman Package Manager Wrapper'
    if test (count $argv) -lt 1
        echo "Usage: ppm [install|remove|update|search|clean|build] package"
        return 1
    end

    switch $argv[1]
        case install
            sudo pacman -S $argv[2..-1]
        case remove
            sudo pacman -Rns $argv[2..-1]
        case update
            if test "$argv[2]" = "full"
                echo "Starting FULL system upgrade (Pacman + AUR + Flatpak)..."
                _ppm_ensure_yay
                yay -Syu --noconfirm

                if not command -v flatpak > /dev/null
                    read -l -P "Flatpak is not installed. Install? [y/N]: " answer
                    if string match -ri '^[y]$' $answer
                        echo "Installing Flatpak and adding Flathub..."
                        sudo pacman -S --noconfirm flatpak
                        flatpak remote-add --if-not-exists flathub https://flathub.org
                        echo "Flatpak configured. Reboot recommended."
                    else
                        echo "Skipping Flatpak installation."
                    end
                else
                    echo "Updating Flatpak packages..."
                    flatpak update -y
                end
            else
                echo "Starting standard system upgrade..."
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
            echo "Unknown command: $argv[1]"
            return 1
    end
end
EOF

    cat << 'EOF' > "$HOME/.config/fish/completions/ppm.fish"
complete -c ppm -f
complete -c ppm -n "__fish_use_subcommand" -a "install remove update search clean build" -d 'Action'
complete -c ppm -n "__fish_seen_subcommand_from install remove search build" -a "(__fish_print_packages)" -d 'Package'
EOF
    RC_FILE=""
fi

echo "PPM installation completed."

if [ -n "$RC_FILE" ] && [ -t 1 ]; then
    echo ""
    read -r -p "Apply changes now (source $RC_FILE)? [Y/n]: " apply_now
    if [[ "$apply_now" =~ ^[Nn]$ ]]; then
        echo "Remember to run: source $RC_FILE or restart your terminal."
    else
        echo "Run this command to apply: source $RC_FILE"
        echo "Or simply restart your terminal."
    fi
else
    echo "Restart your terminal or run: source $RC_FILE"
fi
