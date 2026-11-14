# Instruções para o Codex (e outros agentes)

As regras do projeto estão em [`CLAUDE.md`](CLAUDE.md): gerador por fases em `build/`, validações, Studio via MCP. Leia esse arquivo antes de qualquer mudança. Este arquivo só acrescenta as regras de trabalho em paralelo.

## Antes de começar

1. Pegue uma tarefa livre em [`TASKS.md`](TASKS.md), coloque `codex` como responsável e liste os arquivos que vai mexer.
2. Trabalhe no seu próprio worktree e branch, nunca na `main`:
   `scripts/worktree-novo.sh codex <nome-curto>` cria `../roockie-rocket-wt/codex-<nome-curto>` na branch `codex/<nome-curto>`.
3. Só edite os arquivos que você listou na tarefa. Se precisar de outro arquivo que outra tarefa em andamento já reservou, pare e avise.

## Arquivos com dono único

- `Place1.rbxl` é binário e não tem merge. Só o MacBook (Studio) commita esse arquivo, depois de salvar o place no Studio.
- `build/run_in_studio.luau` e `build/lib.luau` são usados por todas as fases. Quem mudar esses arquivos deve fazer isso numa tarefa própria, sozinho.
- Cada fase (`build/phaseN_*.luau`) pertence a uma tarefa por vez.

## Ao terminar

- Rode `stylua --check build` e `selene build` se estiverem instalados.
- Atualize `IMPLEMENTATION.md` e a tarefa em `TASKS.md`.
- Commit na sua branch, push, Pull Request para `main`. Nunca faça push direto na `main`.
- No PR, diga o que precisa ser rodado no Studio para testar (quais fases, qual playtest).

## Quando o Claude Code te chamar

O Claude Code pode mandar tarefas por `codex exec` (skill `.claude/skills/codex`). Trate a mensagem dele como tarefa do usuário: siga as regras acima e responda no fim com o que mudou, a branch e o que falta testar no Studio.

## Convenções

- Código e comentários seguem o estilo dos geradores existentes (tabs, nomes em inglês, comentários em português).
- Textos visíveis no jogo em inglês (regra do `CLAUDE.md`).
- Modelos 3D externos só da Roblox Creator Store, com o ID e a licença em `assets/LICENSES.md`.
