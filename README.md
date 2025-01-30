# dotfiles

I have too many linux hosts, might as well set them up consistently.

## Concerns

- set default global git user
- set PATH and GOBIN for Go
- adjust PS1 to show git repo/branch (repo may be redundant, may remove).
- ssh-agent for your `~/.ssh/id_rsa`

## Setup

To set up / update the dotfiles run:

```bash
rm -rf ~/.dotfiles
git clone git@github.com:titpetric/dotfiles.git ~/.dotfiles
cp ~/.dotfiles/.bash_aliases ~/
```

This is meant for local/ssh use for exclusive use machines. The ssh
agent will only start once and will be reused for future sessions.

You should edit the `/etc/sudoers` file to enable carrying the git and
ssh into root. This way you can use `git clone` etc.
