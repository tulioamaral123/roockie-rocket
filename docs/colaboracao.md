# Colaboração entre agentes (só no MacBook)

Tudo roda neste Mac: Claude Code, Codex, Roblox Studio, `rojo serve` e o servidor HTTP dos geradores. Não há outro computador nem acesso remoto (a montagem antiga com Linux, SSH e Tailscale foi abandonada em 15/11/2026).

## Como o código chega ao Studio

- **Rojo** (`rojo serve` neste Mac): os scripts listados em `default.project.json` entram no Studio ao salvar.
- **Geradores** (`build/phase*.luau`): rodados no Studio pelo servidor HTTP local (`python3 -m http.server 8765 --bind 127.0.0.1` em `build/`) e `run_in_studio.luau`.

O GitHub serve só de histórico e Pull Requests, não de ponte entre máquinas.

## Agentes

- **Claude Code**: integra, roda os geradores e o MCP do Studio, testa e revisa.
- **Codex** (CLI que vem no app ChatGPT: `/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex`): chamado pelo Claude com `.claude/skills/codex/codex-ask.sh` (`codex exec`). Sem o MCP do Studio (no modo não interativo ele não aprova `execute_luau`); o Claude roda o que precisar no Studio e devolve o resultado.

## Trabalho em paralelo

- Cada agente que edita código trabalha num worktree próprio: `scripts/worktree-novo.sh claude <tarefa>` ou `scripts/worktree-novo.sh codex <tarefa>` (pastas em `../roockie-rocket-wt/`).
- Worktrees que precisam do servidor HTTP usam uma porta própria (8766, 8767, …) para não misturar com o checkout principal (8765).
- `TASKS.md` diz quem está mexendo em quais arquivos. Duas tarefas abertas não compartilham arquivos.
- Tudo entra na `main` por Pull Request.
- `Place1.rbxl` só é commitado depois de salvar o place no Studio (Ctrl+S).
- Só um agente usa o Studio por vez (o Claude); o Rojo do Studio aponta para o checkout principal.
