# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================================
# ZSH CONFIGURATION
# ============================================================================

# ============================================================================
# ONE-TIME MACHINE SETUP (run manually with `setup-machine`)
# ============================================================================
setup-machine() {
    # ---- Required packages (apt) ----
    local -a REQUIRED_PACKAGES=(
        sudo curl wget i3 kitty git zsh btop polybar firefox-esr
        rofi feh pulseaudio rocm-smi picom xclip maim lightdm
    )

    local -a packages_to_install=()
    local installed
    installed=$(dpkg-query -W -f='${Package} ${Status}\n' 2>/dev/null)

    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! echo "$installed" | grep -q "^$pkg install ok installed$"; then
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
        local -a build_deps=(
            build-essential automake pkg-config fakeroot debhelper
            liblightdm-gobject-dev libgtk-3-dev
        )
        echo "Installing lightdm-mini-greeter build dependencies..."
        sudo apt install -y "${build_deps[@]}"

        local build_dir
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
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        echo "Installing Oh My Zsh..."
        KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
    fi

    # ---- Theme & plugins ----
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [[ ! -d "$zsh_custom/themes/powerlevel10k" ]]; then
        echo "Cloning Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$zsh_custom/themes/powerlevel10k"
    fi

    local -A plugins_map=(
        [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
        [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions.git"
    )
    for name url in "${(@kv)plugins_map}"; do
        if [[ ! -d "$zsh_custom/plugins/$name" ]]; then
            echo "Cloning $name..."
            git clone --depth=1 "$url" "$zsh_custom/plugins/$name"
        fi
    done

    # ---- Dotfiles ----
    if [[ ! -d "$HOME/.dotfiles" ]]; then
        echo "Cloning .dotfiles..."
        git clone --depth=1 https://github.com/DeLimaM/.dotfiles "$HOME/.dotfiles"
    fi
    git --git-dir="$HOME/.dotfiles/.git" --work-tree=/ config --local status.showUntrackedFiles no

    echo "\nSetup complete. Restart your shell to apply changes."
}

# ============================================================================
# RUNTIME CONFIGURATION (sourced on every shell)
# ============================================================================

# ----------------------------------------------------------------------------
# Oh My Zsh
# ----------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM=${ZSH_CUSTOM:-$ZSH/custom}
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    zsh-syntax-highlighting
    zsh-autosuggestions
    kitty
)

[[ -f $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

# ----------------------------------------------------------------------------
# Powerlevel10k
# ----------------------------------------------------------------------------
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ----------------------------------------------------------------------------
# Dotfiles management
# ----------------------------------------------------------------------------
if [[ -d "$HOME/.dotfiles" ]]; then
    function dotfiles() {
        git --git-dir="$HOME/.dotfiles/.git" --work-tree=/ "$@"
    }

    function dotfiles-sync-all() {
        dotfiles add -u
        dotfiles commit -m "${1:-Auto-sync all tracked files}"
    }
fi

# ----------------------------------------------------------------------------
# Aliases & functions
# ----------------------------------------------------------------------------
alias ll="ls -al"

function cl() {
    builtin cd "$@" && ll
}
alias cd="cl"

# ----------------------------------------------------------------------------
# Local overrides
# ----------------------------------------------------------------------------
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
