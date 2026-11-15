# NASA Space Adventure — instruções do projeto

Mapa no Roblox Studio inspirado no Kennedy Space Center. Percurso: recepção (museu/planetário na ala leste) → Corredor 1 → Launch Control Center → Corredor 2 → VAB com SLS + Mobile Launcher + crawler → saída de pedestres → área de observação da plataforma 39B (rota do crawler ao lado).

## Referências

- **Spec atual:** `spec-v3.md` (construção do mapa, §1–§15) + §16 (o que fica para depois). `spec.md` vale para o que a v3 não altera (coordenadas da recepção, corredores, museu). `spec-ultimate.md` é histórico.
- **Missões (Rookie Rocket):** `docs/rookie-rocket-spec.md` (missões Mercury e ISS, co-op 1–4, peso, estrelas, DataStore, Álbum) e `docs/rookie-contrato.md` (nomes das peças × scripts). Textos em inglês. Substitui a missão sentada da antiga Fase 15.
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
| 16 | `phase16_museum_hall.luau` | Salão do museu a leste do planetário, átrio, memorial rebaixado (divide a Baseplate), Parede de missões (`museuspec.md`, `docs/museu-contrato.md`) |
| 17 | `phase17_museum_exhibits.luau` | Exposições do museu: Saturn V, Atlantis, Mercury, jardim de foguetes, diorama e console do show |
| 18 | `phase18_museum_systems.luau` | Instala os sistemas do museu de `build/museum/` (painel, show, cards, progresso) quando o Rojo não está conectado |
| 19 | `phase19_rookie_mercury.luau` | Rookie Rocket: cápsula Mercury navegável (−3000, 1200, 0), quiosque Mission Briefing no LCC; apaga a antiga Fase 15 |
| 20 | `phase20_rookie_iss.luau` | Rookie Rocket: módulo da ISS, Cupola, Airlock/EVA, Unity/Zarya, Terra (3000, 1200, 0) |
| 21 | `phase21_rookie_systems.luau` | Instala os scripts de `build/rookie/` quando o Rojo não está conectado |
| 22 | `phase22_guides.luau` | Guias Marcos Pontes e Ana: `NASAComplex.Guides` (NPCs, NavigationPoints) + scripts de `build/guide/` sem Rojo (`docs/guias-spec.md`, `docs/guias-contrato.md`) |
| 23 | `phase23_landscape.luau` | Paisagismo: palmeiras sabal e carvalhos na grama (`NASAComplex.Landscape.Trees`), sorteio com semente fixa, fora do complexo de lançamento, da visão da área de observação e do eixo da recepção |
| 24 | `phase24_outdoor.luau` | Ambientação externa (`docs/paisagismo-spec.md`): estrada, praça da entrada, estacionamento de visitantes, jardins do planetário, lago com mirante, arbustos e nuvens, em `NASAComplex.Landscape` (pasta compartilhada com a 23, sem `BuildPhase`) |

Reconstruir:

1. Servir `build/` em segundo plano: `python3 -m http.server 8765 --bind 127.0.0.1` (parar ao terminar).
2. Fases 1 e 2 (autônomas): carregar e executar no Edit (`loadstring(HttpService:GetAsync(...))()`).
3. `build/run_in_studio.luau`: executa as Fases 3–6, 8–14 e 16–24 em ordem, passando `lib.luau`.

Regras dos geradores:

- Cada fase usa `lib.builder(N)`: toda peça recebe `BuildPhase = N`, e a fase começa com `B.clear(Map)`, então reexecutar é idempotente.
- A Fase 9 move peças das Fases 3, 5 e 8 para o conjunto de transporte. Para refazer qualquer uma delas, rode o runner inteiro (Fase 3 em diante), não a fase isolada.
- A variável local dos geradores continua `Map`, mas a raiz é `NASAComplex`.
- Coordenadas: X largura, Y altura, Z progressão do jogador; eixo central X = 0; pisos com topo em Y 0 (Baseplate em Y −1).
- Textos de placas e prompts em inglês; fontes por `FontFace` (Montserrat; `Code` na telemetria). Não usar `Enum.Font.Gotham*` (removida).
- Tudo que se move fica em `TransportSystem.TransportAssembly`; o que acompanha o conjunto usa referências relativas (`ZoneOffset`, `TargetRef`), nunca coordenadas absolutas.

## Rojo, VS Code e GitHub

- **Rojo** (fixado em `rokit.toml`) sincroniza **todos os scripts** (`default.project.json`): `build/rookie/` (missões Rookie Rocket), `build/guide/` (guias e seta), `build/museum/` (museu), `build/systems/server` → `ServerScriptService.Map_Systems` (AutomaticDoors, CrewAccess) e `build/systems/client` → `StarterPlayerScripts.MapClient` (PlanetOrbits, CrewClient).
- Com o Rojo conectado, as pastas têm o atributo `RojoManaged` e as fases (6, 8, 18, 21) não reinstalam os scripts; sem Rojo, `lib.installSystemScript` baixa de `build/systems/` pelo HTTP.
- Scripts novos vão em arquivos nessas pastas, nunca como texto embutido em gerador.
- Só o mapa (peças) continua pelo servidor HTTP. Não usar `rojo build` (o mapa não está no projeto).
- Guia de instalação e uso: `ROJO.md`. Remote: `git@github.com:tulioamaral123/roockie-rocket.git`.

## Economia de tokens (padrão de trabalho)

- Mudança em script: editar só o arquivo `.luau`; o Rojo leva ao Studio. Não abrir o Studio pelo MCP para isso.
- Não usar MCP do Studio (screenshot, `execute_luau`, `inspect_instance`, playtest) sem o usuário pedir. Ele testa e cola o erro do Output.
- Ler só o trecho necessário (`grep -n` e depois `sed -n` / `Read` com offset), nunca arquivos inteiros grandes (specs, geradores).
- Não reler arquivo que acabou de editar; respostas curtas; não repetir o plano no texto.
- `IMPLEMENTATION.md`: só uma linha curta por mudança, no fim do arquivo.

## Trabalho em paralelo (só no Mac)

- Tudo roda neste Mac: Claude Code, Codex (CLI do app ChatGPT, pela skill `codex`), Studio e `rojo serve`. Não há Linux nem acesso remoto. Ver `docs/colaboracao.md`.
- Agente que edita código trabalha em worktree e branch próprios (`scripts/worktree-novo.sh`); pegar a tarefa em `TASKS.md` e listar os arquivos antes de começar; Codex segue `AGENTS.md`.
- O Studio é usado só pelo Claude; o Codex roda sem o MCP do Studio.

## Validações que devem continuar passando

- **Envelope do conjunto:** X −34..34, Y 0..133 no VAB; portão dos fundos 80 × 140 (folga vertical 7, lateral ≥ 6).
- **Varredura do trajeto** (peça a peça, caixas transladadas): chegada do conjunto de Z 265 a Z 700, recuo do crawler de 700 a 620 e lateral até (90, 0, 620) — 0 interseções, exceto as folhas do portão dos fundos.
- **Visão do SLS** a partir do portão frontal (olho em (0, 4,5, 211)): nada fixo entre o visitante e o foguete.
- Playtest do percurso: recepção → museu (ala leste) → Corredor 1 → LCC → Corredor 2 → VAB → vestiário → escada → elevador → Orion → saída de pedestres → área de observação. Console sem erros.
- Rookie Rocket: quiosque no LCC → Board → Preparação (80 kg falha na plataforma) → Tasks 1–3 → resultado com a equação e estrelas → Álbum; Retry task / Restart mission; o mesmo na ISS (EVA na Task 2).

## Studio via MCP

- Chamar `list_roblox_studios` antes de cada lote; usar o id da janela `Place1.rbxl`.
- Se o Studio estiver em Play iniciado pelo usuário, não parar sem perguntar.
- Medir desempenho com a skill `rbx-scene-analysis` (triângulos e draw calls); FPS lido do Studio em segundo plano não vale como medida.
- Skills do plugin `roblox-skills` (JoCoding) estão instaladas: consultar `roblox-engine-2026`, `roblox-pitfalls`, `roblox-ui-layout` e `roblox-ui-typography` antes de mudanças nessas áreas.

## Git

- Branch `main`. Commits só quando o usuário pedir. Não versionar `Place1.rbxl.lock`.
- Salvar o place no Studio (Ctrl+S) antes de commitar o `Place1.rbxl`.
