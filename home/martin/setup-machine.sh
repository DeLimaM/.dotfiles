#!/bin/bash
# ============================================================================
# ONE-TIME MACHINE SETUP — Raspberry Pi 4 (headless)
# Run with: bash ~/setup-machine.sh
# ============================================================================
set -euo pipefail

echo "===== Raspberry Pi 4 — headless setup ====="

# ---- Required packages (apt) ----
REQUIRED_PACKAGES=(
    # core
    sudo curl wget git zsh rsync
    # system monitoring
    btop htop iotop
    # network
    net-tools dnsutils nmap ssh openssh-server
    # utilities
    tmux tree jq unzip zip vim nano
    # filesystem
    ncdu duf
)

installed=$(dpkg-query -W -f='${Package} ${Status}\n' 2>/dev/null || true)
packages_to_install=()

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! echo "$installed" | grep -q "^${pkg} install ok installed$"; then
        packages_to_install+=("$pkg")
    fi
done

if (( ${#packages_to_install[@]} )); then
    echo "Installing missing packages: ${packages_to_install[*]}"
    sudo apt update && sudo apt install -y "${packages_to_install[@]}"
else
    echo "All required packages are already installed."
fi

# ---- Dotfiles ----
if [ ! -d "$HOME/.dotfiles" ]; then
    echo "Cloning .dotfiles..."
    git clone --depth=1 -b pi4 https://github.com/DeLimaM/.dotfiles "$HOME/.dotfiles"
fi
git --git-dir="$HOME/.dotfiles/.git" --work-tree=/ config --local status.showUntrackedFiles no
echo "Copying dotfiles to / (overwriting existing files)..."
sudo rsync -a --exclude='.git' "$HOME/.dotfiles"/ /

# ---- System configuration ----
# Apply sysctl rules
if [ -f /etc/sysctl.d/99-pi4.conf ]; then
    echo "Applying sysctl settings..."
    sudo sysctl --system > /dev/null 2>&1
fi

# ---- SSH ----
echo "Enabling SSH..."
sudo systemctl enable --now ssh

# ---- Disable unnecessary services ----
for svc in bluetooth avahi-daemon triggerhappy; do
    if systemctl is-enabled "$svc" &>/dev/null; then
        echo "Disabling $svc..."
        sudo systemctl disable --now "$svc"
    fi
done

# ---- Oh My Zsh ----
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# ---- Theme & plugins ----
zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$zsh_custom/themes/powerlevel10k" ]; then
    echo "Cloning Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$zsh_custom/themes/powerlevel10k"
fi

declare -A plugins_map=(
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions.git"
)
for name in "${!plugins_map[@]}"; do
    url="${plugins_map[$name]}"
    if [ ! -d "$zsh_custom/plugins/$name" ]; then
        echo "Cloning $name..."
        git clone --depth=1 "$url" "$zsh_custom/plugins/$name"
    fi
done

# ---- Set zsh as default shell ----
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
fi

echo ""
echo "===== Setup complete. Reboot to apply all changes. ====="
