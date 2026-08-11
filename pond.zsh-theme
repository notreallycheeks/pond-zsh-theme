# pond.zsh-theme — a calm two-line prompt in pastel greens and blues.
#
#   ╭─  ~/dev/project   main ✚1 ●2                             1.4s
#   ╰─≈ ❯
#
# Requires a Nerd Font for the folder and branch glyphs (CaskaydiaCove NF or
# similar). Everything else is plain Unicode and renders in any font.
#
# Tweakables — set any of these in ~/.zshrc *before* oh-my-zsh.sh is sourced:
#   POND_SHOW_TIME=0        disable the elapsed-time right prompt
#   POND_TIME_MIN=3         seconds a command must run before its time shows
#   POND_SHOW_USER=auto     auto | always | never  (user@host segment)
#   POND_PROMPT_CHAR='❯'    the character you actually type at
#   POND_ICON_DIR / POND_ICON_BRANCH / POND_ICON_VENV   override the glyphs

setopt prompt_subst

# ── palette ──────────────────────────────────────────────────────────────────
# Truecolor where available, hand-picked xterm-256 approximations otherwise.
typeset -gA POND
if [[ $COLORTERM == (truecolor|24bit) || -n $WT_SESSION ]]; then
  POND=(
    mist  '#BFE3E0'   # pale aqua — frame and punctuation
    water '#8FC9E8'   # pastel blue — the path
    deep  '#6CA9CC'   # deeper blue — user@host
    lily  '#A5E6B8'   # pastel green — branch name
    reed  '#7FD8B6'   # seafoam — prompt char, clean state
    moss  '#CBE8A6'   # pale yellow-green — staged changes
    silt  '#9BB8C9'   # muted grey-blue — dim text, timings
    dusk  '#C7B8E6'   # pale lavender — stashes
    coral '#F0A6A6'   # soft coral — the only warm colour, errors only
    sun   '#F2E2A8'   # pale yellow — background jobs
  )
else
  POND=( mist 152 water 117 deep 74 lily 157 reed 115
         moss 150 silt 109 dusk 183 coral 210 sun 229 )
fi

# ── glyphs ───────────────────────────────────────────────────────────────────
: ${POND_ICON_DIR=$''}      # nf-fa-folder_open
: ${POND_ICON_BRANCH=$''}   # nf-pl-branch
: ${POND_ICON_VENV=$''}     # nf-dev-python
: ${POND_PROMPT_CHAR='❯'}
: ${POND_SHOW_TIME=1}
: ${POND_TIME_MIN=3}
: ${POND_SHOW_USER=auto}

# ── git ──────────────────────────────────────────────────────────────────────
# git_prompt_info supplies the branch; git_prompt_status supplies the flags.
# DIRTY/CLEAN are blanked so the two don't say the same thing twice.
ZSH_THEME_GIT_PROMPT_PREFIX="%F{${POND[silt]}}on %F{${POND[lily]}}${POND_ICON_BRANCH} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_GIT_PROMPT_ADDED=" %F{${POND[moss]}}✚"
ZSH_THEME_GIT_PROMPT_MODIFIED=" %F{${POND[water]}}●"
ZSH_THEME_GIT_PROMPT_DELETED=" %F{${POND[coral]}}✖"
ZSH_THEME_GIT_PROMPT_RENAMED=" %F{${POND[sun]}}➜"
ZSH_THEME_GIT_PROMPT_UNMERGED=" %F{${POND[coral]}}⚡"
ZSH_THEME_GIT_PROMPT_UNTRACKED=" %F{${POND[silt]}}…"
ZSH_THEME_GIT_PROMPT_STASHED=" %F{${POND[dusk]}}⚑"
ZSH_THEME_GIT_PROMPT_AHEAD=" %F{${POND[lily]}}⇡"
ZSH_THEME_GIT_PROMPT_BEHIND=" %F{${POND[water]}}⇣"
ZSH_THEME_GIT_PROMPT_DIVERGED=" %F{${POND[coral]}}⇕"

# ── command timer ────────────────────────────────────────────────────────────
zmodload zsh/datetime 2>/dev/null
autoload -Uz add-zsh-hook

typeset -g _pond_started= _pond_elapsed=

_pond_human_time() {
  local -F t=$1
  if (( t < 60 )); then
    printf '%.1fs' $t
  elif (( t < 3600 )); then
    printf '%dm %ds' $(( t / 60 )) $(( t % 60 ))
  else
    printf '%dh %dm' $(( t / 3600 )) $(( (t % 3600) / 60 ))
  fi
}

_pond_preexec() { _pond_started=$EPOCHREALTIME }

_pond_precmd() {
  _pond_elapsed=
  if [[ -n $_pond_started ]]; then
    local -F delta=$(( EPOCHREALTIME - _pond_started ))
    (( POND_SHOW_TIME && delta >= POND_TIME_MIN )) &&
      _pond_elapsed=$(_pond_human_time $delta)
    _pond_started=
  fi
}

add-zsh-hook preexec _pond_preexec
add-zsh-hook precmd  _pond_precmd

# ── segments ─────────────────────────────────────────────────────────────────
# Shown only when you're somewhere that isn't your own machine, by default.
_pond_userhost() {
  case $POND_SHOW_USER in
    never)  return ;;
    always) ;;
    *) [[ -n $SSH_CONNECTION || -n $SSH_TTY ]] || return ;;
  esac
  print -n "%F{${POND[deep]}}%n%F{${POND[silt]}}@%F{${POND[deep]}}%m %F{${POND[mist]}}· "
}

VIRTUAL_ENV_DISABLE_PROMPT=1
_pond_venv() {
  [[ -n $VIRTUAL_ENV ]] || return
  print -n " %F{${POND[silt]}}${POND_ICON_VENV} ${VIRTUAL_ENV:t}"
}

# ── prompt ───────────────────────────────────────────────────────────────────
# %(5~|…) keeps deep paths from swallowing the line: first component, an
# ellipsis, then the last three.
PROMPT="%F{${POND[mist]}}╭─ "
PROMPT+="\$(_pond_userhost)"
PROMPT+="%F{${POND[water]}}${POND_ICON_DIR} %B%(5~|%-1~/…/%3~|%~)%b "
PROMPT+="\$(git_prompt_info)\$(git_prompt_status)"
PROMPT+="\$(_pond_venv)"
PROMPT+="%(1j. %F{${POND[sun]}}⚙ %j.)"
PROMPT+="%f"$'\n'
PROMPT+="%F{${POND[mist]}}╰─≈ "
PROMPT+="%(?.%F{${POND[reed]}}.%F{${POND[coral]}})"
PROMPT+="%(!.#.${POND_PROMPT_CHAR})%f "

RPROMPT="%F{${POND[silt]}}\${_pond_elapsed}%f"

# Continuation and selection prompts, kept in palette.
PROMPT2="%F{${POND[mist]}}╰─≈ %F{${POND[silt]}}%_ ❯%f "
PROMPT3="%F{${POND[mist]}}?# %f"
SPROMPT="%F{${POND[silt]}}pond: correct %F{${POND[coral]}}%R%F{${POND[silt]}} to %F{${POND[lily]}}%r%F{${POND[silt]}}? [ynae] %f"
