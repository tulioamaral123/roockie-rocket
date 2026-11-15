# Salão do museu: contrato entre as tarefas

Atualizado em 14/11/2026. A spec é `museuspec.md` (cópia do "Museu Espacial no Roblox"). Este arquivo registra as decisões que a mudam e as coordenadas e nomes que as três tarefas compartilham. **Onde este arquivo e a spec discordam, vale este.**

## Decisões do usuário (14/11/2026)

| Tema | Spec | Decidido |
|---|---|---|
| Escala | 0,28 m/stud | **0,7 m/stud** (a do mapa, ~0,85, um pouco maior para impressionar). `Escala.metros(m) = m / 0.7` |
| Idioma | pt-BR | **Inglês** em tudo o que aparece no jogo (como o resto do mapa). Comentários de código em português |
| Planetário atual | — | Fica como **átrio de entrada (ilha 0)**; o salão novo cresce para leste a partir dele |
| Fonte | Gotham | `FontFace` Montserrat (Gotham foi removida) |
| Construção | Team Create + Rojo `src/` | Geometria por **geradores** em `build/` (Fases 16 e 17, regra do CLAUDE.md); sistemas de jogo por **Rojo** em `build/museum/` |

## Coordenadas (studs; Y = 0 é o topo do piso; X largura, Z para o norte do mapa)

Planetário (já existe): X 44..136, Z −13..68, centro (90, 27,5). A face leste dele (X ≈ 130..136) é a parede que a Fase 14 fechou; a Fase 16 abre ali a passagem para o salão, centrada em Z 27,5.

**Salão:** X 136..400, Z −45..100, piso Y 0, teto **Y 50** (estrutura metálica aparente). Paredes por fora desses limites.
**Átrio de vidro (jardim de foguetes):** X 200..330, Z 100..150, aberto para o salão em toda a face Z 100, teto de vidro em **Y 72**.

| Ilha | Área (X, Z) | Conteúdo |
|---|---|---|
| 0 Entrada | planetário + X 136..172, Z 5..50 | passagem, balcão, totem com mapa, `MuseumArrival`, `MuseumExit` |
| Espinha | eixo Z 27,5, X 176..334 | Saturn V deitado e suspenso, **motores F-1 voltados para oeste** (a primeira coisa vista ao entrar) |
| 1 Pioneiros | X 140..200, Z 58..100 | Mercury (cápsula, traje, painéis Corrida espacial e Mercury Seven) |
| 2 Jardim de foguetes | átrio | Mercury-Redstone e Mercury-Atlas em pé (demo) |
| 3 Apollo | sob o Saturn V, X 180..330, Z 5..50 | CM Apollo em vitrine, linha do tempo Apollo 11, diorama + console do show |
| 4 Atlantis + Hubble | X 336..400, Z 30..100 | Atlantis inclinado 43,21°, portas abertas, braço estendido; Hubble ao lado |
| 5 Memorial | X 345..400, Z −45..−5 | nicho rebaixado (piso Y −3, degraus), luz baixa e quente |
| 6 Marte | X 275..340, Z −45..−5 | rover |
| 7 Moderna | X 205..275, Z −45..−5 | Orion/SLS, Webb, ISS |
| 8 Parede de missões | X 140..205, Z −45..−5, parede Z −45 | 8 vitrines de cards |

Corredores livres de ao menos 9 studs (6 m). Sem becos sem saída.

## Medidas reais → studs (0,7 m/stud)

Fonte: `museuspec.md` §16.1. Aproximações de modelagem (não exibidas em placa) marcadas com *.

| Peça | Real | Studs |
|---|---|---|
| Saturn V total | 110,6 m | 158 |
| S-IC | 42,1 × 10,1 m | 60,1 × 14,4 |
| F-1 (altura × saída do bocal) | 5,8 × 3,8 m | 8,3 × 5,4 |
| S-II* | ~24,9 × 10,1 m | ~35,6 × 14,4 |
| S-IVB | 18 × 6,7 m | 25,7 × 9,6 |
| Unidade de instrumentos | 0,9 × 6,4 m | 1,3 × 9,1 |
| Restante (adaptador, LM, SM, CM, torre de escape)* | ~23,8 m | ~34 |
| Orbitador | 37,2 × 23,8 × 17,4 m | 53 × 34 × 25 |
| Mercury-Redstone* | ~25 m | ~36 |
| Mercury-Atlas* | ~29 m | ~41 |

Saturn V: base dos motores em X 176, ponta da torre de escape em X 334; eixo em Y 22 (fundo do S-IC a Y ~14,8). Estágios levemente separados (2–3 studs), como no salão real.

## Hierarquia e nomes (o que os sistemas leem)

- `Workspace.NASAComplex.SpaceMuseumHall` (Fase 16): arquitetura, luzes, átrio, nicho, zonas de áudio, ponto de chegada, portal de saída, Parede de missões (estrutura + vitrines).
- `Workspace.NASAComplex.SpaceMuseumExhibits` (Fase 17): veículos e objetos expostos, diorama e console do show.

**Exposição** (qualquer objeto examinável):
- `Model` com tag `Exhibit` (CollectionService) e atributo `ExhibitId` (string, igual ao `Id` do arquivo de conteúdo). `PrimaryPart` definido.
- Componentes: `Attachment` com nome igual ao `Id` do componente (ex.: `s_ic`, `f1_1`), dentro de qualquer peça do modelo.
- Uma peça `PromptAnchor` (invisível, sem colisão) onde o prompt deve aparecer; se faltar, usa o `PrimaryPart`.
- IDs da demo: `saturn_v`, `mercury_capsule`, `mercury_suit`, `space_race`, `mercury_seven`, `apollo_cm`, `apollo11_timeline`, `atlantis`, `hubble`, `memorial_apollo1`, `memorial_challenger`, `memorial_columbia`, `mercury_redstone`, `mercury_atlas`, `mars_rover`, `orion_sls`.

**Saturn V** (`ExhibitId = saturn_v`; "Explore rocket" usa estes nomes e os prefixos de peça da nave, ver `docs/museu-foguete-interativo.md`): sub-Models `Stage_S_IC`, `Stage_S_II`, `Stage_S_IVB`, `Stage_IU`, `Stage_Spacecraft`, cada um com atributo `StageIndex` (1..5) e uma peça `ShowLight` com `SpotLight` desligado (`Enabled = false`) que ilumina o estágio. Attachments: `s_ic`, `s_ii`, `s_ivb`, `iu`, `spacecraft`, `les`, `f1_1`..`f1_5`, `j2_ii_1`..`j2_ii_5`, `j2_ivb`. Os 5 F-1 usam a mesma geometria.

**Atlantis** (`atlantis`): sub-Models `PayloadDoor_L` e `PayloadDoor_R` com atributo `HingeOffset` (CFrame da dobradiça relativa ao pivô da porta) e `OpenAngle` (graus); o sistema anima. Attachments: `main_engines`, `tiles`, `wings`, `tail`, `cockpit`, `canadarm`.

**Show de lançamento** (Fase 17, ilha 3):
- `LaunchDiorama` (Model): `MiniRocket` (Model, Saturn V 1:20 do grande), peças `Exhaust` com `ParticleEmitter` desligado, `Pad`.
- `LaunchConsole` (Model): peças com tag `ConsoleLight` e atributo `Order` (1..N), `Screen` (Part com face voltada para a plateia; o sistema cria o `SurfaceGui`), peça `ShowPromptAnchor`.

**Parede de missões** (Fase 16): `MissionWall` com `CardSlot_1`..`CardSlot_8`, cada um um Model com `Glass`, `Plinth`, `ModelAnchor` (onde vai a maquete), `PhotoFrame` (Part; o sistema põe a foto) e `PointLight` desligado em `SlotLight`.

**Outros:** `MuseumArrival` (SpawnLocation, `Neutral = false`, `Enabled = true`); `MuseumExit` (Part com tag `MuseumExit` e atributo `ExitDirection` = Vector3 do sentido de quem sai; o cliente checa a posição, não usa Touched); zonas de áudio = Parts invisíveis com tag `AudioZone` e atributo `Ambience` (`hall`, `atrium`, `memorial`); placas de ilha com tag `IslandSign`.

## Orçamentos

- Fase 16: até ~2500 peças, até 40 luzes, sombra só em 3 delas. Não mexer em `Lighting` (global): só luzes locais.
- Fase 17: até ~3000 peças; Saturn V e Atlantis com `ModelStreamingMode = Persistent`, o resto `Atomic`. `CollisionFidelity`/`CanCollide = false` em peças fora do alcance.
- Nada pode fechar o caminho a pé (verificar com `Humanoid:MoveTo` ou raycasts).

## Quem faz o quê

| Tarefa | Quem | Arquivos (só estes) |
|---|---|---|
| A. Salão (Fase 16) | Codex | `build/phase16_museum_hall.luau` |
| B. Exposições (Fase 17) | Codex | `build/phase17_museum_exhibits.luau` |
| C. Sistemas + conteúdo | Claude | `build/museum/**`, `default.project.json`, `build/run_in_studio.luau`, docs |

Ninguém altera `lib.luau`, outras fases, nem salva o place. Play só pelo Claude.

---

## Revisão 2 (14/11/2026, noite): novo layout, cantos arredondados, fotos reais

Pedido do usuário (desenho): o museu sai do leste do planetário e fica **ao sul do planetário, na vertical (comprimento em Z), a leste do LCC**, ligado ao LCC por **dois corredores** no lado oeste do museu. A passagem para o planetário continua (decisão do usuário). Todas as formas com **cantos e formas arredondados**. Paredes alinhadas em toda a base. Fotos reais da NASA nos painéis.

### Transformação do museu

Os geradores continuam escrevendo nas coordenadas da tabela acima ("coordenadas de projeto") e, no fim, aplicam uma transformação rígida única a todo o seu modelo:

```lua
-- igual nas Fases 16 e 17
local MUSEUM_CF = CFrame.new(205, 0, 85) * CFrame.Angles(0, -math.pi / 2, 0) * CFrame.new(-136, 0, -27.5)
-- projeto (x, z) -> mundo (205 - (z - 27.5), 85 + (x - 136)); +X de projeto vira +Z do mundo
```

Resultado no mundo: **salão X 132,5..277,5, Z 85..349**; **átrio X 82,5..132,5, Z 149..279** (a oeste, voltado para o LCC); entrada norte (F-1 de frente) em (205, 85); memorial no lado leste; Saturn V ao longo de Z em X 205. Áreas conferidas livres no Studio. Restrições: VAB vai até X 72 para Z ≥ 209; LaunchComplex começa em Z 320 com X ≤ 128.

Regras da transformação:
- Aplicar com `model:PivotTo(MUSEUM_CF * model:GetPivot())` no fim (ou transformar cada CFrame); atributos com vetores/CFrames do mundo (`ExitDirection`, `ClosedPivot`, `EnginePlane`…) também precisam ser transformados (`MUSEUM_CF.Rotation` para direções).
- A divisão da Baseplate (fosso do memorial) usa o retângulo **já transformado** (continua alinhado aos eixos, porque o giro é de 90°).
- Câmera do show: a Fase 17 cria em `LaunchConsole` uma peça invisível `ShowCamera` (CFrame = posição da câmera olhando para o alvo; projeto: posição (300, 7, −16), alvo (303, 13, 22)) que é transformada junto. O cliente usa essa peça; o roteiro tem só o campo de visão.

### Ligações (Fase 16)
- **Planetário → museu:** abrir a face sul do planetário (Z ≈ 68) e criar uma galeria de entrada na faixa Z 68..85 que leva até a entrada norte do salão, centrada no eixo X 205 (os F-1 de frente ao entrar). Desfazer a abertura leste antiga do planetário (a da revisão 1).
- **LCC → museu (2 corredores, 12 × 12, retos, em X):** A em Z ≈ 157 (X 6 → 82,5, entra no átrio) e B em Z ≈ 119 (X 6 → 132,5, entra no salão). Abrir a parede leste do LCC (localizar as paredes por geometria, não por nome: a Fase 12 pode mudar) sem cortar telas, consoles e as ligações `LCC_Links`. Mesmo acabamento dos corredores existentes (faixas de vidro, piso, luz).
- `MuseumExit` em cada uma das 3 entradas, com `ExitDirection` apontando para fora do museu (no mundo).

### Estilo arredondado (todas as fases)
- Cantos de parede externos e internos: coluna `Cylinder` vertical (diâmetro = espessura da parede) no encontro, mesma cor/material.
- Pilares e colunas: cilindros. Balcões, bancos e pedestais: retângulo + meios-cilindros nas pontas ou cantos com cilindros (ver `B.cyl`). Vitrines com montantes cilíndricos.
- Portais e vãos: verga com chanfro (WedgePart) ou arco segmentado; batentes cilíndricos.
- Sem CSG em peças grandes (colisão ruim, ver o caso da Baseplate). Orçamento: no máximo +15% de peças por fase.

### Paredes desalinhadas (varredura no Studio, 14/11)
Juntas em T com vão: `LCC_Links.C1_Wall`/`C2_Wall` → `LCC Interior_Lining` (1,0); `LCC Interior_Lining` → `West_Wall` (0,1, duas); telas laterais do LCC → paredes (0,4–0,5); `CapeCanaveralMuseum Mars_Exhibition.Backdrop_S/W` → paredes (0,5). Linha de parede desalinhada: `Corridor_02 Hangar_Portal_L/R` × `VAB Front_Wall_L/R` (faces a 2,0). Portas e portões recuados de propósito não contam.
