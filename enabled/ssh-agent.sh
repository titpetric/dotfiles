#!/bin/bash
# start ssh-agent for local users only
if [ "$USER" == "root" ]; then
	return
fi

# local user agent.sock symlink
agent_link="$HOME/.ssh/agent.sock"

if ! SSH_AUTH_SOCK="$agent_link" ssh-add -l >/dev/null 2>&1; then
	eval "$(ssh-agent -s)" >/dev/null
	ln -sf "$SSH_AUTH_SOCK" "$agent_link"

	ssh-add || echo "No identities added."
fi

export SSH_AUTH_SOCK="$agent_link"

# print added identity
ssh-add -l
