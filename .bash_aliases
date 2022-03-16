for entrypoint in ~/.dotfiles/enabled/*.sh; do
	echo $entrypoint
	. $entrypoint
done
