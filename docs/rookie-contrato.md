# Contrato Rookie Rocket: peças (geradores) × scripts

Spec: `docs/rookie-rocket-spec.md`. Este arquivo diz **o nome, a posição e o papel** de cada peça que os scripts usam. Gerador e script só conversam por estes nomes: não renomear sem atualizar aqui e nos dois lados.

Decisões do usuário (15/11/2026):
- A missão sentada da Fase 15 sai. A Fase 19 apaga as peças dela (`BuildPhase = 15`) e as pastas antigas de script (`ReplicatedStorage.MissionSystem`, `ServerScriptService.MissionSystem`, `StarterPlayerScripts.MissionClient`).
- Todos os textos visíveis em **inglês** (as falas da spec são traduzidas em `Missoes.luau`).
- Entrada pela Ana no braço de acesso: um único painel escolhe missão, veste o traje do CrewAccess e escolhe os equipamentos. O quiosque no LCC orienta até a Ana.
- O servidor exige `SuitOn == true` e `Character.SpaceSuit`, valida etapa/proximidade à Ana, desbloqueio da ISS, itens da missão, máximo de dois itens e 60 kg **antes** de teleportar. O botão continua clicável com 65/80 kg para explicar o excesso ainda na plataforma.
- O primeiro embarque fixa o manifesto compartilhado e inicia uma contagem de 12 s; até quatro tripulantes entram com o mesmo manifesto antes do último segundo. Não há seleção de itens dentro da nave. `Retry task` preserva itens; `Restart mission` devolve a equipe à posição de embarque e reabre o seletor; saída normal volta ao LCC.
- `RookieMission` (id no Player, somente servidor) preserva o traje durante a missão/EVA. Fora de missão, o CrewAccess tira o traje ao sair do VAB/lançador/braço (referência móvel) ou da cabine ampliada da Orion. Respawn sem `SpaceSuit` limpa `SuitOn`.
- Gravidade local: `CapsuleBounds` ativa VectorForce no personagem com gravidade efetiva de 35 studs/s² e impulso de pulo de 19 studs/s. Propriedades originais são restauradas fora da cápsula, em EVA, saída ou troca de personagem; Workspace.Gravity não muda.
- A seta do NavigationClient tem modo de missão local: observa alvos → prancheta → rádio → retropack; na ISS passa pelos acessos da cápsula/Cupola/Airlock e segue console, cabos/polias, escotilha, ferramentas e furo.

## Divisão

| Dono | Arquivos |
|---|---|
| Codex (`codex/rookie-mercury`) | `build/phase19_rookie_mercury.luau` (cápsula Mercury + quiosque no LCC + limpeza da Fase 15) |
| Codex (`codex/rookie-iss`) | `build/phase20_rookie_iss.luau` (módulo da ISS, Cupola, Airlock, exterior) |
| Claude (`claude/rookie-rocket`) | `build/rookie/**`, `build/phase21_rookie_systems.luau`, `default.project.json`, `build/run_in_studio.luau`, este arquivo |

Os geradores **não criam** ProximityPrompt, SurfaceGui de texto dinâmico, sons nem scripts: só peças com os nomes abaixo. Os scripts criam o resto.

## Regras comuns aos geradores

- `lib.builder(N)` e `B.clear(Map)` como as outras fases; raiz `Workspace.NASAComplex.RookieRocket` (Folder; criar se não existir, nunca apagar a pasta inteira, porque as duas fases dividem a raiz).
- Cada nave é um `Model` com `PrimaryPart = Origin` (peça invisível 1×1×1, `CanCollide/CanQuery/CanTouch = false`) e `ModelStreamingMode = Persistent` (os clientes precisam das peças mesmo longe do mapa).
- Tudo `Anchored`. Peças só de marcação: `Transparency = 1`, `CanCollide = false`, `CanQuery = false`, `CanTouch = false`.
- Coordenadas absolutas (as naves ficam paradas): **Mercury com `Origin` em (−3000, 1200, 0)**, **ISS com `Origin` em (3000, 1200, 0)**. O topo do piso interno fica no Y do `Origin`. Eixo da nave ao longo de Z.
- Interior para 1 a 4 jogadores R15 andando livremente: passagens com pelo menos 6 de largura e 8 de altura; pé-direito ≥ 12; nenhum degrau > 1.
- Interior fechado (o jogador não pode cair para fora). Janelas: `Material = Glass`, `Transparency` 0,3 a 0,5, `CanCollide = true`.
- Iluminação interna: luzes (`PointLight`/`SpotLight`) dentro de peças cujo nome começa com `CabinLight`, todas numa pasta `Lights`. Brilho de base agradável com o céu noturno (os clientes trocam o céu por estrelas durante a missão).
- Fontes por `FontFace` (Montserrat). Textos fixos (placas) em inglês.
- Qualidade visual no nível do resto do mapa (painéis, cabos, rebites, consoles com detalhes), sem exagerar nas peças: alvo de até ~1.500 peças por nave.

## Mercury (`NASAComplex.RookieRocket.Mercury`, Fase 19)

Cápsula cônica de 16 lados inspirada na Orion da Fase 8: Ø32 no piso, Ø24 no teto, 15 de altura. Três estações distribuídas no perímetro: painel frontal/periscópio, navegação e conjunto rádio/retropack. Sem assentos obrigatórios; os quatro jogadores circulam no centro.

| Caminho | Tipo | Papel |
|---|---|---|
| `Origin` | Part | PrimaryPart, em (−3000, 1200, 0) |
| `Spawns/Spawn1..4` | Part marcação | onde a equipe aparece ao embarcar (perto da `PrepConsole`), virada para +Z |
| `Bounds` | Part marcação | caixa 32 × 15 × 32 centrada em Origin + (0, 7.5, 0); valida interior caminhável |
| `CapsuleBounds` | Part marcação | mesmo volume; ativa gravidade local da cápsula |
| `Stations/PrepConsole` | Part visível (console) | manifesto confirmado; prompt desativado, sem segunda preparação |
| `Stations/Exit` | Part visível (escotilha) | sair da nave e voltar ao LCC |
| `Windows/*` | Parts Glass | cinco painéis de vidro com ~6.36 × 7.24: Window3/4/5 frontais (+Z), Window8 à esquerda e Window0 à direita; vãos reais no casco cônico |
| `Exterior/AlignPoints/Point1..4` | Part Ball Neon vermelha, diâmetro 4 | Task 1: alvos fora da nave, 40 a 70 studs das janelas. Point1 e Point2 visíveis pela janela frontal; Point3 pela lateral esquerda; Point4 pela lateral direita. Cada um visível de um ponto do piso onde um jogador de pé consegue mirar (linha livre entre a altura dos olhos, piso + 5, e o ponto). `CanCollide = false`, `CanQuery = false` |
| `Exterior/PlasmaEmitters/Emitter1..N` (N ≥ 4) | Part marcação com `ParticleEmitter` (`Enabled = false`, laranja/vermelho, brilhante) | Task 3: plasma de reentrada passando pelas janelas (o cliente liga) |
| `Stations/NavTable` | Model | Estação 2 (janela lateral + mesa de navegação) |
| `Stations/NavTable/Clipboard` | Part (prancheta ~2,5 × 0,1 × 3,5, deitada, face `Top` para cima) | Task 2: SurfaceGui na face Top e prompt "Read flight code"; leitura validada no servidor mostra o código e muda a seta para o rádio |
| `Stations/Radio` | Model | Estação 3a: console de rádio |
| `Stations/Radio/Keypad` | Part visível | Task 2: teclado do rádio (prompt "Use radio") |
| `Stations/Radio/EjectButton` | Part visível vermelha (Neon) | Task 2: botão "EJECT CAPSULE" piscando ao lado do teclado |
| `Stations/Reentry` | Model | Estação 3b: console do retropack, longe o bastante da NavTable para exigir caminhada (≥ 20 studs) |
| `Stations/Reentry/EjectButton` | Part vermelha | Task 3: "EJECT CAPSULE" |
| `Stations/Reentry/RetainButtonA`, `RetainButtonB` | Parts verdes, 6 a 10 studs uma da outra | Task 3: "HOLD RETROPACK" (redundantes, para o co-op); separados por 7 studs |
| `Seats/Seat_1..4/Seat` | Seat (CanTouch = false), atributo `SeatNumber` | 4 assentos da tripulação (2 × 2, voltados para +Z); o GerenciadorMissao cria o prompt "Take seat" |
| `Lights/CabinLight*` | Parts com luz | o cliente pulsa em vermelho (Task 1) e em laranja (Task 3) |

Botões e teclados ficam a 3–4 de altura do piso, de frente para onde o jogador está.

### Quiosque no LCC (também Fase 19)

`NASAComplex.RookieRocket.Kiosk` (Model) dentro do saguão do `NASAComplex.LaunchControlCenter`, posicionado a partir da posição real do LCC no place (a Fase 14 pode tê-lo movido: ler o pivot/bounding box do modelo, não usar coordenadas da Fase 12). Não pode bloquear o eixo de passagem do visitante (porta sul → porta norte) nem as validações do `CLAUDE.md`.

| Caminho | Papel |
|---|---|
| `Kiosk/BoardMercury` | Part visível (pedestal/tela): prompt orienta até a Ana, sem embarcar |
| `Kiosk/BoardISS` | Part visível: prompt orienta até a Ana, sem embarcar |
| `Kiosk/Screen` | Part (tela ~8 × 4.5); o script desenha o status na face `Front` |
| `Kiosk/ReturnPoint` | Part marcação no piso livre ao lado do quiosque: para onde a equipe volta |
| placa fixa "MISSION BRIEFING" | texto do gerador |

### Limpeza da missão antiga (início da Fase 19)

`lib.builder(15)` + `B.clear(Map)` para apagar as peças da Fase 15, e `Destroy()` em `ReplicatedStorage.MissionSystem`, `ServerScriptService.MissionSystem` e `StarterPlayer.StarterPlayerScripts.MissionClient`, se existirem.

## ISS (`NASAComplex.RookieRocket.ISS`, Fase 20)

Cápsula de chegada de 16 lados (Ø32/24, H15), centro local (−42, 0, −12), ligada por túnel ao módulo habitável. Durante os 12 s de chegada o colar anima o encaixe; a cabine permanece fixa para preservar a física da tripulação. A escotilha abre quando começa a Task 1, e as três tasks seguem no módulo/EVA.

Módulo habitável ligado à **Cupola** (7 janelas: 1 central circular/octogonal + 6 trapezoidais voltadas para a Terra), uma **Airlock** e um **módulo adjacente** separado por uma escotilha. Terra grande, iluminada, abaixo da estação.

| Caminho | Tipo | Papel |
|---|---|---|
| `Origin` | Part | PrimaryPart, em (3000, 1200, 0) |
| `Spawns/Spawn1..4`, `Bounds` | como na Mercury | spawns no piso da cápsula, X local −48/−44/−40/−36, Z −12; Bounds centro (−9, 6, −2), tamanho 98 × 24 × 110 cobre cápsula + interiores |
| `CapsuleBounds` | Part marcação | centro (−42, 7.5, −12), tamanho 32 × 15 × 32; gravidade local |
| `Capsule/DockingHatch` | Part visível | escotilha em (−25, 6, −12), tamanho 0.6 × 12 × 20; fechada durante chegada, invisível/sem colisão nas tasks |
| `Capsule/DockingCollar` | Part visível, atributo CFrame `DockedPose` | colar animado no encaixe, independente da cabine |
| `Capsule/Tunnel*` | Parts | túnel fechado até o vão na parede oeste do habitat; passagem no mesmo nível do piso |
| `Stations/PrepConsole`, `Stations/Exit` | como na Mercury | |
| `Cupola/Windows/*` | Parts Glass | as 7 janelas |
| `Stations/CanadarmConsole` | Part visível (console com 2 joysticks), dentro da Cupola ou junto a ela | Task 1: prompt "Use Canadarm console" |
| `Exterior/Unity` | Model | módulo Unity, visível pelas janelas da Cupola |
| `Exterior/Zarya` | Model com `PrimaryPart` | módulo Zarya **desalinhado** no build (≈ 12° de giro e ≈ 6 studs de afastamento do encaixe) |
| `Exterior/ZaryaDockedPose` | Part marcação | CFrame final do pivot da Zarya quando acoplada (o script anima de `Zarya:GetPivot()` até aqui) |
| `Exterior/SolarPanels`, `Exterior/Canadarm` | Models decorativos | painéis solares e braço robótico visíveis |
| `Exterior/Earth` | Part Ball grande (até 2048), `CanCollide/CanQuery/CanTouch = false` | Terra iluminada abaixo da estação (azul, com nuvens; textura/decal opcional) |
| `Airlock/InnerHatch` | Part visível (escotilha interna) | Task 2: prompt "Start EVA" |
| `Airlock/EvaStart` | Part marcação, fora da estação | onde o jogador aparece ao sair em EVA |
| `Airlock/EvaReturn` | Part marcação, dentro | onde o jogador volta ao fim da EVA |
| `Exterior/EvaBounds` | Part marcação (caixa) | área do cabo de segurança: o jogador em EVA não sai dela |
| `Exterior/Cables/Cable1`, `Cable2` | Part (cabo ~0,6 × 0,6 × 6) | Task 2: cabos soltos, dentro de `EvaBounds`, `CanCollide = false` |
| `Exterior/Pulleys/Pulley1`, `Pulley2` | Part (círculo verde, Neon) | polias; cada uma a 20–35 studs do cabo correspondente, dentro de `EvaBounds` |
| `Exterior/TetherAnchor` | Part marcação junto à Airlock | ponto de onde sai o cabo de segurança visual |
| `Stations/AdjacentHatch/Door` | Part visível (porta da escotilha), aberta no build | Task 3: o script move a `Door` para `Stations/AdjacentHatch/DoorClosedPose` |
| `Stations/AdjacentHatch/DoorClosedPose` | Part marcação | CFrame da porta fechada |
| `Stations/AdjacentHatch/Prompt` | Part marcação junto à escotilha | âncora do prompt "Close hatch" |
| `Stations/Toolbox` | Part visível (caixa de ferramentas) | Task 3: prompt "Take epoxy gauze" |
| `LeakSpots/Spot1..4` | Part marcação nas paredes, em pontos diferentes do módulo, com `ParticleEmitter` (`Enabled = false`, partículas finas e claras indo **para dentro** da parede) | Task 3: o servidor sorteia um furo |
| `Lights/CabinLight*` | Parts com luz | o cliente acende o vermelho de emergência |

A parte exterior (EVA) precisa ser navegável flutuando: sem peças que prendam o jogador, cabos e polias acessíveis a partir de `EvaStart`.

## Scripts (`build/rookie/`)

Rojo (`default.project.json`):
- `ReplicatedStorage.RookieRocket` (`RojoManaged`): `Config/Missoes` (todas as constantes e textos), `Remotes` (`SelecionarEquipamento`, `IniciarLancamento`, `AcaoTask`, `ReiniciarTaskOuMissao`, `SincronizarEstado`).
- `ServerScriptService.RookieRocket`: `GerenciadorMissao.server` + módulos das tasks + `DataStoreManager`.
- `StarterPlayerScripts.RookieClient`: navegação/EVA/efeitos, UI de preparação, HUD/feedback/álbum/créditos.

Sem Rojo, a Fase 21 instala os mesmos scripts pelo servidor HTTP (como a Fase 18).
