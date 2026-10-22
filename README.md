
PPM (Pacman Package Manager)

PPM is a minimalist shell wrapper for pacman designed for Arch Linux and derivatives (CachyOS, EndeavourOS), simplifying complex system commands into intuitive actions like apt or pamac.

Features

• Automatic Shell Detection: Deploys native configurations for Bash, Zsh, or Fish.
• Native Fish Support: Uses optimized switch/case syntax.
• Tab Auto-Completion: Integrated with Zsh and Fish.
• Strict Security: Operates safely without modifying system sudoers files.

Available Commands

• ppm install [package] — Installs packages (sudo pacman -S).
• ppm remove [package] — Removes package and dependencies (sudo pacman -Rns).
• ppm update — Upgrades the system (sudo pacman -Syu).
• ppm update full — Full upgrade (Pacman, AUR, Flatpak).
• ppm search [query] — Searches remote database (pacman -Ss).
• ppm clean — Cleans package cache (sudo pacman -Sc).
• ppm build [package] — Builds and installs from AUR (yay -S).


Under the Hood: How ppm sdir Works

Executes sudo find / -iname "*<query>*" 2>/dev/null to scan protected directories root-wide, perform case-insensitive partial matching, and suppress permission errors. Example: ppm sdir zapret.

Fast Installation



git clone https://github.com/kglkdfg/pacman-ppm && cd ppm && chmod +x install.sh && ./install.sh
Note: Restart your terminal after installation.

License

Licensed under the GNU General Public License v3.0 (GPLv3), ensuring the software remains free and open-source. See the LICENSE file for details.
