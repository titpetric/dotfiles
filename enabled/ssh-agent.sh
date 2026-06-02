# start ssh-agent for local users only
if [ "$USER" == "root" ]; then
	return
fi

SOCKETFILE="/tmp/ssh_auth_sock_$USER"

# start ssh-agent if not already started
if [ ! -f "$SOCKETFILE" ]; then
	eval `ssh-agent`
	ln -sf "$SSH_AUTH_SOCK" $SOCKETFILE
	# add the local users identity
	ssh-add
fi
export SSH_AUTH_SOCK=$SOCKETFILE
# print added identity
ssh-add -l
