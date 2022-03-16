# start ssh-agent for local users only
if [ "$USER" == "root" ]; then
	return
fi
# start ssh-agent if not already started
if [ ! -S ~/.ssh/ssh_auth_sock ]; then
	eval `ssh-agent`
	ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
	# add the local users identity
	ssh-add
fi
export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
# print added identity
ssh-add -l
