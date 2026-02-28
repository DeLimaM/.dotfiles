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
# ONE-TIME MACHINE SETUP (run: bash ~/setup-machine.sh)
# ============================================================================

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
