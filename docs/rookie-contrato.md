# Contrato Rookie Rocket: peças (geradores) × scripts

Spec: `docs/rookie-rocket-spec.md`. Este arquivo diz **o nome, a posição e o papel** de cada peça que os scripts usam. Gerador e script só conversam por estes nomes: não renomear sem atualizar aqui e nos dois lados.

Decisões do usuário (15/11/2026):
- A missão sentada da Fase 15 sai. A Fase 19 apaga as peças dela (`BuildPhase = 15`) e as pastas antigas de script (`ReplicatedStorage.MissionSystem`, `ServerScriptService.MissionSystem`, `StarterPlayerScripts.MissionClient`).
- Todos os textos visíveis em **inglês** (as falas da spec são traduzidas em `Missoes.luau`).
- A entrada fica num quiosque **Mission Briefing** no Launch Control Center; a equipe é teleportada para a nave, construída longe do mapa.

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

Interior ampliado (sugestão: ~36 de largura × 14 de altura × 48 de comprimento) com 3 estações físicas separadas, para os jogadores precisarem andar entre elas.

| Caminho | Tipo | Papel |
|---|---|---|
| `Origin` | Part | PrimaryPart, em (−3000, 1200, 0) |
| `Spawns/Spawn1..4` | Part marcação | onde a equipe aparece ao embarcar (perto da `PrepConsole`), virada para +Z |
| `Bounds` | Part marcação | caixa que cobre todo o interior caminhável (o servidor testa "jogador está a bordo") |
| `Stations/PrepConsole` | Part visível (console) | preparação da missão (o script põe o prompt) |
| `Stations/Exit` | Part visível (escotilha) | sair da nave e voltar ao LCC |
| `Windows/*` | Parts Glass | janelas panorâmicas: uma frontal grande (≥ 16 × 8) e pelo menos duas laterais (≥ 10 × 6) |
| `Exterior/AlignPoints/Point1..4` | Part Ball Neon vermelha, diâmetro 4 | Task 1: alvos fora da nave, 40 a 70 studs das janelas. Point1 e Point2 visíveis pela janela frontal; Point3 pela lateral esquerda; Point4 pela lateral direita. Cada um visível de um ponto do piso onde um jogador de pé consegue mirar (linha livre entre a altura dos olhos, piso + 5, e o ponto). `CanCollide = false`, `CanQuery = false` |
| `Exterior/PlasmaEmitters/Emitter1..N` (N ≥ 4) | Part marcação com `ParticleEmitter` (`Enabled = false`, laranja/vermelho, brilhante) | Task 3: plasma de reentrada passando pelas janelas (o cliente liga) |
| `Stations/NavTable` | Model | Estação 2 (janela lateral + mesa de navegação) |
| `Stations/NavTable/Clipboard` | Part (prancheta ~2,5 × 0,1 × 3,5, deitada, face `Top` para cima) | Task 2: o script desenha o código numa SurfaceGui na face Top |
| `Stations/Radio` | Model | Estação 3a: console de rádio |
| `Stations/Radio/Keypad` | Part visível | Task 2: teclado do rádio (prompt "Use radio") |
| `Stations/Radio/EjectButton` | Part visível vermelha (Neon) | Task 2: botão "EJECT CAPSULE" piscando ao lado do teclado |
| `Stations/Reentry` | Model | Estação 3b: console do retropack, longe o bastante da NavTable para exigir caminhada (≥ 20 studs) |
| `Stations/Reentry/EjectButton` | Part vermelha | Task 3: "EJECT CAPSULE" |
| `Stations/Reentry/RetainButtonA`, `RetainButtonB` | Parts verdes, 6 a 10 studs uma da outra | Task 3: "HOLD RETROPACK" (redundantes, para o co-op) |
| `Lights/CabinLight*` | Parts com luz | o cliente pulsa em vermelho (Task 1) e em laranja (Task 3) |

Botões e teclados ficam a 3–4 de altura do piso, de frente para onde o jogador está.

### Quiosque no LCC (também Fase 19)

`NASAComplex.RookieRocket.Kiosk` (Model) dentro do saguão do `NASAComplex.LaunchControlCenter`, posicionado a partir da posição real do LCC no place (a Fase 14 pode tê-lo movido: ler o pivot/bounding box do modelo, não usar coordenadas da Fase 12). Não pode bloquear o eixo de passagem do visitante (porta sul → porta norte) nem as validações do `CLAUDE.md`.

| Caminho | Papel |
|---|---|
| `Kiosk/BoardMercury` | Part visível (pedestal/tela): prompt "Board Mercury mission" |
| `Kiosk/BoardISS` | Part visível: prompt "Board ISS mission" |
| `Kiosk/Screen` | Part (tela ~8 × 4.5); o script desenha o status na face `Front` |
| `Kiosk/ReturnPoint` | Part marcação no piso livre ao lado do quiosque: para onde a equipe volta |
| placa fixa "MISSION BRIEFING" | texto do gerador |

### Limpeza da missão antiga (início da Fase 19)

`lib.builder(15)` + `B.clear(Map)` para apagar as peças da Fase 15, e `Destroy()` em `ReplicatedStorage.MissionSystem`, `ServerScriptService.MissionSystem` e `StarterPlayer.StarterPlayerScripts.MissionClient`, se existirem.

## ISS (`NASAComplex.RookieRocket.ISS`, Fase 20)

Módulo habitável ligado à **Cupola** (7 janelas: 1 central circular/octogonal + 6 trapezoidais voltadas para a Terra), uma **Airlock** e um **módulo adjacente** separado por uma escotilha. Terra grande, iluminada, abaixo da estação.

| Caminho | Tipo | Papel |
|---|---|---|
| `Origin` | Part | PrimaryPart, em (3000, 1200, 0) |
| `Spawns/Spawn1..4`, `Bounds` | como na Mercury | `Bounds` cobre módulo + Cupola + Airlock + módulo adjacente (interior) |
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

## Scripts (Claude, `build/rookie/`)

Rojo (`default.project.json`):
- `ReplicatedStorage.RookieRocket` (`RojoManaged`): `Config/Missoes` (todas as constantes e textos), `Remotes` (`SelecionarEquipamento`, `IniciarLancamento`, `AcaoTask`, `ReiniciarTaskOuMissao`, `SincronizarEstado`).
- `ServerScriptService.RookieRocket`: `GerenciadorMissao.server` + módulos das tasks + `DataStoreManager`.
- `StarterPlayerScripts.RookieClient`: navegação/EVA/efeitos, UI de preparação, HUD/feedback/álbum/créditos.

Sem Rojo, a Fase 21 instala os mesmos scripts pelo servidor HTTP (como a Fase 18).
