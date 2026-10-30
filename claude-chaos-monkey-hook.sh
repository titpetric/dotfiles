#!/usr/bin/env bash
#
# Stop hook: kill the session when the reply opens with a banned word.
#
# One word, "Fair", used as the first word of a reply. It is a verbal tic
# that says nothing, and a hook is the only thing that can enforce its
# absence: the model cannot be trusted to police its own openers, and a
# rule in a prompt is a suggestion. The CLI dies instead.
#
# The hook reads the transcript the Stop event names, takes the last
# assistant text block, and compares its first word against the list.
# On a match it SIGKILLs the claude process that spawned this hook, found
# by walking up the parent chain, so a second session on the same machine
# is untouched.
#
# Every failure path exits 0 and kills nothing. A hook that cannot read
# its input, or cannot find its parent, must not take the session with
# it: a false kill costs the user their context, and the word costs them
# four characters.
#
# CHAOS_DRY_RUN=1 reports the verdict and the pid it would signal,
# without signalling. That is how this is tested, since the honest test
# ends the session running it.
set -u -o pipefail

BANNED_FIRST_WORDS=(fair)

verdict() { [ -n "${CHAOS_DRY_RUN:-}" ] && printf '%s\n' "$1" >&2; }

command -v jq >/dev/null 2>&1 || { verdict "no jq"; exit 0; }

payload=$(cat 2>/dev/null) || exit 0
transcript=$(printf '%s' "$payload" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$transcript" ] && [ -r "$transcript" ] || { verdict "no transcript"; exit 0; }

# The transcript is JSONL and a partial write leaves a line that does not
# parse, so each line is tried on its own and a bad one is skipped.
text=$(
	jq -R 'fromjson? // empty' < "$transcript" 2>/dev/null |
		jq -rs '[.[]
			| select(.type == "assistant")
			| .message.content[]?
			| select(.type == "text")
			| .text]
			| last // ""' 2>/dev/null
) || exit 0
[ -n "$text" ] || { verdict "no assistant text"; exit 0; }

# The first word, with whatever a reply opens with stripped off it:
# markdown emphasis, a quote, a list marker, a backtick.
first=$(
	printf '%s' "$text" |
		sed -e 's/^[[:space:]]*//' -e 's/^[][*_`#>"(-]*//' -e 's/^[[:space:]]*//' |
		awk 'NR == 1 { print tolower($1) }' |
		tr -cd 'a-z'
)
[ -n "$first" ] || { verdict "no first word"; exit 0; }

hit=""
for word in "${BANNED_FIRST_WORDS[@]}"; do
	[ "$first" = "$word" ] && hit="$word" && break
done
[ -n "$hit" ] || { verdict "first word '$first' is fine"; exit 0; }

# The claude that spawned this hook, and nothing else wearing the name.
# Walking up from here keeps the signal inside this process tree, so a
# second session on the same machine goes on running.
#
# The test is the command name, never the arguments. This script's own
# path holds the string "claude", and so does the shell snapshot the tool
# shell sources, so an argument match signals the wrapper shell and
# leaves the session running. A launcher that execs node keeps its
# arguments, so that one case reads them, with this script and the
# snapshot ruled out by name.
target=""
pid=${PPID:-0}
for _ in 1 2 3 4 5 6 7 8; do
	[ "$pid" -gt 1 ] 2>/dev/null || break
	comm=$(ps -o comm= -p "$pid" 2>/dev/null | tr -d '[:space:]')
	if [ "$comm" = "claude" ]; then
		target="$pid"
		break
	fi
	if [ "$comm" = "node" ] || [ "$comm" = "bun" ]; then
		args=$(ps -o args= -p "$pid" 2>/dev/null)
		case "$args" in
			*chaos-monkey* | *shell-snapshots*) ;;
			*claude*) target="$pid"; break ;;
		esac
	fi
	pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d '[:space:]')
	[ -n "$pid" ] || break
done
[ -n "$target" ] || { verdict "matched '$hit', found no claude to signal"; exit 0; }

printf 'chaos monkey: a reply opened with "%s". Killing pid %s.\n' "$hit" "$target" >&2
if [ -n "${CHAOS_DRY_RUN:-}" ]; then
	verdict "would kill $target"
	exit 0
fi

kill -9 "$target" 2>/dev/null
exit 0
