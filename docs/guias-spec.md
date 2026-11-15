# Rookie Rocket — Spec Roblox: NPCs Guias e Apresentação do Complexo

## 1. Visão geral da experiência

O jogador inicia sua jornada como um novo estagiário astronauta dentro do complexo espacial Rookie Rocket.

Ao entrar no jogo, o jogador aparece na área inicial, onde encontra o astronauta Marcos Pontes. Após uma conversa de boas-vindas, Marcos apresenta a experiência e o encaminha ao museu principal. Ao chegar, Marcos se despede e deixa o jogador explorar. Para avançar, o jogador precisa selecionar e conhecer pelo menos um item da exposição.

Em seguida, uma seta indica o caminho até a entrada do foguete. O trajeto pode passar pelo hangar e pela sala de controle. Ao se aproximar da entrada, o jogador ouve uma sirene e é chamado por Ana, que o guia até o topo do foguete. Lá, na primeira experiência, ele deve escolher a primeira missão disponível e selecionar o trade-off da viagem. Com as escolhas feitas, o foguete é lançado e a missão começa.

A experiência começa com Marcos Pontes, um NPC guia, que recebe o jogador e apresenta o complexo.

O jogador explora o museu e segue pelo complexo até o foguete.

A navegação será orientada por uma seta vermelha 3D que indica o próximo destino.

## 2. Personagens

### 2.1 Marcos Pontes — NPC guia

- Personagem R15.
- Uniforme de astronauta ou traje institucional azul.
- Fica próximo ao Spawn.
- Possui interação por ProximityPrompt.
- Apresenta o complexo e acompanha o jogador até o primeiro museu.
- Ao chegar ao museu, despede-se e deixa o jogador explorar sozinho.
- Não acompanha o jogador até o hangar ou sala de controle.

### 2.2 Ana — NPC engenheira de operações

- Personagem feminina R15.
- Uniforme de engenheira espacial branco e azul.
- Fica inicialmente fora da área de visão do jogador.
- Quando o jogador se aproxima da entrada do foguete, uma sirene toca e Ana chama sua atenção.
- Entra em cena para receber o jogador.
- Guia o jogador até o topo do foguete e a seleção da missão.

Os diálogos são fictícios. Marcos Pontes é representado como personagem ficcional, sem sugerir participação ou endosso oficial.

## 3. Mapa e pontos de interesse

### 3.1 Recepção / Spawn

- Local inicial do jogador.
- Marcos fica próximo ao ponto de nascimento.
- Ambiente com identidade visual de centro espacial.
- A seta vermelha aponta para Marcos.

### 3.2 Primeiro museu

- Área de exposição espacial.
- Painéis informativos e objetos históricos.
- Marcos acompanha o jogador até a entrada.
- Ao chegar, Marcos se despede.
- Após a interação com pelo menos um item, a seta indica o caminho para o foguete.

### 3.3 Hangar de foguetes

- Ambiente amplo com foguetes e equipamentos.
- O jogador explora o local sozinho.
- Grandes janelas permitem visualizar o ambiente externo.
- Se fizer parte do percurso, o hangar oferece pontos de navegação para a entrada do foguete.

### 3.4 Sala de controle

- Painéis de monitoramento.
- Telas com informações de missão.
- Consoles e estações de trabalho.
- Porta lateral de acesso ao complexo.
- Painel principal para informações de missão.

## 4. Sequência de apresentação

1. **Spawn:** a seta aponta para Marcos; o jogador interage com ele e recebe as boas-vindas.
2. **Caminho ao museu:** Marcos acompanha o jogador e se despede ao chegar.
3. **Museu:** o jogador explora e seleciona pelo menos um item. O progresso é validado antes de indicar o próximo destino.
4. **Foguete:** a seta guia o jogador até a entrada, por um percurso que pode incluir o hangar e a sala de controle. Ao se aproximar, uma sirene toca e Ana chama o jogador.
5. **Preparação:** Ana guia o jogador até o topo do foguete. Na primeira experiência, a primeira missão é obrigatória; depois, o jogador escolhe o trade-off.
6. **Lançamento:** com as escolhas concluídas, o foguete parte e a missão começa.

## 5. Sistema de diálogo no Roblox

Criar uma interface ScreenGui com:

- Nome do personagem.
- Texto do diálogo.
- Avatar ou retrato do NPC.
- Botão para continuar.
- Animação de aparecimento do texto.
- Opção de avançar os diálogos.

Os diálogos devem ser armazenados em ModuleScripts para facilitar alterações.

## 6. Sistema de navegação com seta vermelha

### 6.1 Comportamento da seta

Criar uma seta vermelha 3D visível para o jogador.

Características:

- Cor vermelha.
- Aparência destacada.
- Animação suave de flutuação.
- Orientação para o próximo destino.
- Atualização automática conforme o progresso.
- Não deve atravessar paredes.
- Deve funcionar individualmente para cada jogador.

### 6.2 Sequência de destinos

1. Spawn → Marcos.
2. Marcos → Museu.
3. Museu → Item da exposição, até que um seja selecionado.
4. Museu → Entrada do foguete, com waypoints pelo complexo.
5. Entrada do foguete → Ana → Topo do foguete e seleção da missão.

### 6.3 Implementação Roblox

Criar:

- `NavigationPoints`: pasta com os pontos de destino.
- `NavigationService`: serviço responsável pelo progresso e destinos.
- `NavigationUpdate`: RemoteEvent para atualizar o destino do jogador.
- Indicador visual no cliente para renderizar a seta.

A seta deve ser atualizada conforme os eventos de progresso.

Utilizar waypoints para orientar a navegação, evitando que a seta indique caminhos através de paredes.

### 6.4 Interface de objetivo

Exibir no HUD uma mensagem curta com o objetivo atual.

Exemplos de objetivos visíveis no jogo (em inglês):

- "Meet Marcos Pontes."
- "Explore the museum and select an exhibit."
- "Go to the rocket entrance."
- "Follow Ana to the top of the rocket."
- "Choose your mission and trade-off."

## 7. Movimento dos NPCs

Utilizar:

- Humanoid.
- Animator.
- PathfindingService.
- Humanoid:MoveTo().
- Animações de caminhada e parada.

Marcos acompanha o jogador somente durante o trajeto inicial até o museu.

Ana entra em cena perto da entrada do foguete e guia o jogador até o topo.

Os NPCs devem evitar obstáculos e não bloquear a passagem do jogador.

## 8. Cooperação e múltiplos jogadores

- Jogadores podem explorar o complexo juntos.
- Cada jogador possui seu próprio progresso de navegação.
- A seta deve ser individual.
- Diálogos compartilhados devem evitar duplicação de eventos.
- A chegada de um jogador não deve alterar indevidamente o objetivo de outro.
- O servidor controla o progresso de cada jogador.

## 9. Estrutura técnica sugerida

```text
Workspace
├── NPCs
│   ├── MarcosPontes
│   └── Ana
├── NavigationPoints
│   ├── Spawn_Marcos
│   ├── PrimeiroMuseu
│   ├── Hangar
│   ├── SalaControle
│   ├── Ana
│   └── PainelPrincipal
└── Map

ReplicatedStorage
├── Remotes
│   ├── NavigationUpdate
│   └── DialogueEvent
└── Config
    └── Dialogues

ServerScriptService
├── NPCService
├── NavigationService
└── ProgressService

StarterGui
└── DialogueGui

StarterPlayer
└── StarterPlayerScripts
    └── NavigationClient
```
