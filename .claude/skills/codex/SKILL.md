---
name: codex
description: Conversar com o Codex (OpenAI) pelo terminal para dividir tarefas, pedir revisão ou segunda opinião. Usar quando o usuário pedir "pede pro Codex", "manda o Codex fazer", "o que o Codex acha", ou quando uma tarefa puder ir em paralelo para o Codex num worktree separado.
---

# Conversar com o Codex

O Codex roda sem interface por `codex exec`. O script `codex-ask.sh` (nesta pasta) abre ou continua uma conversa e devolve a resposta final.

## Regras

- **Pastas separadas.** Tarefa que edita arquivos vai para um worktree do Codex, nunca para a pasta onde o Claude está trabalhando. Criar com `scripts/worktree-novo.sh codex <tarefa>` (resultado: `../roockie-rocket-wt/codex-<tarefa>`, branch `codex/<tarefa>`).
- Registrar a tarefa em `TASKS.md` com responsável `codex` e os arquivos dela antes de mandar.
- Sandbox: `read-only` para perguntas e revisões; `workspace-write` só dentro do worktree do Codex.
- A conta usada é a do `CODEX_HOME` herdado do terminal (no Mac, o atalho `claude-valter` já aponta para a conta certa). Não mudar login nem config do Codex.
- Cada chamada pode levar minutos: rodar em segundo plano (`run_in_background`) quando for tarefa de código, e seguir trabalhando.
- O Codex lê `AGENTS.md`. Na mensagem, dizer a tarefa, os arquivos permitidos e o que entregar (diff, resumo, commit na branch dele).

## Uso

Nova conversa (guarde o `THREAD_ID` impresso na primeira linha):

```bash
.claude/skills/codex/codex-ask.sh new ../roockie-rocket-wt/codex-placas workspace-write "Tarefa 3 do TASKS.md: ... Só mexa em build/phase4_decoration.luau. Ao terminar, commit na sua branch e me diga o que mudou."
```

Continuar a mesma conversa (o Codex lembra o contexto):

```bash
.claude/skills/codex/codex-ask.sh resume <THREAD_ID> "Faltou X. Ajuste e me mostre o diff."
```

Pergunta rápida ou revisão, sem editar nada:

```bash
.claude/skills/codex/codex-ask.sh new . read-only "Revise build/mission/Task1ControlService.luau procurando bugs de replicação. Liste problemas com linha."
```

## Depois da resposta

- Conferir o que o Codex fez (`git -C <worktree> log -3 --stat`, `git -C <worktree> diff main...`) antes de dizer ao usuário que está pronto.
- Resumir ao usuário em português: o que o Codex fez, o que ainda falta, e se discorda de algo, por quê.
- Integração sempre por Pull Request, como em `AGENTS.md`.
