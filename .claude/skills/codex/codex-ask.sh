#!/usr/bin/env bash
# Conversa com o Codex sem interface (codex exec) e imprime a resposta.
#   Nova conversa:  codex-ask.sh new <pasta> <sandbox> "mensagem"
#   Continuar:      codex-ask.sh resume <thread_id> "mensagem"
# sandbox: read-only (perguntas, revisão) ou workspace-write (pode editar a pasta).
# Saída: "THREAD_ID=<id>" na primeira linha, depois a resposta final do Codex.
set -euo pipefail

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

case "${1:-}" in
	new)
		[ $# -eq 4 ] || { echo "uso: $0 new <pasta> <read-only|workspace-write> \"mensagem\"" >&2; exit 1; }
		codex exec --json -C "$2" -s "$3" -o "$tmp/resp.md" "$4" </dev/null >"$tmp/events.jsonl" 2>"$tmp/err.log" || true
		;;
	resume)
		[ $# -eq 3 ] || { echo "uso: $0 resume <thread_id> \"mensagem\"" >&2; exit 1; }
		codex exec resume --json -o "$tmp/resp.md" "$2" "$3" </dev/null >"$tmp/events.jsonl" 2>"$tmp/err.log" || true
		;;
	*)
		echo "uso: $0 new|resume ..." >&2
		exit 1
		;;
esac

id=$(grep -m1 -o '"thread_id":"[^"]*"' "$tmp/events.jsonl" | cut -d'"' -f4 || true)
if [ -z "$id" ] || [ ! -s "$tmp/resp.md" ]; then
	echo "Codex não respondeu. Log:" >&2
	tail -20 "$tmp/err.log" >&2
	exit 2
fi
echo "THREAD_ID=$id"
cat "$tmp/resp.md"
echo
