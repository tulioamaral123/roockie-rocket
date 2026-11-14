# NASA SPACE ADVENTURE
# SPEC — MISSÃO: FRIENDSHIP 7 — SOBREVIVÊNCIA EM ÓRBITA

**Versão:** 1.0  
**Plataforma:** Roblox Studio  
**Linguagem:** Luau  
**Tipo:** Missão narrativa interativa em primeira pessoa  
**Referência histórica:** Mercury-Atlas 6 — Friendship 7  
**Astronauta histórico:** John H. Glenn Jr.  
**Escopo:** Implementação das três tarefas dentro da cápsula espacial.

---

# 1. OBJETIVO DA MISSÃO

Criar uma missão espacial educativa e interativa baseada nos acontecimentos da missão Friendship 7, realizada por John Glenn em 20 de fevereiro de 1962.

O jogador estará dentro da cápsula espacial e enfrentará três situações críticas:

1. Falha no sistema automático de controle.
2. Perda temporária de comunicação com a Terra.
3. Alerta incorreto sobre a integridade do escudo térmico.

Cada situação deverá exigir uma habilidade diferente:

| Tarefa | Habilidade desenvolvida |
|---|---|
| Colapso do piloto automático | Coordenação e controle manual |
| Blackout de comunicação | Interpretação de informações e cumprimento de procedimentos |
| Alarme do escudo térmico | Tomada de decisão sob pressão |

A missão deverá transmitir a sensação de que o jogador está realmente pilotando uma cápsula espacial em situação de emergência.

## 1.1. Direção visual

A experiência deve seguir uma estética inspirada nas cápsulas Mercury:

- Painéis analógicos.
- Botões físicos.
- Indicadores circulares.
- Luzes de alerta.
- Instrumentos mecânicos.
- Pequenos monitores.
- Rádio com interferência.
- Iluminação vermelha e laranja durante emergências.
- Sons de equipamentos, alarmes e comunicação.

A cápsula Orion já existente no projeto poderá receber esses elementos como uma representação educativa inspirada na Mercury.

**Importante:** a experiência é uma simulação histórica dentro de uma cápsula estilizada do jogo. Não apresentar os painéis como uma reprodução literal da cabine da Mercury ou da Orion.

---

# 2. FLUXO GERAL DA MISSÃO

A missão será dividida em três etapas consecutivas.

```text
INÍCIO DA MISSÃO
       |
       v
ENTRADA NA CÁPSULA
       |
       v
TAREFA 1 — FALHA NO PILOTO AUTOMÁTICO
       |
       v
RECUPERAÇÃO DO CONTROLE
       |
       v
TAREFA 2 — BLACKOUT DE COMUNICAÇÃO
       |
       v
RESTAURAÇÃO DA COMUNICAÇÃO
       |
       v
TAREFA 3 — ALERTA DO ESCUDO TÉRMICO
       |
       v
DECISÃO SOBRE O RETROPAQUETE
       |
       v
SIMULAÇÃO DA REENTRADA
       |
       v
MISSÃO CONCLUÍDA
```

## 2.1. Regras gerais

- A missão deve acontecer dentro da cápsula.
- O jogador deve utilizar a visão em primeira pessoa.
- Os objetos interativos devem fazer parte do cenário 3D.
- A câmera deve ser posicionada de forma que o painel fique visível.
- O jogador não poderá sair da cápsula durante as tarefas.
- As três tarefas deverão ser executadas na ordem definida.
- Cada tarefa terá condições específicas de sucesso e falha.
- A missão deverá possuir feedback visual e sonoro para todas as interações.

## 2.2. Duração

A duração da missão deve ser configurável.

Valores iniciais sugeridos:

| Etapa | Duração estimada |
|---|---:|
| Tarefa 1 | 30–60 segundos |
| Tarefa 2 | 30–60 segundos |
| Tarefa 3 | 20–40 segundos |
| Transições | 10–20 segundos |
| Total | 90–180 segundos |

Os quatro minutos e vinte segundos históricos de blackout serão representados por uma versão comprimida no gameplay. O tempo de jogo não precisa reproduzir a duração histórica real.

---

# 3. TAREFA 1 — O COLAPSO DO PILOTO AUTOMÁTICO

## 3.1. Contexto histórico

Durante a missão Friendship 7, John Glenn enfrentou problemas no sistema automático de controle de atitude da cápsula.

Ele precisou assumir o controle manual e manter a orientação da nave.

A tarefa deverá transmitir essa situação ao jogador.

Referência:
https://www.nasa.gov/history/SP-4219/Chapter7.html

## 3.2. Objetivo

O jogador deverá recuperar a estabilidade da cápsula por meio de movimentos direcionados da câmera.

Diferentemente de um minigame convencional baseado apenas nas setas do teclado, esta versão utilizará interação por observação e direcionamento da visão.

## 3.3. Cenário e elementos visuais

A câmera deverá estar posicionada dentro da cápsula, apontada para o painel de controle.

Elementos necessários:

- Mostrador circular de atitude.
- Cruz indicadora central.
- Alvo de referência.
- Botão vermelho de desligamento do piloto automático.
- Indicador de combustível de controle.
- Luzes de emergência.
- Pequenos indicadores analógicos.

### Layout conceitual

```text
+-------------------------------------------+
|          FALHA NO SISTEMA AUTOMÁTICO      |
|                                           |
|                                           |
|   COMBUSTÍVEL RCS        INDICADOR         |
|   +-------------+       +-----------+     |
|   |             |       |           |     |
|   |    75%      |       |     +     |     |
|   |             |       |           |     |
|   +-------------+       +-----------+     |
|                                           |
|          [DESLIGAR AUTOPILOTO]             |
|                                           |
+-------------------------------------------+
```

## 3.4. Sequência de funcionamento

### Fase A — Falha

1. O jogador recebe o aviso: "FALHA NO SISTEMA AUTOMÁTICO".
2. O painel começa a piscar em laranja.
3. A câmera apresenta uma pequena vibração.
4. O indicador circular começa a desviar para a direita.
5. Um alerta sonoro é reproduzido.

### Fase B — Desativação

O jogador deverá interagir com o botão físico:

**DESLIGAR AUTOPILOTO**

Ao clicar:

- O botão deverá afundar visualmente.
- A iluminação do botão deverá mudar.
- O indicador de controle manual deverá ser ativado.
- O mostrador deverá começar a girar ou oscilar.

### Fase C — Recuperação manual

O jogador precisará encontrar pontos específicos no mostrador.

A tela deverá apresentar de três a quatro pontos de referência.

O jogador deverá direcionar a câmera para cada ponto e mantê-la sobre ele por um pequeno intervalo.

Regras:

- Cada ponto deverá possuir uma área de detecção.
- A câmera deverá estar apontada para o ponto.
- O jogador deverá manter o foco por aproximadamente 0,7 segundo.
- Um ponto confirmado muda de cor.
- O próximo ponto será ativado após a confirmação do anterior.

Exemplo de sequência:

1. Ponto superior direito.
2. Ponto inferior direito.
3. Ponto inferior esquerdo.
4. Ponto central.

Os pontos devem aparecer em posições variáveis dentro de limites definidos, evitando que a tarefa seja sempre idêntica.

### Fase D — Resultado

Quando todos os pontos forem confirmados:

- A cruz retorna ao centro.
- O indicador circular para de oscilar.
- A vibração da câmera diminui.
- O alerta laranja é desligado.
- O combustível deixa de diminuir.
- O sistema automático volta a funcionar.

Mensagem:

**CONTROLE RECUPERADO — SISTEMA ESTABILIZADO**

## 3.5. Combustível de controle

O painel deverá possuir uma barra lateral chamada:

**COMBUSTÍVEL DE CONTROLE**

A barra representa a reserva fictícia de controle manual da simulação.

Regras:

- Valor inicial: 100%.
- O combustível diminui enquanto o jogador executa correções.
- Correções excessivas ou movimentos errados consomem mais combustível.
- O jogador deverá controlar a frequência das correções.
- Ao chegar a 0%, a tarefa falha.

A implementação deverá permitir ajustar o consumo por dificuldade.

Não exigir que o jogador fique pressionando teclas continuamente. A mecânica principal desta versão é a detecção dos pontos pela câmera.

## 3.6. Condições de falha

- Combustível chega a 0%.
- Jogador não consegue concluir a sequência dentro do tempo máximo configurado.

Mensagem:

**FALHA NO CONTROLE DE ATITUDE**

A missão deverá oferecer reinício da tarefa.

---

# 4. TAREFA 2 — O BLACKOUT DE COMUNICAÇÃO

## 4.1. Contexto histórico

Durante a reentrada de Friendship 7, a cápsula atravessou um período de perda temporária de comunicação por causa da ionização ao redor da nave.

O blackout histórico durou aproximadamente quatro minutos e vinte segundos.

Referência:
https://www.nasa.gov/history/60-years-ago-john-glenn-the-first-american-to-orbit-the-earth-aboard-friendship-7/

## 4.2. Objetivo

O jogador deverá recuperar uma informação necessária para executar um procedimento de segurança.

A solução estará escrita em um papel físico localizado ao lado do painel.

O jogador deverá observar o papel, identificar o código e digitá-lo no campo correspondente.

## 4.3. Elementos visuais

- Painel de rádio.
- Alto-falante.
- Tela com estática.
- Cronômetro.
- Papel com código.
- Campo de entrada.
- Botão de confirmação.
- Botão vermelho de emergência indevida.

### Layout conceitual

```text
+-------------------------------------------+
|          BLACKOUT DE REENTRADA            |
|                                           |
|       PERDA DE CONTATO COM A TERRA        |
|                                           |
|              03:59                        |
|                                           |
|          [ TELA COM ESTÁTICA ]            |
|                                           |
|                                           |
|   CÓDIGO DE PROCEDIMENTO:                 |
|                                           |
|       [____________________]              |
|                                           |
|           [CONFIRMAR]                     |
|                                           |
|             [EJETAR]                      |
+-------------------------------------------+
```

## 4.4. Sequência de funcionamento

### Fase A — Perda de comunicação

1. O rádio começa a apresentar chiado.
2. A tela recebe um efeito de estática em preto e branco.
3. A iluminação do painel muda.
4. O jogador recebe o aviso:

**BLACKOUT DE REENTRADA — CONTATO COM A TERRA INTERROMPIDO**

5. O cronômetro começa a contar.

O tempo deverá ser configurável para a duração da experiência.

### Fase B — Encontrar o código

Um papel físico deverá estar posicionado próximo ao painel.

O papel deverá conter:

- Título: PROCEDIMENTO DE EMERGÊNCIA.
- Código de identificação.
- Instrução para inserir o código no rádio.

O código poderá ser gerado aleatoriamente a cada tentativa.

Exemplo:

```text
PROCEDIMENTO DE EMERGÊNCIA

CÓDIGO DE RESTAURAÇÃO:

M7-42-K9

DIGITE O CÓDIGO NO TERMINAL.
```

O código deverá ser armazenado no servidor e replicado para a interface apenas quando necessário para a validação.

O jogador deverá poder observar o papel e retornar sua visão para o painel.

### Fase C — Inserção do código

O painel deverá possuir um campo de texto.

Regras:

- O jogador digita o código encontrado no papel.
- A validação ignora espaços extras e diferenças entre letras maiúsculas e minúsculas.
- Código incorreto gera mensagem de erro.
- Código correto inicia a restauração da comunicação.

Mensagem de erro:

**CÓDIGO INVÁLIDO — VERIFIQUE O DOCUMENTO**

Mensagem de sucesso:

**PROCEDIMENTO ACEITO — RESTAURANDO COMUNICAÇÃO**

### Fase D — Recuperação

Ao inserir o código correto:

- A estática começa a desaparecer.
- O volume do chiado diminui.
- O rádio volta a apresentar sinal.
- O cronômetro para.
- A comunicação com a Terra é restaurada.

Mensagem de rádio:

**"Friendship 7, we read you. Welcome back."**

Esta frase é uma fala dramatizada para a experiência, não uma transcrição literal do contato histórico.

## 4.5. Botão de emergência indevida

O painel deverá conter um botão vermelho:

**EJETAR CÁPSULA**

A interação com esse botão deverá provocar falha imediata na tarefa.

Mensagem:

**PROCEDIMENTO INCORRETO — NÃO ABANDONE A CÁPSULA DURANTE A REENTRADA.**

A tela deverá explicar que o jogador interrompeu o procedimento de segurança.

A missão poderá ser reiniciada.

## 4.6. Condições de sucesso

- Jogador encontra o documento.
- Insere o código correto.
- Confirma o procedimento.
- Comunicação é restaurada.

## 4.7. Condições de falha

- Jogador aciona o botão de ejeção.
- Cronômetro termina sem que o código correto seja informado.

A dificuldade poderá permitir uma quantidade configurável de tentativas incorretas.

---

# 5. TAREFA 3 — O ALARME FALSO DO ESCUDO TÉRMICO

## 5.1. Contexto histórico

Durante a missão Friendship 7, um sinal indicou que o sistema de aterrissagem havia sido acionado, levantando a preocupação de que o escudo térmico pudesse estar solto.

O sinal posteriormente foi identificado como incorreto.

A equipe de controle orientou John Glenn a manter o pacote de retrofoguetes preso à cápsula durante a reentrada, como medida de segurança para ajudar a manter o escudo térmico no lugar.

Referências:

https://www.nasa.gov/mission/mercury-atlas-6-friendship-7/

https://www.archives.gov/exhibits/featured-documents/friendship-7-transcript

## 5.2. Objetivo

O jogador deverá interpretar um alerta de possível falha no escudo térmico e escolher o procedimento correto.

A decisão deverá acontecer sob pressão, com cronômetro.

## 5.3. Elementos visuais

- Painel de reentrada.
- Alerta vermelho.
- Indicador de integridade do escudo.
- Cronômetro de 10 segundos.
- Botão vermelho: DESCARTAR RETROPAQUETE.
- Botão verde: MANTER RETROPAQUETE.
- Indicador de temperatura.
- Efeito visual de aquecimento da cápsula.

### Layout conceitual

```text
+-------------------------------------------+
|        ALERTA — REENTRADA                 |
|                                           |
|    PERIGO: SENSOR DO ESCUDO INSTÁVEL      |
|                                           |
|              00:10                        |
|                                           |
|         INTEGRIDADE DO ESCUDO             |
|                 42%                       |
|                                           |
|  [DESCARTAR]       [MANTER]               |
|  [RETROPAQUETE]    [RETROPAQUETE]         |
|                                           |
+-------------------------------------------+
```

## 5.4. Sequência de funcionamento

### Fase A — Alerta

1. A cápsula começa a tremer.
2. O painel apresenta um alerta vermelho.
3. A temperatura indicada começa a subir.
4. O cronômetro de 10 segundos é iniciado.
5. O jogador recebe uma mensagem de voz:

"Friendship 7, temos uma indicação de possível problema no escudo térmico. Mantenha o pacote de retrofoguetes preso durante a reentrada."

A mensagem é uma adaptação dramatizada do contexto histórico.

### Fase B — Decisão

O jogador terá duas opções:

**Opção 1 — DESCARTAR RETROPAQUETE**

- Botão vermelho.
- Representa a decisão incorreta.
- A cápsula perde a proteção adicional prevista no procedimento da simulação.
- A tarefa termina imediatamente em falha.

Mensagem:

**FALHA CRÍTICA — RETROPAQUETE DESCARTADO**

Explicação:

O sinal do sensor era incorreto. A decisão de manter o retro pacote era necessária para proteger o escudo térmico.

**Opção 2 — MANTER RETROPAQUETE**

- Botão verde.
- Representa a decisão correta.
- O jogador avança para a fase de reentrada.

### Fase C — Resistência durante a reentrada

Após escolher a opção correta:

1. A cápsula começa a atravessar a atmosfera.
2. O exterior da janela fica vermelho e alaranjado.
3. O painel começa a tremer.
4. Sons de vibração e atrito são reproduzidos.
5. A temperatura visual aumenta.
6. O jogador deverá manter pressionado o botão:

**MANTER RETROPAQUETE**

A interação deverá durar 10 segundos.

O botão deverá possuir um indicador visual de progresso.

Exemplo:

```text
REENTRADA ATMOSFÉRICA

MANTENHA O PROCEDIMENTO

[====================          ]

TEMPO RESTANTE: 04
```

Regras:

- O jogador precisa manter o botão pressionado.
- Se soltar, o progresso poderá diminuir gradualmente.
- O tempo de resistência deverá ser configurável.
- Ao completar os 10 segundos, o procedimento será considerado concluído.

### Fase D — Resultado

Após concluir a resistência:

- A vibração diminui.
- A coloração vermelha desaparece gradualmente.
- O indicador de integridade se estabiliza.
- O painel deixa de emitir alertas.
- O jogador recebe a confirmação de reentrada segura.

Mensagem:

**ESCUDO TÉRMICO ESTÁVEL — REENTRADA CONCLUÍDA**

---

# 6. CONCLUSÃO DA MISSÃO

Após completar as três tarefas, apresentar uma sequência final.

Elementos:

- Imagem da Terra pela janela.
- Redução dos alarmes.
- Som de rádio normalizado.
- Mensagem de conclusão.

Mensagem principal:

**MISSÃO CONCLUÍDA**

"Você conseguiu recuperar o controle da cápsula, seguir os procedimentos durante a perda de comunicação e tomar a decisão correta durante a reentrada."

Exibir três resultados:

| Indicador | Resultado |
|---|---|
| Controle manual | Recuperado |
| Comunicação | Restaurada |
| Escudo térmico | Preservado |

A missão deverá finalizar com uma tela de resumo.

Não implementar recompensas, emblemas ou persistência nesta etapa. Esses sistemas poderão ser adicionados posteriormente.

---

# 7. ARQUITETURA TÉCNICA NO ROBLOX STUDIO

## 7.1. Organização sugerida

Criar a estrutura abaixo sem substituir os sistemas já existentes no projeto.

```text
ReplicatedStorage
└── MissionSystem
    ├── Remotes
    │   ├── StartMission
    │   ├── MissionUpdate
    │   ├── SubmitCode
    │   ├── SubmitChoice
    │   └── CompleteTask
    │
    └── Config
        └── Friendship7Config

ServerScriptService
└── MissionSystem
    ├── Friendship7MissionService
    ├── Task1ControlService
    ├── Task2CommunicationService
    └── Task3ReentryService

StarterPlayer
└── StarterPlayerScripts
    └── MissionClient
        ├── MissionController
        ├── FirstPersonController
        ├── CameraShakeController
        ├── GazeInteractionController
        ├── PanelInteractionController
        └── AudioController

Workspace
└── NASAComplex
    └── Capsule
        └── Friendship7Mission
            ├── MissionStart
            ├── ControlPanel
            │   ├── AttitudeIndicator
            │   ├── AutopilotButton
            │   ├── FuelGauge
            │   └── GazeTargets
            │
            ├── CommunicationPanel
            │   ├── RadioScreen
            │   ├── CodeInput
            │   ├── ConfirmButton
            │   ├── EjectButton
            │   └── PaperDocument
            │
            ├── ReentryPanel
            │   ├── ThermalAlert
            │   ├── CountdownDisplay
            │   ├── JettisonButton
            │   └── RetainButton
            │
            └── MissionEffects
                ├── WarningLights
                ├── AudioSources
                └── WindowEffects
```

Os nomes poderão ser adaptados à organização real do Explorer. Não criar uma segunda cápsula nem duplicar os objetos já existentes.

## 7.2. Responsabilidades dos serviços

**Friendship7MissionService**

- Controlar o estado geral da missão.
- Iniciar e finalizar a experiência.
- Controlar a ordem das tarefas.
- Impedir que uma tarefa seja iniciada fora de sequência.

**Task1ControlService**

- Controlar o piloto automático.
- Gerenciar os pontos de observação.
- Controlar o consumo de combustível.
- Validar a recuperação da atitude.

**Task2CommunicationService**

- Gerar o código de procedimento.
- Validar o código enviado.
- Controlar o cronômetro.
- Restaurar a comunicação.

**Task3ReentryService**

- Controlar o alerta térmico.
- Validar a decisão.
- Controlar o tempo de resistência.
- Finalizar a reentrada.

**GazeInteractionController**

- Detectar a direção da câmera.
- Identificar os pontos observados.
- Verificar o tempo de permanência sobre cada ponto.
- Enviar as interações ao servidor.

**CameraShakeController**

- Aplicar vibrações durante as emergências.
- Controlar intensidade e duração.
- Reduzir gradualmente a vibração quando a tarefa for concluída.

**AudioController**

- Controlar alertas sonoros.
- Reproduzir chiado de rádio.
- Controlar sons de emergência.
- Reproduzir mensagens de voz.

---

# 8. REGRAS DE SEGURANÇA E MULTIPLAYER

A missão deverá ser individual por jogador.

- Cada jogador terá seu próprio estado de missão.
- Um jogador não poderá concluir uma tarefa em nome de outro.
- A validação de códigos deverá ocorrer no servidor.
- A escolha da tarefa 3 deverá ser validada no servidor.
- O cliente poderá controlar efeitos visuais e sonoros locais.
- O servidor deverá validar a ordem das tarefas e seus resultados.
- Não confiar exclusivamente em valores enviados pelo cliente.

A missão deverá bloquear interações externas enquanto estiver ativa, sem modificar permanentemente os controles do jogador.

Ao sair da cápsula ou abandonar a missão:

- Encerrar os efeitos.
- Restaurar a câmera.
- Restaurar os controles.
- Limpar interfaces temporárias.
- Liberar os objetos de interação.

---

# 9. DIRETRIZES DE IMPLEMENTAÇÃO VISUAL

## 9.1. Painéis físicos

Os botões devem ser objetos 3D reais.

Utilizar:

- ProximityPrompt ou ClickDetector quando apropriado.
- Clickable Parts ou raycasting para interações direcionadas.
- TweenService para animações.
- SurfaceGui para informações nos painéis.
- BillboardGui somente quando houver necessidade de orientação espacial.

Não transformar todos os painéis em uma única ScreenGui que cubra a tela.

## 9.2. Primeira pessoa

A experiência deverá utilizar primeira pessoa durante a missão.

A câmera deverá:

- Permanecer dentro da cápsula.
- Permitir observar os painéis.
- Possuir movimento limitado quando necessário.
- Ser controlada de maneira consistente em teclado e mouse.
- Ser restaurada ao terminar a missão.

Na Tarefa 1, o jogador deverá conseguir direcionar sua visão para os pontos indicados.

Na Tarefa 2, deverá conseguir olhar para o papel e depois para o terminal.

Na Tarefa 3, deverá conseguir observar e interagir com os botões físicos.

## 9.3. Efeitos

Utilizar efeitos com moderação:

- ColorCorrectionEffect.
- BlurEffect.
- Camera shake.
- PointLight.
- SurfaceLight.
- Partículas de aquecimento.
- Sons de vibração.
- Estática visual.

Evitar efeitos que prejudiquem a leitura dos instrumentos ou causem desconforto prolongado.

---

# 10. CONFIGURAÇÕES AJUSTÁVEIS

Todos os valores de gameplay deverão ficar centralizados em Friendship7Config.

Parâmetros iniciais:

| Parâmetro | Valor |
|---|---:|
| Pontos da tarefa 1 | 4 |
| Tempo de foco por ponto | 0,7 s |
| Combustível inicial | 100% |
| Tempo máximo tarefa 1 | 60 s |
| Duração do blackout no jogo | 45 s |
| Código de procedimento | Gerado por tentativa |
| Tempo para tarefa 3 | 10 s |
| Tempo de resistência | 10 s |
| Penalidade por soltar botão | Configurável |
| Reinício após falha | Permitido |

Os tempos são parâmetros de gameplay e não representam necessariamente os tempos históricos reais.

---

# 11. CRITÉRIOS DE ACEITAÇÃO

A implementação somente será considerada concluída quando:

## Tarefa 1

- [ ] O alerta automático aparece.
- [ ] A câmera treme.
- [ ] O botão de desligar funciona.
- [ ] O mostrador apresenta os pontos de observação.
- [ ] A câmera detecta os pontos corretamente.
- [ ] O jogador consegue completar os quatro pontos.
- [ ] O combustível diminui conforme as regras.
- [ ] A atitude é estabilizada ao concluir.

## Tarefa 2

- [ ] O rádio apresenta estática.
- [ ] O áudio de interferência funciona.
- [ ] O cronômetro aparece.
- [ ] O papel com o código fica visível.
- [ ] O jogador consegue inserir o código.
- [ ] Código incorreto é rejeitado.
- [ ] Código correto restaura a comunicação.
- [ ] O botão de ejeção provoca falha.

## Tarefa 3

- [ ] O alerta térmico aparece.
- [ ] O cronômetro de 10 segundos funciona.
- [ ] Os dois botões funcionam.
- [ ] Descartar o retro pacote provoca falha.
- [ ] Manter o retro pacote permite continuar.
- [ ] O jogador precisa manter o botão durante a resistência.
- [ ] A reentrada é concluída com sucesso.

## Missão completa

- [ ] As tarefas acontecem na ordem correta.
- [ ] A missão pode ser reiniciada.
- [ ] A câmera retorna ao estado normal.
- [ ] Os efeitos sonoros e visuais são encerrados.
- [ ] O jogador recebe a tela de conclusão.
- [ ] A experiência funciona em servidor com mais de um jogador.

---

# 12. ORDEM DE DESENVOLVIMENTO

Implementar na seguinte ordem:

1. Inspecionar a cápsula já construída no Roblox Studio.
2. Identificar os painéis e os espaços disponíveis.
3. Criar os objetos físicos que faltam.
4. Implementar o sistema geral de missão.
5. Implementar a primeira tarefa e testar a detecção por câmera.
6. Implementar a segunda tarefa e testar a leitura do documento.
7. Implementar a terceira tarefa e testar as decisões.
8. Adicionar efeitos visuais e sonoros.
9. Integrar as três tarefas.
10. Executar testes multiplayer e de reinício.

Não construir os três desafios simultaneamente antes de validar a interação básica de cada um.

---

# 13. RESTRIÇÕES PARA O DESENVOLVIMENTO

- Não reconstruir o VAB.
- Não alterar as dimensões do museu.
- Não modificar a arquitetura do SLS.
- Não substituir a cápsula existente.
- Não criar um novo sistema de missões global sem necessidade.
- Não implementar DataStore ou BadgeService nesta fase.
- Não implementar transporte do crawler ou lançamento do foguete como parte desta missão.
- Não utilizar interfaces genéricas que descaracterizem os painéis físicos.
- Não implementar movimentos de câmera que tirem o jogador da cabine.
- Não permitir que o cliente determine sozinho o resultado das tarefas.

O desenvolvedor deverá primeiro inspecionar o projeto atual e adaptar a missão à estrutura existente.

**Prioridade máxima:** garantir que o jogador consiga realizar as três tarefas de maneira intuitiva, visualmente convincente e sem sair da cápsula.

---

# 14. REFERÊNCIAS HISTÓRICAS

1. NASA — The Project Mercury Astronauts  
   https://www.nasa.gov/history/SP-4219/Chapter7.html

2. NASA — 60 Years Ago: John Glenn and Friendship 7  
   https://www.nasa.gov/history/60-years-ago-john-glenn-the-first-american-to-orbit-the-earth-aboard-friendship-7/

3. NASA — Mercury-Atlas 6: Friendship 7  
   https://www.nasa.gov/mission/mercury-atlas-6-friendship-7/

4. National Archives — John Glenn's Official Communication with the Command Center  
   https://www.archives.gov/milestone-documents/john-glenns-official-communication-with-the-command-center

5. National Archives — Friendship 7 Reentry Transcript  
   https://www.archives.gov/exhibits/featured-documents/friendship-7-transcript/reentry-transcript.html

**Fim da especificação — versão 1.0**