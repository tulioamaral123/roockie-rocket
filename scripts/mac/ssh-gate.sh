#!/usr/bin/env bash
# Porteiro SSH do MacBook: a chave do Linux só pode rodar os comandos abaixo.
# Instalação: ver docs/colaboracao.md, passo "Mac 3". Fica fora do repositório em ~/bin/roockie-ssh-gate.sh.
set -euo pipefail

REPO="${ROOCKIE_REPO:-$HOME/Documents/nasa}"
STUDIO_MCP="/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"
PORT=8765

read -r -a args <<< "${SSH_ORIGINAL_COMMAND:-}"
cmd="${args[0]:-}"

case "$cmd" in
	studio-mcp)
		# MCP embutido do Studio (stdio). O Studio precisa estar aberto com o MCP ligado.
		exec "$STUDIO_MCP"
		;;
	status)
		git -C "$REPO" status --short --branch
		;;
	sync)
		# sync <branch>: troca para a branch e puxa do GitHub, só se não houver mudança local.
		branch="${args[1]:-main}"
		[[ "$branch" =~ ^[A-Za-z0-9._/-]+$ ]] || { echo "branch inválida" >&2; exit 2; }
		if [ -n "$(git -C "$REPO" status --porcelain --untracked-files=no)" ]; then
			echo "Há mudanças não commitadas no Mac. Nada foi feito." >&2
			git -C "$REPO" status --short >&2
			exit 3
		fi
		git -C "$REPO" fetch origin
		git -C "$REPO" switch "$branch" 2>/dev/null || git -C "$REPO" switch -c "$branch" --track "origin/$branch"
		git -C "$REPO" pull --ff-only
		git -C "$REPO" log -1 --oneline
		;;
	serve-start)
		# Servidor local dos geradores (só 127.0.0.1, como no CLAUDE.md).
		if lsof -nP -iTCP:$PORT -sTCP:LISTEN >/dev/null 2>&1; then echo "já rodando"; exit 0; fi
		cd "$REPO/build"
		nohup python3 -m http.server $PORT --bind 127.0.0.1 >/tmp/roockie-http.log 2>&1 &
		echo "servindo build/ em http://127.0.0.1:$PORT (pid $!)"
		;;
	serve-stop)
		pids=$(lsof -nP -t -iTCP:$PORT -sTCP:LISTEN || true)
		[ -n "$pids" ] && kill $pids && echo "parado" || echo "não estava rodando"
		;;
	*)
		echo "comando não permitido: '$cmd'. Use: studio-mcp | status | sync <branch> | serve-start | serve-stop" >&2
		exit 1
		;;
esac
