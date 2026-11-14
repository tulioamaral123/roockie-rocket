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
| 8. Acesso da tripulação (pedido extra) | Vestiário com trajes espaciais brancos da NASA, elevador na torre esquerda, braço de acesso + White Room na altura da Orion, cabine ampliada da Orion (Ø 32, 4 assentos), portas no elevador e transições com tela escura | `build/phase8_crew.luau` |

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
3. Cole `build/run_in_studio.luau` no Command Bar. Ele executa as Fases 3–6, 8 e 9 em ordem.

A Fase 9 move peças das Fases 3, 5 e 8 para o conjunto de transporte. Para refazer qualquer uma dessas fases, rode o runner inteiro (a partir da Fase 3), e não a fase isolada.

## Ajustes e interpretações feitos (sem mudar decisões da spec)

- **Altura do salão do museu: 18 studs.** A cúpula nasce em Y 18 e chega a 42, o que dá uma forma quase semiesférica. O furo do teto é uma peça CSG (`Space_Adventure.Walls.Roof`).
- **Entrada do museu: portal de 12 × 9.** Fica dentro do corredor de 14 × 12, deixando espaço para o letreiro *SPACE ADVENTURE — EXPLORE THE UNIVERSE* acima dele (spec §4.3).
- **Portão do hangar.** O Corredor 2 (16 × 14) desemboca num pórtico de 24 × 30 na parede frontal do hangar. As folhas segmentadas ficam recolhidas, e o portão está aberto.
- **Portão dos fundos:** 80 × 140, fechado, em Z ≈ 319 (era 40 × 100; ampliado na Etapa 1 da spec-v3).
- **Sala de observação:** X 44–70, piso em Y 35, Z 238–262. Tem janelas voltadas para o foguete e para o portão frontal, e o acesso é por uma escada de 35 degraus junto à parede direita.
- **Zona E.** Ganhou a pasta própria `Science_Exhibition`.
- **Textos das placas em inglês**, para manter coerência com o letreiro definido na spec. Os fatos citados (datas e alturas) foram conferidos.
- **Atmosfera do template.** A `Atmosphere` padrão (densidade 0,3) e o `DepthOfField` escondiam o foguete dentro do hangar. A densidade foi reduzida para 0,04 e o DoF, desligado.
- **Spawn virado para −Z (decidido).** O jogador nasce de frente para o painel institucional (Z = 3), com o balcão à esquerda e as telas à direita, como nas posições da spec (§3.2–3.3). A saída fica às costas, indicada pela placa e pela faixa azul no piso.

## Fase 8 — acesso da tripulação

Percurso: **Crew Suit-Up Room** (piso do VAB) → escada do lançador → **Crew Elevator** → braço de acesso → **White Room** → escotilha → cabine da Orion.

- **Vestiário** (sala fixa no piso do VAB, X −46,2..−36,3, Z 245,8..256,2, fora do envelope de transporte). Entrada pela face −Z, do lado do portão frontal; a porta da face +X (placa *TO MOBILE LAUNCHER*) dá para a escada do lançador. Até a Etapa 3 ele ficava sobre o deck do lançador. São 4 armários com o traje espacial branco; o prompt veste ou tira o traje. O traje é a camisa e a calça de astronauta criadas no ForgeGUI e enviadas ao Roblox (Shirt `rbxassetid://106949180814943`, Pants `rbxassetid://82940626824190`), mais capacete de vidro e anel do pescoço. A roupa original do jogador fica guardada e volta ao tirar o traje. Acessórios como cabelo, chapéus e roupas 3D ficam ocultos enquanto o traje estiver vestido. O traje é opcional e some ao renascer.
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

## spec-v3 — Etapa 1 (validação dimensional)

Aplicada no Studio e nos geradores (`phase2_architecture.luau`, `phase4_decoration.luau`):

- **Portão dos fundos 80 × 140** (X −40..40), com 7 folhas de 20, batentes e verga em Y 140–142. A parede dos fundos mantém 152 de altura.
- **Letreiro "SPACE LAUNCH SYSTEM"** passou para Y 142–151, acima do portão.
- **Ponte rolante:** trolley, cabo e gancho estacionados em X = 54. A viga (Y 136–139) e as vigas do telhado (Y 143–146) ficam acima do envelope.
- **Blocos de referência** no Model `Workspace.Etapa1_Validation`, sem colisão, já na posição da Etapa 2 (+5,5): crawler (Y 0–7), base do ML (7–15,5), torre (15,5–125,5), SLS (16–133). Contorno vermelho = envelope na posição inicial; verde = varredura até Z 370. Foram apagados ao fim da Etapa 2, depois de validar o conjunto real.

Resultado da varredura (X −34..34, Y 0..133, Z 235..370, excluindo o próprio conjunto):

- Nenhuma estrutura fixa do hangar invade o caminho.
- No caminho só ficam as folhas do portão, que precisam abrir, e luzes que pertencem ao conjunto (`Lighting_Objects.Hangar.Rocket_Flood` sobre o deck e `Tower_Flood` na torre esquerda). Essas luzes devem entrar no `TransportAssembly` na Etapa 2.
- Vão livre medido: X −40..40, altura 140.
- **Base do ML com 8,5 (decidido).** O SLS mede 117 e fica 0,5 acima do deck, sobre os holddown posts. Com base de 9 o topo iria a 133,5 (folga de 6,5). Com base de 8,5 (Y 7–15,5) o topo fica em 133 e a folga é de 7,0, medida no Studio. Na Etapa 2 tudo sobre o deck sobe +5,5.

Pendências encontradas:

- **Abertura do portão.** Acima de 140 sobram só 12 studs de parede, então as folhas não têm onde subir por dentro. O mecanismo (folhas telescópicas que sobem por fora da parede, como no VAB real, ou outra solução) fica para quando o transporte for implementado.
- **Desnível na saída.** O piso do hangar está em Y 0 e a Baseplate em Y −1. A rota do crawler (Etapa 5) precisa de piso em Y 0.

## spec-v3 — Etapa 2 (conjunto móvel)

Gerador novo: `build/phase9_transport.luau` (Fase 9, incluído no `run_in_studio.luau`). Hierarquia criada:

```text
Map.TransportSystem
├── TransportAssembly            pivô (0, 0, 265)
│   ├── CrawlerTransporter       pivô (0, 0, 265)
│   ├── MobileLauncher           pivô (0, 7, 265)
│   │   ├── Base                 deck Y 7–15,5, chapa, holddown posts, escada de 15 degraus, 4 luzes do deck
│   │   ├── ServiceTower         antiga torre esquerda + elevador da tripulação + luz da torre
│   │   ├── Umbilicals           Umbilical_40 e Umbilical_60, pivô na articulação (X −17)
│   │   ├── AccessArms           Crew_Access_Arm (pivô X −17,4, Y 117) + Service_Arm_100
│   │   └── WhiteRoom
│   └── SLSRocket                pivô (0, 16, 265)
└── CrawlerRoute
    └── Start_VAB                (0, 0, 265), invisível
```

- **Crawler** (Y 0–7, 38 × 36): estrutura superior, corpo inferior, 4 truques com 2 esteiras cada, cilindros de nivelamento e 2 cabines de operação em cantos opostos com sinalizador âmbar. Substitui os 6 pedestais do lançador.
- **Tudo sobre o deck subiu +5,5:** SLS de Y 16 a 133, torre até Y 125, elevador (cabines em Y 15,6 e 117), braço e White Room em Y 117.
- **Torre direita removida**, junto com a luz dela.
- **Prompts:** as zonas e destinos do elevador e a saída da Orion subiram +5,5. A entrada da Orion (para a cabine sob o hangar) não mudou.
- **Vestiário:** subiu com o deck, mas continua em `Rocket_Hangar.Crew_Access`, fora do conjunto. A Etapa 3 o leva para uma sala fixa no piso do VAB.
- As pastas `Launch_Platform`, `Gantry` e `SLS_Rocket` do hangar ficaram vazias. Continuam existindo porque as Fases 3–8 escrevem nelas.

Validação no Studio:

- Conjunto completo: X −25..24,1 (49 de largura), Y 0..133, Z 230..287,1.
- Varredura do caminho (X −34..34, Y 0..133, de Z 230 até 370): só as 7 folhas do portão dos fundos e a faixa de segurança delas.
- Topo dos holddown posts = base do SLS = Y 16.
- Playtest: o personagem subiu a escada até o deck, foi do vestiário ao elevador, subiu até Y 120, andou pelo braço, entrou na Orion pela escotilha e saiu de volta na White Room em (−5, 120, 265). Sem erros dos scripts no console.

As zonas do elevador e a saída da Orion passaram a ser relativas na Etapa 3 (ver abaixo).

## spec-v3 — Etapa 3 (acesso da tripulação)

Mudanças no `phase8_crew.luau` (a Fase 9 deixou de corrigir coordenadas):

- **Vestiário no piso do VAB.** É montado nas coordenadas antigas e transladado por (−22, −10,1, 0): fica em X −46,2..−36,3, Y 0..9,3, Z 245,8..256,2. A parede que dava para o elevador foi fechada, a placa *CREW ELEVATOR* virou *TO MOBILE LAUNCHER* (na porta +X) e o texto da placa dos trajes agora manda subir a escada do lançador.
- **Elevador relativo.** Cada cabine tem `PrimaryPart` = piso e os atributos `ZoneOffset` (centro da zona de passageiros, relativo ao piso) e `ZoneSize`. O painel leva quem está na própria cabine até a outra cabine, lendo a posição atual das duas. Os prompts não guardam mais `ZoneCenter`/`Target`.
- **Portas do elevador relativas.** As posições aberta e fechada ficam guardadas em relação ao piso da cabine.
- **Escotilhas por referência.** Cada prompt de escotilha tem um `ObjectValue` `TargetRef`. O de fora aponta para `Orion_Cabin.Entry_Point`; o de dentro, para `WhiteRoom.Exit_Point`, que viaja com o lançador.
- **CrewClient** lê as zonas das cabines na posição atual (e ignora cabines que o streaming ainda não carregou).

Validação (reconstrução das Fases 3–9 pelo runner e playtest):

- A reconstrução recriou tudo sem duplicatas: 1 SLS, 1 crawler, 4 luzes do deck no conjunto, 1 luz da torre.
- Percurso completo: vestiário (traje vestido) → porta +X → pé da escada → deck → elevador (Y 18,8 → 120) → braço → Orion → saída na White Room (−5, 120, 265).
- **Teste com o conjunto deslocado** (só durante o Play): com o `TransportAssembly` movido +30 em Z, a saída da Orion levou o personagem a (−5, 120, 295) e o elevador desceu da cabine de cima até a de baixo em Z ≈ 289. As portas das duas cabines ficaram na posição certa em relação a cada cabine.
- Console sem erros.
- Observação de teste: prompts com tempo de segurar (os armários usam 0,4 s) não disparam com `InputHoldBegin` simulado; no teste o tempo foi zerado só no cliente da sessão de Play.

## Pontos que dependem de você

1. **Salvar o place.** O Place1 ainda não foi salvo; use File → Save to File ou Publish to Roblox.
2. **`Lighting.Technology = Future`.** Ajuste manualmente em Properties, porque o Studio não permite alterar isso por script. Sem Future, as SurfaceLights e as sombras dos focos ficam mais pobres.
3. **Visão do foguete ao entrar.** Pelo portão, o jogador vê imediatamente a base, os propulsores e o estágio central. O topo (Orion e torre de escape, a 127 studs) exige olhar para cima, por causa da distância de 55 studs entre o portão e o foguete definida na spec.
4. **MeshParts (spec §11).** O SLS e os planetas usam peças primitivas, leves e editáveis. Se quiser, dá para trocar por MeshParts numa etapa futura.

## Resultados dos testes (Fase 7)

- **Percurso a pé.** Um playtest com `Humanoid:MoveTo` percorreu sem travar: recepção → Corredor 1 → museu (incluindo o anel de circulação) → Corredor 2 → hangar → escada → sala de observação.
- **Porta automática.** Abre ao aproximar e fecha ao afastar.
- **Planetas.** Giram no cliente, e o anel de Saturno acompanha.
- **Fase 8.** O percurso completo funcionou em playtest: vestir o traje, subir de elevador, andar pelo braço, entrar pela escotilha, sentar, trocar de assento e sair pela escotilha. Antes da cabine ampliada, também foi testado descer de elevador. O traje branco da NASA foi testado vestindo e tirando: as roupas originais voltaram.
  - Nas portas do elevador e na tela escura, a sequência foi conferida por posição e transparência.
  - Raycasts confirmaram que paredes, piso e teto da cabine nova não têm frestas.
  - O rig R15 foi testado; o R6 não.
- **Console e desempenho.** O console não registrou erros, e o jogo rodou a cerca de 60 FPS no playtest local.
- **Não testado:** multiplayer com vários clientes e configurações gráficas baixas em dispositivos modestos (spec §11). Use Test → Clients and Servers no Studio.
