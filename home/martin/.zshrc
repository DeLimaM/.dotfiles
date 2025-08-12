# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Install curl
if ! command -v curl &>/dev/null; then
    echo "Installing curl..."
    sudo apt update && sudo apt install -y curl
fi

# Install Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing Oh My Zsh..."
    KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_CUSTOM=${ZSH_CUSTOM:-$ZSH/custom}
THEMES_DIR="$ZSH_CUSTOM/themes"
SPACESHIP_THEME="$THEMES_DIR/spaceship-prompt"
PURE_THEME="$THEMES_DIR/pure"

# Clone Spaceship theme
if [[ ! -d "$SPACESHIP_THEME" ]]; then
    echo "Cloning Spaceship theme..."
    git clone --depth=1 https://github.com/spaceship-prompt/spaceship-prompt.git "$SPACESHIP_THEME"
    ln -sf "$SPACESHIP_THEME/spaceship.zsh-theme" "$THEMES_DIR/spaceship.zsh-theme"
fi

# Clone Pure theme
if [[ ! -d "$PURE_THEME" ]]; then
    echo "Cloning Pure theme..."
    git clone --depth=1 https://github.com/sindresorhus/pure.git "$PURE_THEME"
    ln -sf "$PURE_THEME/pure.zsh" "$THEMES_DIR/pure.zsh"
    ln -sf "$PURE_THEME/async.zsh" "$THEMES_DIR/async.zsh"
fi

# --- PURE THEME SETUP ---
fpath+=$PURE_THEME
autoload -Uz promptinit
promptinit
prompt pure
# ------------------------

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

# Install required plugins
clone_plugin_if_missing "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
clone_plugin_if_missing "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"

plugins=(
    git
    zsh-syntax-highlighting
    zsh-autosuggestions
    kitty
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

# Sync function
function sync-all() {
    dotfiles add -u
    dotfiles commit -m "${1:-Auto-sync all tracked files}"
}
alias sync-all="sync-all"

# ll & cd
alias ll="ls -alF"
function cl() {
    builtin cd "$@" && ll
}
alias cd="cl"

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
