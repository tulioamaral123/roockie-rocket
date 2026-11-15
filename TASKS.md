# Tarefas

Uma linha por tarefa. Antes de começar, preencha o responsável, a branch e os arquivos que vai mexer. Duas tarefas em andamento não podem ter arquivos em comum.

Responsáveis: `claude` (Claude Code), `codex` (Codex), `mac` (teste no Studio), ou o nome de uma pessoa. Tudo roda neste Mac (ver `docs/colaboracao.md`).

| # | Tarefa | Responsável | Branch | Arquivos | Estado |
|---|---|---|---|---|---|
| 1 | Teste de integração Linux → GitHub → Mac → Rojo → Studio | claude + mac | `setup/linux-colaboracao` | `build/tests/IntegracaoLinux.server.luau`, `default.project.json` | cancelada (sem Linux) |
| 2 | Ligar o MCP do Studio ao Linux por SSH (Tailscale) | mac + claude | — | nenhum no repositório | cancelada (sem Linux) |
| 3 | Museu: salão (Fase 16) | codex | `codex/museu-salao` | `build/phase16_museum_hall.luau` | aguardando teste no Mac (visual) |
| 4 | Museu: exposições (Fase 17) | codex | `codex/museu-exposicoes` | `build/phase17_museum_exhibits.luau` | aguardando teste no Mac (visual) |
| 5 | Museu: sistemas e conteúdo (Fase 18, Rojo) | claude | `setup/linux-colaboracao` | `build/museum/**`, `build/phase18_museum_systems.luau`, `default.project.json`, `build/run_in_studio.luau`, `docs/museu-contrato.md` | aguardando teste no Mac (visual) |
| 6 | Rookie Rocket: missões Mercury e ISS (docs/rookie-rocket-spec.md) | claude + codex | `claude/rookie-rocket` (+ `codex/rookie-mercury`, `codex/rookie-iss`) | `build/rookie/**`, `build/phase19_rookie_mercury.luau`, `build/phase20_rookie_iss.luau`, `build/phase21_rookie_systems.luau`, `default.project.json`, `build/run_in_studio.luau` | aguardando teste no Studio |
| 7 | Guias Marcos Pontes e Ana + seta de navegação (docs/guias-spec.md) | claude | `claude/rookie-rocket` | `build/guide/**`, `build/phase22_guides.luau`, `build/rookie/server/GerenciadorMissao.server.luau` (ponte), `default.project.json`, `build/run_in_studio.luau`, `docs/guias-*.md` | aguardando teste no Studio |

| 8 | Missões: traje obrigatório, cápsulas compactas, gravidade local, seta e trade-off com Ana | codex | `codex/missoes-capsula` | `build/phase19_rookie_mercury.luau`, `build/phase20_rookie_iss.luau`, `build/systems/server/CrewAccess.server.luau`, `build/rookie/server/{GerenciadorMissao.server,Sessao,Naves,TasksMercury,TasksISS}.luau`, `build/rookie/client/{RookieClient.client,Capsule,Hud}.luau`, `build/guide/server/NPCService.luau`, `build/guide/client/{MissionSelect,NavigationClient}.luau`, `docs/rookie-contrato.md`, `docs/guias-contrato.md`, `IMPLEMENTATION.md`, `TASKS.md` | aguardando teste no Mac; commit/push/PR bloqueados pelo sandbox do Git e conector GitHub sem acesso (404) |
| 9 | Melhorias após playtest (docs/rookie-melhorias-playtest.md) | claude | `claude/rookie-rocket` | `build/guide/**`, `build/rookie/**`, `build/museum/client/PanelController.luau`, `build/phase19_rookie_mercury.luau`, `build/phase20_rookie_iss.luau`, `docs/rookie-contrato.md`, `docs/rookie-melhorias-playtest.md` | aguardando teste no Studio |

Estados: `a fazer`, `em andamento`, `PR aberto`, `aguardando teste no Mac`, `feito`, `cancelada`.
