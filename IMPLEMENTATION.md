# NASA Space Adventure — Notas de implementação

Complementa o [spec.md](spec.md), que segue sendo a referência oficial. Na Revisão 2, a spec passou a incluir as medidas adotadas e o acesso da tripulação (§7.8).
Este documento registra como a spec foi implementada no Roblox Studio, como reconstruir o mapa
e quais pontos ainda dependem de decisão.

## Estado atual

As 7 fases da spec (§12) foram executadas no place aberto no Studio (**Place1**, ainda não salvo).

| Fase | Conteúdo | Gerador |
|---|---|---|
| 1. Estrutura | Pisos, paredes, aberturas dos 5 ambientes, SpawnLocation | `build/phase1_structure.luau` |
| 2. Arquitetura | Cúpula de 16 lados (Y 18→42), fachada de vidro, janelas do Corredor 1, letreiro do museu, portões do hangar, sala de observação + escada | `build/phase2_architecture.luau` |
| 3. Elementos principais | SLS Block 1 (117 studs) em 7 sub-Models, lançador móvel, 2 torres de serviço com braços, sistema solar suspenso, zonas A–E do museu | `build/phase3_elements.luau` |
| 4. Decoração | Recepção (balcão, telas, sofás, painel institucional), quadros e placas, tubulações e pórticos do Corredor 2, treliças, ponte rolante, veículos e marcações do hangar, console da sala de observação | `build/phase4_decoration.luau` |
| 5. Iluminação | 46 luzes (3 com sombra), céu estrelado na cúpula (só UI), atmosfera leve, poeira no hangar | `build/phase5_lighting.luau` |
| 6. Interatividade | Portas automáticas na saída da recepção; rotação lenta dos planetas | `build/phase6_interactivity.luau` |
| 7. Testes | Ver “Resultados dos testes” abaixo | — |
| 8. Acesso da tripulação (pedido extra) | Vestiário com trajes OCSS, elevador na torre esquerda, braço de acesso + White Room na altura da Orion, cabine ampliada da Orion (Ø 32, 4 assentos), portas no elevador e transições com tela escura | `build/phase8_crew.luau` |

Totais: 1215 peças no `Workspace.Map` (todas ancoradas; 420 sem colisão), 4 scripts e 1 RemoteEvent.

## Scripts no jogo (spec §14, item 9)

| Script | Onde fica | Função |
|---|---|---|
| `AutomaticDoors` (Script) | `ServerScriptService/Map_Systems` | Abre qualquer Model com o atributo `AutoDoor = true` quando um jogador entra no raio `SensorRadius`. As folhas são Models filhos com o atributo `OpenOffset`. |
| `PlanetOrbits` (LocalScript) | `StarterPlayer/StarterPlayerScripts` | Gira os planetas no cliente (efeito visual) usando os atributos `OrbitRadius`, `OrbitAngle`, `OrbitSpeed` e `OrbitCenter`. |

| `CrewAccess` (Script) | `ServerScriptService/Map_Systems` | Trata os ProximityPrompts do Map com o atributo `CrewAction`: `Suit` (veste/tira o traje), `Elevator` (leva quem está na cabine até a outra), `Teleport` (escotilha da Orion) e `Sit` (assentos da cabine). Também move as portas do elevador e esconde o prompt de assento ocupado. |
| `CrewClient` (LocalScript) | `StarterPlayer/StarterPlayerScripts` | Escurece a tela nas transições (pelo RemoteEvent `ReplicatedStorage.CrewFade`), mostra *Put on suit* ou *Take off suit* e desativa os prompts dos armários enquanto o jogador está dentro do elevador. |

Não há scripts em objetos individuais (spec §11).

## Convenções geométricas

- Topo de todos os pisos em **Y = 0**, com laje de Y −1 a 0; não há degraus entre ambientes.
- As dimensões da spec são **medidas internas**; as paredes ficam por fora.
- As divisórias ficam centradas nos planos Z = 55, 90, 170 e 210, com aberturas no eixo X = 0.
- Cada peça criada pelas Fases 2–6 recebe o atributo `BuildPhase`. Por isso cada gerador é idempotente: remove o que criou antes e recria.

## Como reconstruir

1. Cole `phase1_structure.luau` e depois `phase2_architecture.luau` no Command Bar (modo Edit).
2. Num terminal, sirva a pasta `build/`:
   ```bash
   cd ~/Documents/nasa/build && python3 -m http.server 8765 --bind 127.0.0.1
   ```
3. Cole `build/run_in_studio.luau` no Command Bar. Ele executa as Fases 3–6 e 8 em ordem.

## Ajustes e interpretações feitos (sem mudar decisões da spec)

- **Altura do salão do museu: 18 studs.** A cúpula nasce em Y 18 e chega a 42, o que dá uma forma quase semiesférica. O furo do teto é uma peça CSG (`Space_Adventure.Walls.Roof`).
- **Entrada do museu: portal de 12 × 9.** Fica dentro do corredor de 14 × 12, deixando espaço para o letreiro *SPACE ADVENTURE — EXPLORE THE UNIVERSE* acima dele (spec §4.3).
- **Portão do hangar.** O Corredor 2 (16 × 14) desemboca num pórtico de 24 × 30 na parede frontal do hangar. As folhas segmentadas ficam recolhidas, e o portão está aberto.
- **Portão de manutenção:** 40 × 100, fechado, em Z ≈ 319.
- **Sala de observação:** X 44–70, piso em Y 35, Z 238–262. Tem janelas voltadas para o foguete e para o portão frontal, e o acesso é por uma escada de 35 degraus junto à parede direita.
- **Zona E.** Ganhou a pasta própria `Science_Exhibition`.
- **Textos das placas em inglês**, para manter coerência com o letreiro definido na spec. Os fatos citados (datas e alturas) foram conferidos.
- **Atmosfera do template.** A `Atmosphere` padrão (densidade 0,3) e o `DepthOfField` escondiam o foguete dentro do hangar. A densidade foi reduzida para 0,04 e o DoF, desligado.
- **Spawn virado para −Z (decidido).** O jogador nasce de frente para o painel institucional (Z = 3), com o balcão à esquerda e as telas à direita, como nas posições da spec (§3.2–3.3). A saída fica às costas, indicada pela placa e pela faixa azul no piso.

## Fase 8 — acesso da tripulação

Percurso: escada do lançador → **Crew Suit-Up Room** → **Crew Elevator** → braço de acesso → **White Room** → escotilha → cabine da Orion.

- **Vestiário** (X −24..−14,5, Z 246..256, sobre o lançador). A escada de acesso do lançador chega direto nele. São 4 armários com o traje laranja OCSS; o prompt *Put on / take off* veste ou tira o traje. O traje é feito de cópias das partes do corpo em tecido laranja, com luvas, botas, capacete de vidro e patch azul. Acessórios como cabelo e chapéus ficam ocultos enquanto o traje estiver vestido. O traje é opcional e some ao renascer.
- **Elevador** (X −22,6..−17,4, Z 255,6..262, junto à torre esquerda). Tem duas cabines, uma no deck (Y 10,1) e outra no topo (Y 111,5). Cada cabine tem portas deslizantes. O prompt fecha as portas, escurece a tela de quem está dentro e leva todos para a outra cabine. Na chegada, as portas reabrem e a luz de status volta ao verde. Dentro da cabine, os armários vizinhos não roubam a tecla E. A escada de marinheiro original continua lá.
- **Plataforma final:** as colunas da torre esquerda foram prolongadas até Y ≈ 119, com um deck em Y 111,5. Esse é o topo do módulo de serviço, onde passa o braço de acesso até a White Room, encostada na cápsula. A torre direita e as passarelas da Fase 3 não mudaram.
- **Cabine da Orion.** Na escala do foguete, a cápsula tem só 3,5 studs de altura, sem espaço para um personagem. Por isso o interior é um modelo em escala humana sob o hangar, centrado em (0, −60, 265) e escondido pela Baseplate. A cabine é um polígono de 16 lados (Ø 32 no piso, Ø 19 no teto, 15 de altura). A escotilha escurece a tela e teleporta o jogador para dentro e de volta para a White Room. Lá dentro há:
  - 4 assentos reclinados (CDR, PLT, MS1, MS2), com a fileira de trás numa plataforma;
  - à frente, um console com 3 telas e controladores manuais;
  - 5 janelas com céu estrelado, painéis POWER e LIFE SUPPORT e corrimãos;
  - atrás, o compartimento de higiene, armários de estiva, bolsas de carga, placa informativa e placa de saída;
  - no teto, um anel de luz e o túnel de acoplamento.
- **Textos** dos prompts e placas em inglês, como o resto do mapa.
- **Assentos:** o prompt *Take seat* some quando o assento está ocupado e permite trocar de assento sem pular. Na cabine maior, a escotilha fica a mais de 9 studs dos assentos, então é preciso levantar (pular) e andar até ela para sair.

## Pontos que dependem de você

1. **Salvar o place.** O Place1 ainda não foi salvo; use File → Save to File ou Publish to Roblox.
2. **`Lighting.Technology = Future`.** Ajuste manualmente em Properties, porque o Studio não permite alterar isso por script. Sem Future, as SurfaceLights e as sombras dos focos ficam mais pobres.
3. **Visão do foguete ao entrar.** Pelo portão, o jogador vê imediatamente a base, os propulsores e o estágio central. O topo (Orion e torre de escape, a 127 studs) exige olhar para cima, por causa da distância de 55 studs entre o portão e o foguete definida na spec.
4. **MeshParts (spec §11).** O SLS e os planetas usam peças primitivas, leves e editáveis. Se quiser, dá para trocar por MeshParts numa etapa futura.

## Resultados dos testes (Fase 7)

- **Percurso a pé.** Um playtest com `Humanoid:MoveTo` percorreu sem travar: recepção → Corredor 1 → museu (incluindo o anel de circulação) → Corredor 2 → hangar → escada → sala de observação.
- **Porta automática.** Abre ao aproximar e fecha ao afastar.
- **Planetas.** Giram no cliente, e o anel de Saturno acompanha.
- **Fase 8.** O percurso completo funcionou em playtest: vestir o traje, subir de elevador, andar pelo braço, entrar pela escotilha, sentar, trocar de assento e sair pela escotilha. Antes da cabine ampliada, também foram testados descer de elevador e tirar o traje.
  - Nas portas do elevador e na tela escura, a sequência foi conferida por posição e transparência.
  - Raycasts confirmaram que paredes, piso e teto da cabine nova não têm frestas.
  - O rig R15 foi testado; o R6 não.
- **Console e desempenho.** O console não registrou erros, e o jogo rodou a cerca de 60 FPS no playtest local.
- **Não testado:** multiplayer com vários clientes e configurações gráficas baixas em dispositivos modestos (spec §11). Use Test → Clients and Servers no Studio.
