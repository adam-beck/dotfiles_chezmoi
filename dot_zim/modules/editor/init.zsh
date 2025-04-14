bindkey -e

autoload -Uz edit-command-line
zle -N edit-command-line

dot-expand() {
  if [[ $LBUFFER = *.. ]]; then
    LBUFFER+=/..
  else
    LBUFFER+=.
  fi
}

zle -N dot-expand

bindkey . dot-expand
