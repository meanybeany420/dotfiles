typeset -U path PATH
path=("$HOME/.local/bin" $path)

#Powerlevel10k
[[ ! -r "$HOME/.powerlevel10k/powerlevel10k.zsh-theme" ]] || source "$HOME/.powerlevel10k/powerlevel10k.zsh-theme"
if [[ -r "$HOME/.ls_colors" ]]; then
  export LS_COLORS="$(<"$HOME/.ls_colors")"
fi
# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory sharehistory hist_ignore_dups

# Completion
autoload -Uz compinit
compinit

# Aliases
if (( $+commands[bat] )); then alias cat='bat'; fi
if (( $+commands[eza] )); then alias ls='eza --icons --group-directories-first'; fi
# Navigation
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
  alias cd='z'
fi

# FZF
[[ ! -r /usr/share/fzf/key-bindings.zsh ]] || source /usr/share/fzf/key-bindings.zsh
[[ ! -r /usr/share/fzf/completion.zsh ]] || source /usr/share/fzf/completion.zsh

export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
  --color=fg:#afa9a9,fg+:#000000,bg:#2d1e1e,bg+:#723a3a \
  --color=hl:#ed8585,hl+:#000000,info:#000000,marker:#fc2323 \
  --color=prompt:#ff0000,spinner:#ffffff,pointer:#000000,header:#87afaf \
  --color=gutter:#2d1e1e,border:#000000,separator:#000000,label:#aeaeae \
  --color=query:#d9d9d9 \
  --preview-window=border-rounded \
  --margin=2 \
  --prompt='> ' \
  --marker='>' \
  --pointer='◆' \
  --separator='-' \
  --scrollbar='│' \
  --layout=reverse \
  --info=right"

fzf-cd-widget() {
  local dir
  dir=$(fd --type d --hidden --exclude .git . | fzf --height 40%) || return
  BUFFER="cd ${(q)dir}"
  zle accept-line
}

function lock {
  hyprlock >/dev/null 2>&1 &|
}

zle -N fzf-cd-widget
bindkey '^f' fzf-cd-widget

typeset -A ZSH_HIGHLIGHT_STYLES

ZSH_HIGHLIGHT_STYLES+=(precommand 'fg=#604369,bold')
ZSH_HIGHLIGHT_STYLES+=(command 'fg=#915651')
ZSH_HIGHLIGHT_STYLES+=(builtin 'fg=#915651')
ZSH_HIGHLIGHT_STYLES+=(alias 'fg=#915651')
ZSH_HIGHLIGHT_STYLES+=(path 'fg=#999050')
ZSH_HIGHLIGHT_STYLES+=(unknown-token 'fg=#b50f04')

[[ ! -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] || source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Start a chat with a Hermes profile.
alias cyberbill='hermes -p cyberbill chat'
alias writerbob='hermes -p writerbob chat'
