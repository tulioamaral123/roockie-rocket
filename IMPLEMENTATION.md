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
3. Cole `build/run_in_studio.luau` no Command Bar. Ele executa as Fases 3–6 e 8–13 em ordem.

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
│   │   ├── Base                 deck Y 7–15,5, chapa, holddown posts, escada lateral (X −30..−24), 4 luzes do deck
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

## spec-v3 — Etapa 4 (VAB)

Gerador novo: `build/phase10_vab.luau` (Fase 10, idempotente, incluído no runner). Tudo fica fora do envelope de transporte.

- **Saída de pedestres** na parede esquerda (X = −70, Z 296..302, 6 × 10), com porta automática de duas folhas (sistema `AutomaticDoors`, sensor de 9 studs), placa verde *EXIT — LAUNCH COMPLEX* e patamar externo de concreto no nível do piso do hangar (Y 0; a Baseplate está em −1). A parede esquerda inteira da Fase 1 foi trocada por três trechos com o vão.
- **Torres de plataformas** (`Rocket_Hangar.Work_Platforms`), uma de cada lado: X ±36..±46, Z 262..290, até Y 112. Seis níveis (Y 30, 45, 60, 75, 90, 105), cada um com deck, guarda-corpo dos dois lados e nas pontas, e uma **plataforma retrátil recolhida** (`Work_Platform`, atributos `WorkPlatform = true` e `ExtendOffset` = ∓22 em X, que leva a borda a 14 studs do eixo) para o futuro `WorkPlatformController`. Na torre esquerda, os níveis 30 e 45 deixam livre o poço do elevador. Placas *WORK PLATFORMS* voltadas para o foguete.
- **Elevador de serviço** na torre esquerda (`Platform_Tower_L.Service_Elevator`): piso do hangar ↔ nível 60. Usa o sistema do `CrewAccess` sem mudar o script: cabines `Cab_Floor` e `Cab_Level60` com `ZoneOffset`/`ZoneSize`, painel com prompt `CrewAction = "Elevator"`, portas com `OpenOffset`.
- **Segunda ponte rolante** (`Structure.Bridge_Crane_2`, Z 240), com trolley e gancho estacionados em X = −54.
- **Equipamentos industriais** (`Rocket_Hangar.Industrial_Equipment`): três linhas de tubulação em cada parede (Y 20–25; a da direita para antes da escada da sala de observação), descidas de tubo, 4 painéis elétricos com indicadores, 2 bancadas com ferramentas, dutos de ventilação junto ao teto (Y 118–122), 4 câmeras nos pilares, 2 pilhas de caixas técnicas e barreira em frente ao pé da torre direita.
- **Iluminação:** 3 faixas com SurfaceLight sob os níveis 30, 60 e 90 de cada torre, e luz em cada cabine do elevador de serviço (sem sombras).
- **Plataforma tesoura** (Fase 4) deslocada para X 52..58, liberando o pé da torre direita.

Validação:

- Varredura do envelope (X −34..34, Y 0..133, Z 230..370): continua só com as folhas do portão dos fundos.
- Sobreposições entre peças colidíveis da Fase 10 e de outras fases: só o piso da cabine `Cab_Floor` encostado no piso do hangar (esperado).
- Visão a partir do portão frontal: as torres ficam nas laterais e o SLS segue visível de imediato.
- Playtest: a porta de pedestres abriu ao aproximar (folha L recolheu 2,5 studs), o personagem saiu ao patamar externo e voltou; o elevador de serviço subiu do piso ao nível 60 (Y 3 → 63) e desceu; no nível 60 o guarda-corpo do lado do foguete segurou o personagem em X ≈ −37,3. Console sem erros.
- Contagem depois da Etapa 4: 770 peças no hangar, 326 no conjunto de transporte, 1645 no `Map`; 59 luzes no workspace.

## spec-v3 — Etapa 5 (área externa)

Feita por dois agentes em paralelo, cada um com um gerador e uma faixa do mapa (fronteira em X = −85), e integrada depois.

**Fase 11 — `build/phase11_launch_pad.luau`** (`Map.LaunchComplex`, 602 peças, 9 luzes):

- **Crawlerway** reto em X = 0, de Z 321 a 660, 90 de largura, piso em Y 0 (lajes −1..0) com faixas de cascalho sob as esteiras e canteiro central. A zona de exclusão (X ±40) só tem marcações sem colisão. Uma soleira (`Crawlerway.Threshold`, Z 320,2..321) fecha a fresta entre o portão dos fundos e a rota.
- **Plataforma 39B:** hardstand X −80..92, Z 660..724. Destino do pivô do conjunto em (0, 0, 700). Seis pedestais com topo em Y 7 (X ±22,3..±24, Z 685/700/715), fora da faixa do crawler, com atributo `SupportsMobileLauncher`. Trincheira de chamas e defletor no sentido +Z (Z 724..820), acima do chão. Sem torre de serviço fixa.
- **Estruturas:** esferas de LH2 (70, 738) e LOX (−60, 748) com tubulação até umbilicais de solo em X ±35..39; torre de água em (48, 812), até Y 105; três torres de para-raios até Y 200 com catenária sem colisão (ponto mais baixo Y ≈ 177); cercas na rota, na plataforma e no estacionamento.
- **Estacionamento do crawler:** laje X 62..122, Z 586..660, vaga centrada em (90, 620), ligada à rota por um ramal.
- **Pontos da rota** em `TransportSystem.CrawlerRoute`: Point_01..06 (Z 321..665, atributos `Order` e `Leg`), `Destination_LaunchPad` (0, 0, 700) e `Parking_Crawler` (90, 0, 620). A ida ao estacionamento é: recuar até Point_05 (Z 620) e andar de lado em +X.

**Fase 12 — `build/phase12_control_center.luau`** (`Map.Launch_Control_Center` e `Map.Visitor_Paths`, 501 peças, 14 luzes):

- **Launch Control Center** em X −150..−95, Z 250..320, com portas automáticas a leste (alinhada com a saída de pedestres do VAB) e ao norte. **Firing Room** com quatro fileiras de 8 estações em degraus (Y 0–3), telão principal (T− 00:00:00 HOLD) e telas laterais estáticas, diagramas, racks de comunicação e janelas voltadas para a plataforma.
- **Console principal** (`Consoles.Main_Console`, atributo `FutureInteraction = "StartOperation"`, peça `Interface_Anchor`). As estações têm `FutureInteraction = "Station"`. Nada funcional ainda; as cadeiras são Parts, não Seats.
- **Caminhos de pedestres:** do patamar da saída do VAB até o LCC e um passeio em X −105..−97 até a **área de observação** (X −140..−95, Z 640..720) com arquibancada coberta, lunetas e painéis. Tudo em X ≤ −82, sem cruzar a rota; placas "CRAWLERWAY — NO ENTRY" junto ao passeio.

**Integração:**

- **Escada da base do ML movida** para a lateral −X (X −30..−24, sobe em +Z de Z 234 a 249, patamar até Z 252). Antes ela ficava na faixa das esteiras do crawler e impedia o recuo na plataforma. Fica mais perto do vestiário e dentro do envelope (largura do conjunto agora X −30..24,1 = 54).
- **Sinalizadores das cabines do crawler** passaram para a face externa da cabine, abaixo de Y 7, porque passariam sob o deck do ML no recuo.
- Runner com as Fases 11 e 12; reconstrução completa das Fases 3–12 sem erros nem duplicatas.

Validação conjunta (por varredura de caixas, peça a peça):

- **Chegada** do conjunto inteiro de Z 265 a Z 700: só o portão dos fundos, que precisa abrir.
- **Recuo do crawler** de Z 700 a 620 com o ML e o SLS na plataforma: 0 interseções. **Lateral** até o estacionamento (X 0 → 90 em Z 620): 0 interseções.
- Na plataforma, só os pedestais tocam a base do ML (em Y 7).
- Agente B: playtest do patamar do VAB até a Firing Room (porta leste), subida dos degraus, saída pela porta norte, passeio até a arquibancada da área de observação. Console sem erros.

## spec-v3 — Etapa 6 (migração e acabamento)

### Migração da hierarquia

A raiz agora é `Workspace.NASAComplex` (tabela de nomes antigos e novos no §11.1 da `spec-v3.md`). Os geradores continuam usando a variável local `Map`, mas procuram `NASAComplex`; os quatro scripts (`AutomaticDoors`, `CrewAccess`, `CrewClient`, `PlanetOrbits`) também. A Fase 1 apaga tanto `NASAComplex` quanto um `Map` antigo antes de recriar.

As seções anteriores deste documento mantêm os nomes da época em que foram escritas (`Map`, `Rocket_Hangar`, `Space_Adventure`, `Suit_Room`, `Orion_Cabin`).

Validação: o mapa foi reconstruído do zero (Fases 1, 2 e runner 3–12) sem erros, com 2751 peças no `NASAComplex`. As varreduras do conjunto (chegada à plataforma, recuo do crawler e ida ao estacionamento) continuaram com 0 interseções fora do portão dos fundos.

### Acabamento — `build/phase13_finishing.luau` (Fase 13)

Feito em paralelo com o teste de circulação, por dois agentes, e integrado depois.

- **`NASAComplex.SafetyZones`** (Parts invisíveis, sem colisão, atributos `SafetyZone`, `ZoneType`, `Purpose`, `Min`, `Max`) para o futuro `PlayerSafetyController`: `VABObservationZone` (sala de observação), `VABEnvelopeZone` (X −34..34, Y 0..133, Z 230..320), `RouteExclusionZone` (X −40..40, Z 320..722), `CrawlerParkingZone` (centro 90, 0, 620) e `LaunchPadObservationZone` (área de observação).
- **Sinalização no VAB** (`VABHangar.Wayfinding_VAB`, decorativa): quadro de direções suspenso na treliça da entrada, em X −24..−4 (fora do cone de visão do SLS), linha de piso até o vestiário com etiqueta, placa do elevador de serviço, placa da saída de pedestres e o painel *ONE ROCKET, ONE JOURNEY* sobre o conjunto de transporte.
- **Otimização** (todo o `NASAComplex` menos o conjunto de transporte, 2450 peças): `CastShadow = false` em 1027 peças pequenas ou decorativas e `CanTouch = false` em 1253 peças ancoradas (nenhum script usa `Touched`). `CanCollide` e `CanQuery` não mudaram. Reaplicar não muda nada.

### Correções da integração

- **Cercas da rota fechadas** (Fase 11): `Crawlerway_Fence_W` e `_E` agora começam em Z 321,5, encostadas na parede dos fundos do VAB (antes havia uma passagem de Z 321 a 331,75 por onde o visitante entrava na rota a partir do passeio do LCC). Dois trechos novos (`Parking_Fence_Link_W` e `_S`) fecham a brecha entre a cerca leste e a do estacionamento, fora do caminho do crawler.
- **Quadro de direções da entrada** saiu do eixo do portão: no centro ele tapava o estágio central entre Y 45 e 60 para quem entra. Depois da mudança, 35 raios do olho do visitante no portão até o SLS só são interrompidos pelos braços de acesso do próprio lançador.

### Teste de circulação (Play)

| Trecho | Resultado |
|---|---|
| Recepção → Corredor 1 → museu → Corredor 2 → portão do VAB → frente do foguete | ok (portas automáticas abriram) |
| Vestiário: vestir o traje | ok |
| Escada lateral → deck → elevador → braço → Orion → sentar → sair na White Room → descer | ok |
| Elevador de serviço: piso ↔ nível 60 | ok |
| Saída de pedestres → LCC (porta leste) → Firing Room → porta norte → passeio → arquibancada | ok |
| Entrar na rota a partir do passeio | entrava pela brecha das cercas; corrigido depois |

- **SLS visível ao entrar:** sim (raios do portão acertam core stage, LAS e Orion; a base fica atrás do deck do lançador, como esperado).
- **Console:** nenhum erro dos scripts do mapa.
- **Contagens** (antes da Fase 13): VAB 644 peças (orçamento 2500), conjunto de transporte 337 (1500), museu 407 (2000), demais áreas 1363 (2000); 2793 no workspace (~8000). 82 luzes, 3 com sombra (por projeto, Fase 5), 1 ParticleEmitter.
- **Desempenho no Studio** (referência, não é teste de celular): física a 60 FPS no servidor e no cliente.

### Pendências

- **Teste em celular** (spec §13): não feito. Usar o emulador de dispositivos do Studio ou um aparelho real e registrar o modelo.
- **Porta da cabine inferior do elevador da tripulação:** quem chega na diagonal pelo patamar podia esbarrar na quina da folha aberta (X −24..−22, Z 255,8). Corrigido no gerador (Fase 9): faixa de piso azul-clara `Crew_Walkway_Guide` do patamar até o eixo da porta (X −20), com seta.
- **Elevador da tripulação disparou sem o painel** uma vez no playtest automatizado. O script só aciona a viagem pelo prompt do painel; provavelmente foi uma tecla E na janela do Studio. Vale observar num teste manual.
- **Passagem entre o trator de reboque e as caixas** a caminho da saída de pedestres tinha cerca de 3 studs. Corrigido no gerador (Fase 4): o trator foi recuado 10 studs (Z 282..287).
- **Acabamento de materiais e cores** não foi feito além do que cada fase já define.
- **Sistemas futuros** (fora do escopo da spec-v3 §15): abrir o portão dos fundos, mover o conjunto, estender plataformas e braços, sequência de lançamento, persistência e emblemas.


## spec-v3 §16 — conferência da preparação

O §16 (o que fica para depois) foi anexado à spec-v3. Conferência do que ele pede "nesta fase", contra o mapa atual:

| Item | Situação |
|---|---|
| §16.2 Critérios de conclusão do mapa | Atendidos: conjunto cabe no VAB, passa pelo portão com 7 de folga vertical e 13 de cada lado, SLS único, ML com o foguete, estruturas fixas e móveis separadas, plataforma comporta o conjunto, rota livre (varreduras com 0 interseções), pivôs definidos |
| §16.3 Referências de posição | `CrawlerRoute.Start_VAB`, `Destination_LaunchPad`, `Parking_Crawler`; pivôs do `TransportAssembly`, `CrawlerTransporter`, `MobileLauncher` e `SLSRocket` |
| §16.4 Objetos móveis separados dos fixos | Tudo que se move está em `TransportSystem.TransportAssembly`; o interior da Orion e o vestiário são fixos e usam referências relativas |
| §16.5 Espaço reservado | `SafetyZones` (envelope no VAB, rota, estacionamento, áreas de observação); cercas fechando a rota |
| §16.6 Sala de controle cenográfica | 32 estações identificadas na tela (POWER, LOX TANK, GUIDANCE, RANGE…), console principal reservado, sem botões funcionais |
| §16.7 Espaço vertical acima da plataforma | Coluna acima do SLS na plataforma (X ±12, Y 133..800) livre; a catenária dos para-raios passa a 13,4 studs do eixo do foguete. Ainda não há efeitos de lançamento; o único efeito do mapa (poeira do hangar) está em `Atmosphere_Objects` |
| §16.8 / §16.9 Persistência e emblemas | Nada implementado, como pedido |

## Skills roblox-skills (JoCoding) — ajustes de qualidade

O plugin `roblox-skills@roblox-skills` (v1.11.0, github.com/JoCoding-Inc/roblox-skills) foi instalado no Claude Code (escopo do usuário). Ele só contém skills, sem hooks nem servidores. Ajustes feitos a partir delas, dentro do escopo do §16.10 (qualidade, sem sistemas novos):

- **Fontes explícitas** (`roblox-ui-typography`, `roblox-engine-2026` §2): Gotham foi removida do Roblox e era trocada silenciosamente por Montserrat. Todas as placas e textos agora usam `FontFace` com Montserrat explícita, no mesmo peso de antes (Black → Heavy, Bold → Bold, Medium → Medium); os textos de telemetria seguem em `Code`. O visual não muda. Arquivos: `lib.luau`, Fases 2, 4, 8 (CrewClient) e 12.
- **Streaming** (`roblox-engine-2026` §3): a Fase 1 aplica `StreamingIntegrityMode = PauseOutsideLoadedArea` e `StreamOutBehavior = Opportunistic`. `ModelStreamingBehavior` também está na lista, em `pcall`, mas a propriedade não existe nesta versão do Studio e foi ignorada.
- **Aplicado e conferido:** reconstrução do zero (Fases 1–13) sem erros; 326 textos, 0 em Gotham (243 Montserrat, 83 Inconsolata = `Code`); trajeto do conjunto com 0 interseções.

### Iluminação (skill `roblox-feel-audio-vfx` §4) — opção B aplicada

Comparação medida em três pontos (VAB, museu, área externa), mesma câmera, com a página `docs/lighting/compare.html` (imagens e números). Escolhida a opção B:

- `Lighting.LightingStyle = Realistic` (antes `Soft`). Substitui a antiga instrução de ajustar `Technology = Future` à mão: essa propriedade não existe mais.
- Bloom 0,25 / 10 / 2 (antes 0,6 / 24 / 1,6).

Efeito medido (claridade perceptual): no VAB a área estourada caiu de 5,5% para 1,3% e a mediana subiu de 0,21 para 0,23; museu e área externa ficaram praticamente iguais. Aplicado na Fase 5 e reconstruído (Fases 3–13).

- **Correção de interiores:** a comparação inicial não incluiu interiores claros. Com `Realistic` e o `Ambient` antigo (58, 60, 70), a recepção caiu de claridade média 0,53 para 0,30 (cinzenta), porque o Realistic tira o preenchimento difuso do Soft. A Fase 5 agora usa `Ambient = (105, 108, 118)`: a recepção volta a 0,54 e o VAB mantém a área estourada em 1,2%. Medido com a iluminação assentada (15 s após cada mudança, como recomenda a `roblox-pitfalls`). O LCC continua escuro por projeto (paredes #2B313B e luz controlada).
- **Materiais (aplicado):** comparação medida em `docs/materials/compare.html` (5 pontos, luz assentada). O reboco escureceu e manchou a recepção (claridade 0,44 → 0,38) e não mudou museu nem LCC, então ficou só onde houve ganho: **reboco (`Plaster`) nas paredes e no teto do vestiário** (área estourada 46% → 36%, Fase 8) e **metal nas esferas de LH2 e LOX e no reservatório da torre de água** (estouro 3,5% → 1,7%, Fase 11). Recepção, corredores, museu e LCC continuam lisos.

### Teste por dispositivo (skill `rbx-device-simulator-lua`)

`StarterGui.ScreenOrientation = Sensor` (retrato e paisagem). A UI do jogo é criada em runtime; não há ScreenGui em `StarterGui`. Vista do visitante logo depois do portão frontal, olhando o SLS:

| Aparelho | Viewport | Resultado |
|---|---|---|
| Samsung Galaxy A06 (Android de entrada) | 705 × 338 | SLS inteiro visível; quadro de direções legível |
| iPhone 17 Pro | 750 × 381 | Igual ao A06, com mais margem |
| iPhone 17 Pro, retrato | 401 × 778 | Foguete preenche a tela; placas laterais saem do quadro |
| iPad Pro M5 (13 pol.) | 1375 × 1032 | Foguete com folga; o quadro de direções corta na lateral nesse enquadramento (a câmera segue o jogador) |
| Xbox One | 1919 × 1079 | Tudo legível |

Play no Galaxy A06: joystick e botão de pulo nos cantos sem cobrir nada importante; console sem erros. Achado: no vestiário (10 studs de largura, teto a 9,3) a câmera em terceira pessoa fica colada no personagem, e o prompt do armário mais próximo pode ficar fora do quadro estreito do celular, embora esteja ativo.

### Medição da cena (skill `rbx-scene-analysis`, Play, sem sombras)

| Ponto de vista | Triângulos | Draw calls |
|---|---|---|
| Entrada do VAB, olhando o SLS | 32.188 | 114 |
| VAB, vista ampla com as torres | 29.420 | 126 |
| Museu (planetário) | 31.044 | 215 |
| Área de observação → plataforma | 26.578 | 26 |
| Saída dos fundos → rota e plataforma | 30.480 | 44 |

Referência da skill: cerca de 800 mil triângulos e 600 draw calls para 60 FPS na maioria dos aparelhos. A geometria opaca fica em 18 a 30 draw calls; o resto são as telas de texto (SurfaceGui: 183 no museu, 89 a 101 no VAB). Os números refletem o que o cliente tinha carregado pelo streaming; o FPS real em celular continua dependendo de um aparelho.

- **Orientação:** o jogo aceita retrato (`Sensor`). Em retrato a visão lateral fica estreita para um mapa de exploração; `LandscapeSensor` é uma opção, a decidir.
- **Vestiário ampliado (feito):** a sala passou de 10 × 10,4 × 9,3 para 23,5 × 14 × 13 studs (X −60..−36,5, Z 244..258, Y 0..13), construída direto no piso (sem a translação antiga). Armários na parede do fundo, voltados para +X; entrada na face −Z (X −44..−38) e porta para o lançador na face +X (Z 248,5..253,5); duas luzes de teto. A placa do elevador de serviço (Fase 13) subiu para Y 14..17, acima do teto novo, e a faixa de piso termina na entrada. Conferido: 0 sobreposições da sala, trajeto do conjunto com 0 interseções e Play no Galaxy A06 com a câmera atrás do personagem e os 4 armários e a placa visíveis. O prompt do armário fica ativo e marcado como mostrado no cliente; o `screen_capture` não registra o painel do prompt, então a checagem visual dele fica para um teste à mão.

Recomendações das skills registradas para a próxima fase (não aplicadas agora, para não reconstruir sistemas sem necessidade, §16.10 regra 2):

- **Animar portas no cliente:** `AutomaticDoors` e `CrewAccess` fazem tween das folhas no servidor; a skill recomenda tween no cliente. Combina com a sincronização visual do §16.4.
- **Desempenho em celular:** o FPS lido do Studio em segundo plano não vale como medida (o Studio limita a 15 FPS fora de foco). Medir em aparelho Android de entrada por 10 a 15 minutos; o Studio tem ainda o *Performance Simulator* (Test > Device Simulator > Performance), que simula qualidade gráfica e memória, não CPU.
- **Alcance de desenho no celular:** em qualidade baixa, o Roblox garante ao menos 500 studs. O pad (Z 700) fica a cerca de 380 do portão dos fundos e a menos de 100 da área de observação.

## Revisão de layout: museu na ala leste, LCC no caminho principal

Pedido do usuário: trocar o museu de lugar com a central de controle e colocar o museu ao lado da recepção (à esquerda de quem sai para o VAB = leste). Decisões confirmadas: o LCC ocupa o lugar do museu; o museu continua o planetário atual (o salão da `museuspec.md` fica para uma etapa própria).

- **Fase 12 (LCC):** montado nas coordenadas antigas e transladado por (101, 0, −155) para X −49..6, Z 95..165, sem girar. A porta leste virou parede; entraram uma porta sul automática e uma passagem no fundo do saguão, ligando um corredor de fundo (antes vazio) ao saguão. O visitante atravessa em linha reta pelo eixo X = 0, da porta sul à porta norte; a Firing Room fica ao lado, pelo vão do saguão. Sensores das portas automáticas transladados junto. Marquises leste e norte removidas; placa "LAUNCH CONTROL CENTER" sobre a porta sul; placas internas reescritas.
- **Fase 12 (caminhos):** sem o LCC ao lado do VAB, a saída de pedestres liga direto ao passeio X −105..−97 até a área de observação (as praças do LCC saíram). Placas de direção atualizadas.
- **Fase 14 nova — `build/phase14_relocation.luau`:** move o museu por um giro de 90° + translação (centro (0, 130) → (90, 27,5)): `CapeCanaveralMuseum`, `Lighting_Objects.Museum` e a placa da entrada. Os planetas recebem `OrbitCenter` transformado e `OrbitAngle − 90`. Fecha os fundos do museu, abre a parede leste da recepção (vão Z 20,5..34,5, 12 de altura; faixa decorativa interrompida), cria o corredor do museu e as duas ligações do LCC com os corredores. Idempotente: cada peça movida recebe `MovedByPhase14`; peças recriadas pelas Fases 1–6 são movidas na execução seguinte.
- **Textos:** recepção ("Your mission…", "YOUR ROUTE", placa sobre a saída para o Corredor 1), Corredor 1 ("CONTROL CENTER AHEAD") e VAB (quadro de direções e placa da saída de pedestres).

Validação: reconstrução do zero (Fases 1–14) sem erros; segunda execução da Fase 14 sem mover nada; nada sobrou na área antiga do museu; só encaixes esperados nas sobreposições; planetas na órbita certa em volta de (90, 28) no cliente. Playtest: spawn → museu (ida e volta pela ala leste); recepção → Corredor 1 → porta sul do LCC → corredor de fundo → saguão → porta norte → Corredor 2 → VAB; saguão → Firing Room; saída de pedestres do VAB → área de observação. Console sem erros.

## Missão Friendship 7 (missaoUm.md) — Fase 15

Decisões do usuário:
- Textos em inglês.
- A missão começa sentado no assento do comandante (CDR); o piloto (PLT) também pode iniciar.
- Sons da Creator Store, com as falas de rádio só como legenda.

**Fase 15, `build/phase15_friendship7.luau`:** acrescenta `OrionInterior.Friendship7Mission` sem mexer na cápsula da Fase 8.
- Botões físicos no console: AUTOPILOT OFF, RETRY, CONFIRM, EJECT CAPSULE (com guarda), JETTISON RETROPACK e RETAIN RETROPACK.
- Folhas de procedimento presas aos dois painéis de chaves.
- Âncoras do prompt "Start mission" (tecla F, só aparece para quem está sentado no assento dele).
- Duas luzes de alerta.
- As três telas existentes (DU 1/2/3) viram os painéis de controle de atitude, rádio/terminal e reentrada.

**Scripts:** os fontes ficam em `build/mission/`, e a Fase 15 os baixa pelo mesmo servidor HTTP.
- `ReplicatedStorage.MissionSystem`:
  - Remotes: StartMission, MissionUpdate, MissionAction, SubmitCode e SubmitChoice.
  - `Config.Friendship7Config`, com todos os valores da §10.
  - Desvio da spec: `CompleteTask` virou `MissionAction`; quem conclui cada tarefa é sempre o servidor.
- `ServerScriptService.MissionSystem.Friendship7MissionService`, com os módulos Task1ControlService, Task2CommunicationService e Task3ReentryService.
  - Estado por jogador, ordem fixa das tarefas, validação de código e escolha, e limite de taxa.
  - Levantar, morrer ou sair do jogo encerra a missão.
  - Atributo `MissionActive` no jogador.
- `StarterPlayerScripts.MissionClient.MissionController`, com os módulos FirstPerson, CameraShake, GazeInteraction, PanelInteraction, Audio e PanelDisplays.
  - Telas, papel, janelas (Terra; plasma na reentrada) e HUD mínimo (faixa, legenda, mira, resumo) só no cliente do jogador.
- **Fase 8:** o CrewAccess ignora os prompts de quem tem `MissionActive`, então não dá para sair pela escotilha no meio da missão.
- **Áudio:** 8 sons do catálogo licenciado ProSoundEffects, ligados por Audio API com buses (ver `assets/LICENSES.md`).

**Playtest em Studio (1 jogador, CDR):**
- **Início:** o prompt iniciou a missão em primeira pessoa, com a câmera virada para o console.
- **Tarefa 1:**
  - O alerta apareceu e o AUTOPILOT OFF funcionou.
  - Os 4 pontos foram detectados pelo olhar em cerca de 0,77 s cada.
  - O combustível caiu de 100 % para 96,9 %.
  - A atitude foi estabilizada.
- **Tarefa 2:**
  - Estática, cronômetro e código legível no papel.
  - Código errado foi recusado (1/3).
  - O código certo em minúsculas e com espaços foi aceito.
  - A fala de rádio apareceu como legenda.
- **Tarefa 3:**
  - JETTISON gerou falha, e RETRY reiniciou a tarefa.
  - RETAIN levou à reentrada; segurando, o progresso subiu (0,40 em 4 s) e, solto, caiu (0,28 em 2 s).
  - A reentrada foi concluída e o resumo final apareceu.
- **Abortar:** levantar no meio da missão encerrou tudo. Câmera Classic de volta, telas originais restauradas e aviso na tela.
- **Console:** sem erros.

**Não testado:**
- Botões apertados com o mouse de verdade: o teste usou os remotes. O raio e o destaque dos botões dependem do mouse travado no centro.
- Toque no celular.
- Dois jogadores ao mesmo tempo, CDR e PLT (o estado é por jogador; use Test → Clients and Servers).
- O EJECT e as falhas por tempo e por combustível foram revisados no código, não exercitados no Play.

## Pontos que dependem de você

1. **Salvar o place.** O Place1 ainda não foi salvo; use File → Save to File ou Publish to Roblox.
2. **~~`Lighting.Technology = Future`~~** Resolvido: a propriedade foi substituída por `Lighting.LightingStyle`, que a Fase 5 define como `Realistic`.
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
