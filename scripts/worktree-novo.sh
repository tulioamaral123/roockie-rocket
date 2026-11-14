#!/usr/bin/env bash
# Cria um worktree isolado para um agente: scripts/worktree-novo.sh <claude|codex|nome> <tarefa-curta>
# Resultado: ../roockie-rocket-wt/<agente>-<tarefa> na branch <agente>/<tarefa>, criada a partir de origin/main.
set -euo pipefail

if [ $# -ne 2 ]; then
	echo "uso: $0 <agente> <tarefa-curta>   (ex.: $0 codex placas-museu)" >&2
	exit 1
fi

agente=$1
tarefa=$2
repo=$(git rev-parse --path-format=absolute --git-common-dir | sed 's#/\.git$##')
destino="$(dirname "$repo")/roockie-rocket-wt/$agente-$tarefa"
branch="$agente/$tarefa"

git -C "$repo" fetch origin main
git -C "$repo" worktree add -b "$branch" "$destino" origin/main
echo
echo "Pronto. Abra o agente nesta pasta:"
echo "  cd $destino"
