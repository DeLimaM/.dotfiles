#!/bin/bash
# ============================================================================
# ONE-TIME MACHINE SETUP
# Run with: bash ~/setup-machine.sh
# ============================================================================
set -euo pipefail

# ---- Required packages (apt) ----
REQUIRED_PACKAGES=(
    sudo curl wget i3 kitty git zsh btop polybar firefox-esr
    rofi feh pulseaudio rocm-smi picom xclip maim lightdm
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

# ---- lightdm-mini-greeter (build .deb from source) ----
if dpkg-query -W -f='${Status}' lightdm-mini-greeter 2>/dev/null | grep -q "install ok installed"; then
    echo "lightdm-mini-greeter already installed."
else
    build_deps=(
        build-essential automake pkg-config fakeroot debhelper
        liblightdm-gobject-dev libgtk-3-dev
    )
    echo "Installing lightdm-mini-greeter build dependencies..."
    sudo apt install -y "${build_deps[@]}"

    build_dir=$(mktemp -d)
    git clone --depth=1 https://github.com/prikhi/lightdm-mini-greeter.git "$build_dir/lightdm-mini-greeter"

    pushd "$build_dir/lightdm-mini-greeter" > /dev/null
    fakeroot dh binary
    sudo dpkg -i ../lightdm-mini-greeter_*.deb
    popd > /dev/null

    rm -rf "$build_dir"
    echo "lightdm-mini-greeter installed."
fi

# ---- Oh My Zsh ----
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
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

# ---- Dotfiles ----
if [ ! -d "$HOME/.dotfiles" ]; then
    echo "Cloning .dotfiles..."
    git clone --depth=1 https://github.com/DeLimaM/.dotfiles "$HOME/.dotfiles"
fi
git --git-dir="$HOME/.dotfiles/.git" --work-tree=/ config --local status.showUntrackedFiles no
echo "Copying dotfiles to / (overwriting existing files)..."
sudo rsync -a --exclude='.git' "$HOME/.dotfiles"/ /

# ---- Set zsh as default shell ----
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
fi

echo ""
echo "Setup complete. Log out and back in (or run 'zsh') to use your new shell."
