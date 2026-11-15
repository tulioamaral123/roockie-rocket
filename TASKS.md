# Tarefas

Uma linha por tarefa. Antes de começar, preencha o responsável, a branch e os arquivos que vai mexer. Duas tarefas em andamento não podem ter arquivos em comum.

Responsáveis: `claude` (Claude Code no Linux), `codex` (Codex no Linux), `mac` (Studio no MacBook), ou o nome de uma pessoa.

| # | Tarefa | Responsável | Branch | Arquivos | Estado |
|---|---|---|---|---|---|
| 1 | Teste de integração Linux → GitHub → Mac → Rojo → Studio | claude + mac | `setup/linux-colaboracao` | `build/tests/IntegracaoLinux.server.luau`, `default.project.json` | aguardando teste no Mac |
| 2 | Ligar o MCP do Studio ao Linux por SSH (Tailscale) | mac + claude | — | nenhum no repositório | a fazer (ver `docs/colaboracao.md`) |
| 3 | Museu: salão (Fase 16) | codex | `codex/museu-salao` | `build/phase16_museum_hall.luau` | aguardando teste no Mac (visual) |
| 4 | Museu: exposições (Fase 17) | codex | `codex/museu-exposicoes` | `build/phase17_museum_exhibits.luau` | aguardando teste no Mac (visual) |
| 5 | Museu: sistemas e conteúdo (Fase 18, Rojo) | claude | `setup/linux-colaboracao` | `build/museum/**`, `build/phase18_museum_systems.luau`, `default.project.json`, `build/run_in_studio.luau`, `docs/museu-contrato.md` | aguardando teste no Mac (visual) |

Estados: `a fazer`, `em andamento`, `PR aberto`, `aguardando teste no Mac`, `feito`.
