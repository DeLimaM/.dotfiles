#!/bin/bash
# ============================================================================
# ONE-TIME MACHINE SETUP — Sway / Wayland
# Run with: bash ~/setup-machine.sh
# ============================================================================
set -euo pipefail

# ---- Required packages (apt) ----
REQUIRED_PACKAGES=(
    # Core
    sudo curl wget git zsh rsync

    # Sway / Wayland
    sway swaybg swayidle swaylock waybar wofi kanshi wdisplays
    xdg-desktop-portal-wlr wl-clipboard grim slurp grimshot

    # Notifications
    dunst

    # Terminal & tools
    kitty btop firefox-esr

    # Audio
    pipewire pipewire-pulse pavucontrol

    # Network / Bluetooth (GUI management)
    network-manager network-manager-gnome bluez blueman

    # Power management
    power-profiles-daemon brightnessctl

    # Fonts
    fonts-font-awesome
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

# ---- Disable TLP if present (conflicts with power-profiles-daemon) ----
if systemctl is-enabled tlp &>/dev/null; then
    echo "Disabling TLP (conflicts with power-profiles-daemon)..."
    sudo systemctl disable tlp
    sudo systemctl mask tlp
fi

# ---- Enable services ----
sudo systemctl enable --now power-profiles-daemon
sudo systemctl enable --now bluetooth
sudo systemctl enable --now NetworkManager

# ---- Dotfiles ----
if [ ! -d "$HOME/.dotfiles" ]; then
    echo "Cloning .dotfiles..."
    git clone --depth=1 https://github.com/DeLimaM/.dotfiles "$HOME/.dotfiles"
fi
git --git-dir="$HOME/.dotfiles/.git" --work-tree=/ config --local status.showUntrackedFiles no
echo "Copying dotfiles to / (overwriting existing files)..."
sudo rsync -a --exclude='.git' "$HOME/.dotfiles"/ /

# ---- Make waybar scripts executable ----
chmod +x "$HOME/.config/waybar/scripts/"*.sh

# ---- Screenshots directory ----
mkdir -p "$HOME/Pictures/screenshots"

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
echo "Setup complete. Log out and select Sway from your display manager."
