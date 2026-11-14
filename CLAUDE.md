# NASA Space Adventure — instruções do projeto

Mapa no Roblox Studio inspirado no Kennedy Space Center. Percurso: recepção (museu/planetário na ala leste) → Corredor 1 → Launch Control Center → Corredor 2 → VAB com SLS + Mobile Launcher + crawler → saída de pedestres → área de observação da plataforma 39B (rota do crawler ao lado).

## Referências

- **Spec atual:** `spec-v3.md` (construção do mapa, §1–§15) + §16 (o que fica para depois). `spec.md` vale para o que a v3 não altera (coordenadas da recepção, corredores, museu). `spec-ultimate.md` é histórico.
- **Escopo (spec-v3 §16.10):** só construção física, validação dimensional, circulação e qualidade visual. Não implementar transporte, sincronização, zona de exclusão dinâmica, sala funcional, decolagem, DataStore nem emblemas até haver uma spec da próxima fase.
- **Notas de implementação:** `IMPLEMENTATION.md` (estado de cada etapa, validações, pendências). Atualizar a cada mudança.

## Como o mapa é gerado

O place (`Place1.rbxl`) é gerado por scripts Luau em `build/`. Não editar peças à mão no Studio: mudar o gerador e reconstruir.

| Fase | Arquivo | Conteúdo |
|---|---|---|
| 1 | `phase1_structure.luau` | Raiz `Workspace.NASAComplex`, pisos, paredes, streaming |
| 2 | `phase2_architecture.luau` | Cúpula, fachadas, portões do VAB, sala de observação |
| 3–6 | `phase3_elements` … `phase6_interactivity` | SLS, decoração, iluminação, portas automáticas |
| 8 | `phase8_crew.luau` | Vestiário, elevador e acesso à Orion + scripts `CrewAccess`/`CrewClient` |
| 9 | `phase9_transport.luau` | `TransportSystem.TransportAssembly` (crawler, ML, SLS), pivôs |
| 10 | `phase10_vab.luau` | Torres de plataformas, elevador de serviço, saída de pedestres, equipamentos |
| 11 | `phase11_launch_pad.luau` | Crawlerway, plataforma 39B, estacionamento, pontos da rota |
| 12 | `phase12_control_center.luau` | Launch Control Center e caminhos de pedestres |
| 13 | `phase13_finishing.luau` | SafetyZones, sinalização, passe de otimização |
| 14 | `phase14_relocation.luau` | Museu na ala leste da recepção (giro + translação) e ligações do LCC |
| 15 | `phase15_friendship7.luau` | Missão Friendship 7 na cápsula (missaoUm.md): botões, papel, luzes + scripts de `build/mission/` |

Reconstruir:

1. Servir `build/` em segundo plano: `python3 -m http.server 8765 --bind 127.0.0.1` (parar ao terminar).
2. Fases 1 e 2 (autônomas): carregar e executar no Edit (`loadstring(HttpService:GetAsync(...))()`).
3. `build/run_in_studio.luau`: executa as Fases 3–6 e 8–15 em ordem, passando `lib.luau`.

Regras dos geradores:

- Cada fase usa `lib.builder(N)`: toda peça recebe `BuildPhase = N`, e a fase começa com `B.clear(Map)`, então reexecutar é idempotente.
- A Fase 9 move peças das Fases 3, 5 e 8 para o conjunto de transporte. Para refazer qualquer uma delas, rode o runner inteiro (Fase 3 em diante), não a fase isolada.
- A variável local dos geradores continua `Map`, mas a raiz é `NASAComplex`.
- Coordenadas: X largura, Y altura, Z progressão do jogador; eixo central X = 0; pisos com topo em Y 0 (Baseplate em Y −1).
- Textos de placas e prompts em inglês; fontes por `FontFace` (Montserrat; `Code` na telemetria). Não usar `Enum.Font.Gotham*` (removida).
- Tudo que se move fica em `TransportSystem.TransportAssembly`; o que acompanha o conjunto usa referências relativas (`ZoneOffset`, `TargetRef`), nunca coordenadas absolutas.

## Rojo, VS Code e GitHub

- **Rojo** (fixado em `rokit.toml`) sincroniza só os scripts da missão (`build/mission/`), conforme `default.project.json`.
- Com o Rojo conectado, `ReplicatedStorage.MissionSystem` tem o atributo `RojoManaged`, e a Fase 15 não reinstala os scripts.
- Mapa e scripts embutidos nos geradores continuam pelo servidor HTTP.
- Não usar `rojo build` (o mapa não está no projeto).
- Guia de instalação e uso: `ROJO.md`.
- Remote: `git@github.com:tulioamaral123/roockie-rocket.git`.

## Trabalho em paralelo (Linux + Mac)

- Código é escrito no Linux (Claude Code e Codex), cada agente em seu worktree e branch; o Mac roda o Studio e o `rojo serve`. Ver `docs/colaboracao.md`.
- Pegar a tarefa em `TASKS.md` e listar os arquivos antes de começar; Codex segue `AGENTS.md`.
- `Place1.rbxl` só é commitado pelo Mac.
- Pelo MCP remoto (`Roblox_Studio_Mac`), sincronizar o Mac com `ssh roockie-mac sync <branch>` antes de rodar geradores.

## Validações que devem continuar passando

- **Envelope do conjunto:** X −34..34, Y 0..133 no VAB; portão dos fundos 80 × 140 (folga vertical 7, lateral ≥ 6).
- **Varredura do trajeto** (peça a peça, caixas transladadas): chegada do conjunto de Z 265 a Z 700, recuo do crawler de 700 a 620 e lateral até (90, 0, 620) — 0 interseções, exceto as folhas do portão dos fundos.
- **Visão do SLS** a partir do portão frontal (olho em (0, 4,5, 211)): nada fixo entre o visitante e o foguete.
- Playtest do percurso: recepção → museu (ala leste) → Corredor 1 → LCC → Corredor 2 → VAB → vestiário → escada → elevador → Orion → saída de pedestres → área de observação. Console sem erros.
- Missão Friendship 7: sentar no CDR → "Start mission" → Tarefas 1–3 → resumo; levantar no meio aborta e restaura a câmera.

## Studio via MCP

- Chamar `list_roblox_studios` antes de cada lote; usar o id da janela `Place1.rbxl`.
- Se o Studio estiver em Play iniciado pelo usuário, não parar sem perguntar.
- Medir desempenho com a skill `rbx-scene-analysis` (triângulos e draw calls); FPS lido do Studio em segundo plano não vale como medida.
- Skills do plugin `roblox-skills` (JoCoding) estão instaladas: consultar `roblox-engine-2026`, `roblox-pitfalls`, `roblox-ui-layout` e `roblox-ui-typography` antes de mudanças nessas áreas.

## Git

- Branch `main`. Commits só quando o usuário pedir. Não versionar `Place1.rbxl.lock`.
- Salvar o place no Studio (Ctrl+S) antes de commitar o `Place1.rbxl`.
