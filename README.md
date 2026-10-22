# PPM (Pacman Package Manager)

[![License: GPL v3](https://shields.io)](https://gnu.org)

**PPM** (known as Pacman Package Manager) is a convenient and minimalist shell wrapper for `pacman`. This tool is specifically made for **Arch Linux and its derivatives** (such as CachyOS, EndeavourOS, and others). 

It simplifies long and complex system commands into short, intuitive actions reminiscent of `apt` or `pamac`, making command-line package management much more comfortable.

---

## ✨ Features

* 🔀 **Automatic Shell Detection:** The installer automatically detects your active shell (**Bash, Zsh, or Fish**) and deploys the appropriate native configuration.
* 🐟 **Native Fish Support:** Generates clean, performance-optimized `.fish` functions utilizing native `switch/case` syntax.
* ⌨️ **Tab Auto-Completion:** Seamless integration with Zsh and Fish auto-completion mechanisms. Simply type `ppm install ` and press **Tab** to view or complete available packages.
* 🛡️ **Strict Security:** **Does not alter system `sudoers` files.** The script operates entirely within standard, safe `sudo` environment variables to protect your system from vulnerabilities.

---

## 🛠️ Available Commands

The list of available commands in **PPM** includes:

| Command | Native Equivalent | Description |
| :--- | :--- | :--- |
| `ppm install [package]` | `sudo pacman -S` | Installs packages from the official repositories. |
| `ppm remove [package]` | `sudo pacman -Rns` | Safely removes a package along with its unneeded dependencies. |
| `ppm update` | `sudo pacman -Syu` | Synchronizes repositories and upgrades the entire system. |
| `ppm search [query]` | `pacman -Ss` | Searches for packages in the remote database. |
| `ppm clean` | `sudo pacman -Sc` | Cleans up the local package cache to free up disk space. |
| `ppm build [package]` | `paru -S` | Safely downloads, builds, and installs a package from the **AUR**. |

---

## 📦 Fast Installation

To deploy **PPM** on your system, open your terminal and run the following command:

```bash
git clone https://github.com/kglkdfg/pacman-ppm && cd ppm && chmod +x install.sh && ./install.sh
```

> 💡 **Note:** After the installation completes, please **restart your terminal** or open a new tab to apply the changes.

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. 

GPLv3 is a strong copyleft license which guarantees that this tool will always remain free and open-source. Anyone is free to copy, modify, and distribute this software, provided that all derivative works remain open-source under the exact same GPLv3 terms.

For more details, see the full text in the [LICENSE](./LICENSE) file.
