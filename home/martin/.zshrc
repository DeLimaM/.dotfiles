# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================================
# ZSH CONFIGURATION
# ============================================================================

# ----------------------------------------------------------------------------
# PACKAGE AUTO-INSTALLATION
# ----------------------------------------------------------------------------
REQUIRED_PACKAGES=(
    i3          # Window manager
    kitty       # Terminal emulator
    git         # Version control
    zsh         # Z shell
    curl        # URL transfer tool
    wget        # File downloader
    vim         # Text editor
    tmux        # Terminal multiplexer
    btop        # System monitor
)


install_missing_packages() {
    local packages_to_install=()
    
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            packages_to_install+=("$pkg")
        fi
    done
    
    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        echo "Missing packages detected: ${packages_to_install[*]}"
        echo "Installing missing packages..."
        sudo apt update && sudo apt install -y "${packages_to_install[@]}"
    fi
}

install_missing_packages

# ----------------------------------------------------------------------------
# OH MY ZSH INSTALLATION & CONFIGURATION
# ----------------------------------------------------------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing Oh My Zsh..."
    KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
fi

export ZSH="$HOME/.oh-my-zsh"

# ----------------------------------------------------------------------------
# THEME CONFIGURATION
# ----------------------------------------------------------------------------
ZSH_CUSTOM=${ZSH_CUSTOM:-$ZSH/custom}
THEMES_DIR="$ZSH_CUSTOM/themes"

if [[ ! -d "${THEMES_DIR}/powerlevel10k" ]]; then
    echo "Cloning Spaceship theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${THEMES_DIR}/powerlevel10k
fi

ZSH_THEME="powerlevel10k/powerlevel10k"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ----------------------------------------------------------------------------
# PLUGINS CONFIGURATION
# ----------------------------------------------------------------------------
PLUGINS_DIR="$ZSH_CUSTOM/plugins"

clone_plugin_if_missing() {
    local plugin_name=$1
    local repo_url=$2
    local plugin_path="$PLUGINS_DIR/$plugin_name"

    if [[ ! -d "$plugin_path" ]]; then
        echo "Cloning $plugin_name..."
        git clone --depth=1 "$repo_url" "$plugin_path"
    fi
}

clone_plugin_if_missing "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
clone_plugin_if_missing "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"

plugins=(
    git                 
    zsh-syntax-highlighting
    zsh-autosuggestions
    kitty
)

source $ZSH/oh-my-zsh.sh

# ----------------------------------------------------------------------------
# DOTFILES REPOSITORY MANAGEMENT
# ----------------------------------------------------------------------------
DOTFILES="$HOME/.dotfiles"
if [[ ! -d "$DOTFILES" ]]; then
    echo "Cloning .dotfiles..."
    git clone --depth=1 https://github.com/DeLimaM/.dotfiles
fi

alias dotfiles="git --git-dir=$HOME/.dotfiles/.git --work-tree=/"
dotfiles config --local status.showUntrackedFiles no

function sync-all() {
    dotfiles add -u
    dotfiles commit -m "${1:-Auto-sync all tracked files}"
}
alias sync-all="sync-all"

# ----------------------------------------------------------------------------
# CUSTOM ALIASES & FUNCTIONS
# ----------------------------------------------------------------------------
alias ll="ls -al"

function cl() {
    builtin cd "$@" && ll
}
alias cd="cl"

# ----------------------------------------------------------------------------
# LOCAL OVERRIDES
# ----------------------------------------------------------------------------
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
