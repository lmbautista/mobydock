# mobydock-prompt.sh
#
# Shows the active mobydock environment in your shell prompt, the same way the
# git branch is shown. The environment is set by `eval $(mobydock <env> login)`,
# which exports MOBYDOCK_ENV into your shell.
#
# Installation
# ------------
# 1. Source this file from your shell rc (~/.zshrc or ~/.bashrc):
#
#       source /path/to/mobydock/shell/mobydock-prompt.sh
#
# 2. Add the segment to your prompt:
#
#    zsh (~/.zshrc):
#       setopt PROMPT_SUBST
#       PROMPT='$(mobydock_prompt)'$PROMPT
#
#    bash (~/.bashrc):
#       PROMPT_COMMAND='__mobydock_ps1=$(mobydock_prompt)'"${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
#       PS1='${__mobydock_ps1}'$PS1
#
# To clear the segment, run `unset MOBYDOCK_ENV` (or log into another env).

mobydock_prompt() {
  [ -n "$MOBYDOCK_ENV" ] && printf '(mobydock:%s) ' "$MOBYDOCK_ENV"
}
