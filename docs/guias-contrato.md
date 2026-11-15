# Contrato dos guias (Marcos Pontes e Ana): peças × scripts

Spec: `docs/guias-spec.md`. Gerador: `build/phase22_guides.luau`. Scripts: `build/guide/` (Rojo).

## Hierarquia

```text
Workspace.NASAComplex.Guides            (Fase 22)
├── NPCs                                 Marcos ("MarcosPontes") e Ana, montados pelo NPCService em Play
└── NavigationPoints                     peças invisíveis 1×1×1 na altura do HumanoidRootPart (piso + 3)
    ├── Spawn_Marcos                     ao lado do SpawnLocation, virado para ele
    ├── PrimeiroMuseu                    entrada do planetário (ala leste), onde o Marcos se despede
    ├── PainelPrincipal                  ReturnPoint do quiosque Mission Briefing no LCC
    ├── SalaControle                     eixo X = 0 do LCC
    ├── Hangar                           logo depois do portão frontal do VAB
    ├── RocketEntrance                   diante do vestiário da tripulação (sirene + Ana)
    ├── Ana                              fundo do vestiário: onde ela entra em cena
    └── Ana_Route1..5                    vestiário → porta +X → pé da escada do lançador

ReplicatedStorage.GuideSystem
├── Config  (build/guide/shared)         Dialogues (falas, objetivos, aparência), Settings
└── Remotes (criados pelo GuideBoot)     NavigationUpdate, DialogueEvent, MissionSelect
ServerScriptService.GuideSystem          GuideBoot, ProgressService, NavigationService, NPCService, World, MarcosLook
StarterPlayerScripts.GuideClient         GuideClient, NavigationClient, DialogueGui, MissionSelect, GuideUI
ServerStorage.RookieBridge               criado pelo GerenciadorMissao: Embarcar(player, id, items), Perfil, EmMissao
ServerStorage.CrewSuit                   BindableFunction do CrewAccess: Invoke(player, true) veste o traje
ServerStorage.GuideParking               a Ana fica aqui enquanto está fora de cena
```

Pontos lidos ao vivo do `TransportSystem` (acompanham o lançador; não são criados pela Fase 22):
`Access_Stairs.Landing` (topo da escada), `Crew_Elevator.Cab_Lower` / `Cab_Upper` (PrimaryPart = piso; porta da cabine de baixo na face −Z local), `Arm_Deck` (braço de acesso; a Ana espera a 4 studs da ponta da torre).

Estrutura sugerida na spec × projeto: `Workspace.NPCs` e `Workspace.NavigationPoints` ficam em `NASAComplex.Guides` (regra da raiz única). `StarterGui.DialogueGui` é criado pelo cliente em `PlayerGui` (como as telas do museu e do Rookie Rocket).

## Etapas (servidor, por jogador)

`MeetMarcos → FollowMarcos → Museum → Rocket → FollowAna → Elevator → TalkAna → ChooseMission → InMission → Free`

- Museu: o primeiro ProximityPrompt com o atributo `ExhibitId` (ExhibitService) libera `Rocket`.
- `ChooseMission`: na primeira experiência (sem estrelas na missão 1) só o Mercury fica liberado. O mesmo painel escolhe missão, veste o traje e seleciona até dois equipamentos com peso/efeitos visíveis. Cliente envia `{ action = "Suit" }` ou `{ action = "Board", id = 1|2, items = { [equipmentKey] = true } }`. O servidor valida etapa, proximidade à Ana e desbloqueio; `CrewSuit` veste o traje e `RookieBridge.Embarcar(player, id, items)` valida traje, itens, 60 kg, vaga e manifesto compartilhado antes do teleporte. Resposta `MissionSelect { kind = "Feedback", text = ... }` mantém o painel aberto em erros. Excesso de peso falha ainda na plataforma. Ao embarcar, o painel fecha por `RookieMission`; não há preparação adicional na cápsula. Co-op entra na contagem de 12 s com o mesmo manifesto.
- Saindo da missão (`EmMissao` falso): `Free`. A Ana no topo continua abrindo a escolha.

## Regras

- NPCs no grupo de colisão `GuideNPC`, que não colide com `GuidePlayer` (personagens dos jogadores) nem consigo mesmo.
- Portas automáticas (`AutoDoor`) recebem `PathfindingModifier.PassThrough` para o caminho da seta passar por elas.
- NPCs presos por mais de 4 s num trecho são teleportados para o ponto seguinte (a apresentação nunca trava).
