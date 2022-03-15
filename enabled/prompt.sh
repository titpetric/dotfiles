parse_git_branch() {
	git branch 2> /dev/null | awk '{print $2}'
}
parse_git_repo() {
	git remote get-url origin 2> /dev/null | sed -E 's/(^git@|\.git$)//g'
}

color_green="\033[32m"
color_reset="\033[00m"
color_orange="\033[33m"

git_ps1() {
	GBR=$(parse_git_branch)
	GREPO=$(parse_git_repo)
	if [ -z "$GBR" ]; then
		return
	fi
	if [ -z "$GREPO" ]; then
		return
	fi
	echo -e " ${color_orange}${GREPO/:/\/}${color_reset} (${color_green}$GBR${color_reset})"
}

export PS1="\[\033[01;32m\]\u@\h${color_reset}:\[\033[32m\]\w${color_reset}\$(git_ps1) $ "