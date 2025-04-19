# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Install curl
if ! command -v curl &>/dev/null; then
    echo "Installing curl..."
    sudo apt update && sudo apt install -y curl
fi

# Install oh my zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing Oh My Zsh..."
    KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
fi

export ZSH="$HOME/.oh-my-zsh"

# Ensure custom theme directory exists
ZSH_CUSTOM=${ZSH_CUSTOM:-$ZSH/custom}
THEMES_DIR="$ZSH_CUSTOM/themes"
SPACESHIP_THEME="$THEMES_DIR/spaceship-prompt"

# Clone Spaceship theme
if [[ ! -d "$SPACESHIP_THEME" ]]; then
    echo "Cloning Spaceship theme..."
    git clone --depth=1 https://github.com/spaceship-prompt/spaceship-prompt.git "$SPACESHIP_THEME"
    ln -sf "$SPACESHIP_THEME/spaceship.zsh-theme" "$THEMES_DIR/spaceship.zsh-theme"
fi

# Set name of the theme to load
ZSH_THEME="spaceship"

# Custom plugins directory
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

# Install required plugins if not present
clone_plugin_if_missing "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
clone_plugin_if_missing "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"

plugins=(
    git
    zsh-syntax-highlighting
    zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=60"

# .dotfiles repo
DOTFILES="$HOME/.dotfiles"
if [[ ! -d "$DOTFILES" ]]; then
    echo "Cloning .dotfiles..."
    git clone --depth=1 https://github.com/DeLimaM/.dotfiles
fi
alias dotfiles="git --git-dir=$HOME/.dotfiles/.git --work-tree=/"
dotfiles config --local status.showUntrackedFiles no

# ll & cd
alias ll="ls -alF"
function cl() {
    builtin cd "$@" && ll
}
alias cd="cl"

# Sync Alias
alias sync-all="dotfiles add -u && dotfiles commit -m 'Auto-sync all tracked files'"
