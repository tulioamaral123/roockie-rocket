# SPEC.md — NASA Space Adventure: Complexo Espacial

**Plataforma:** Roblox Studio  
**Linguagem de programação:** Luau  
**Referência principal:** Kennedy Space Center (KSC), Flórida, Estados Unidos  
**Foguete principal:** Space Launch System (SLS) com cápsula Orion  
**Tipo de experiência:** Exploração, visitação educativa e atrações interativas  
**Status:** Especificação de arquitetura, ambiente e funcionalidades

---

# 1. Visão geral do projeto

## 1.1 Objetivo

Desenvolver no Roblox Studio um complexo espacial inspirado nas instalações da NASA, especialmente no Kennedy Space Center.

O ambiente deve proporcionar uma experiência imersiva, permitindo que os jogadores explorem instalações espaciais, conheçam equipamentos utilizados na preparação de foguetes, entrem em uma cápsula espacial e acompanhem uma demonstração de lançamento.

O projeto não deve ser apenas um mapa com um foguete em um galpão. A proposta é construir um complexo com diferentes atrações, ambientes conectados, equipamentos reconhecíveis e sistemas interativos.

A construção será adaptada às possibilidades do Roblox Studio, utilizando:

- Parts para estruturas arquitetônicas.
- MeshParts para modelos 3D detalhados.
- Models para organizar equipamentos e ambientes.
- Scripts em Luau para movimentação e interatividade.
- TweenService para animações.
- Interfaces para painéis, monitores e sistemas informativos.

## 1.2 Objetivos principais

- Criar uma base espacial com identidade visual inspirada na NASA.
- Construir um museu dedicado à história da exploração espacial.
- Desenvolver um hangar monumental inspirado no VAB.
- Construir o foguete SLS e a cápsula Orion.
- Representar equipamentos de montagem e manutenção.
- Criar uma sala de controle com monitores e painéis.
- Desenvolver um crawler-transportador funcional de forma simplificada.
- Construir uma plataforma externa de lançamento.
- Permitir que os jogadores entrem no foguete e explorem a cápsula Orion.
- Criar uma sequência interativa de preparação e demonstração de lançamento.

## 1.3 Direção do projeto

O complexo deve apresentar uma mistura de realismo arquitetônico e adaptação para gameplay.

Não é necessário reproduzir todo o Kennedy Space Center em escala real. O objetivo é preservar os elementos mais reconhecíveis, mantendo o mapa navegável, visualmente interessante e otimizado para o Roblox.

---

# 2. Organização geral do complexo

O complexo será dividido em três grandes atrações:

1. **Museu Cape Canaveral:** história da exploração espacial, foguetes históricos e equipamentos.
2. **Hangar VAB:** foguete SLS, cápsula Orion, equipamentos de montagem e manutenção.
3. **Área Externa de Lançamento:** crawler, torre de lançamento e plataforma.

Além dessas atrações, existirão áreas de conexão, recepção e controle.

## 2.1 Fluxo de visitação

O fluxo recomendado para o jogador é:

**Spawn → Recepção → Museu Cape Canaveral → Corredor de acesso → Hangar VAB → Sala de Controle → Pátio do Crawler → Plataforma de Lançamento.**

O jogador deve conseguir explorar os ambientes de maneira intuitiva, com sinalizações e elementos visuais que indiquem os próximos destinos.

## 2.2 Organização espacial

| Área | Função |
|---|---|
| Recepção | Entrada e orientação dos jogadores |
| Museu Cape Canaveral | História e exposições espaciais |
| Corredores | Conexão entre as atrações |
| Hangar VAB | Montagem e exposição do foguete |
| Sala de Controle | Monitoramento e sequência de lançamento |
| Pátio do Crawler | Exposição e movimentação do transportador |
| Plataforma de Lançamento | Demonstração de lançamento |

## 2.3 Prioridade visual

O foguete SLS deve ser o principal destaque do complexo.

Ao entrar no Hangar VAB, o jogador deverá enxergar imediatamente o foguete em posição vertical.

A primeira impressão precisa transmitir:

- Grande escala.
- Altura do hangar.
- Complexidade das estruturas industriais.
- Presença do foguete.
- Sensação de estar dentro de uma instalação espacial.

---

# 3. Atração 1 — Museu Cape Canaveral

## 3.1 Objetivo

Criar um museu espacial inspirado na história das instalações de lançamento de Cape Canaveral e da exploração espacial americana.

O museu será uma área educativa e de exploração, com exposições, modelos históricos, painéis e equipamentos.

**Importante:** o museu do jogo será uma atração temática inspirada na história espacial da região, não uma reprodução oficial e exata de um único edifício.

## 3.2 Elementos arquitetônicos

- Entrada principal ampla.
- Fachada com identificação do museu.
- Espaço interno de exposição.
- Vitrines e pedestais.
- Painéis informativos.
- Telas interativas.
- Iluminação de museu.
- Áreas de circulação.
- Espaços para fotografias.

## 3.3 Exposições

O museu poderá ser dividido em setores temáticos:

| Setor | Conteúdo |
|---|---|
| Primeiros foguetes | História dos primeiros programas espaciais |
| Corrida espacial | Missões e acontecimentos históricos |
| Programa Apollo | Foguetes Saturn V e missões lunares |
| Ônibus espacial | História dos Space Shuttles |
| Satélites | Satélites e equipamentos orbitais |
| Exploração robótica | Sondas e robôs espaciais |
| Programa Artemis | SLS, Orion e retorno à Lua |

## 3.4 Objetos de exposição

- Modelos de foguetes históricos.
- Modelos de cápsulas espaciais.
- Satélites.
- Sondas espaciais.
- Miniaturas de módulos lunares.
- Equipamentos de astronautas.
- Painéis de controle históricos.
- Fotografias e diagramas.

## 3.5 Interações

O jogador poderá:

- Aproximar-se de uma exposição.
- Abrir informações sobre o objeto.
- Visualizar imagens e diagramas.
- Interagir com telas.
- Navegar por uma linha do tempo.
- Desbloquear conquistas ao visitar os setores.

## 3.6 Direção visual

O museu deve ter aparência moderna e organizada, diferente do ambiente industrial do hangar.

Utilizar:

- Paredes claras.
- Iluminação direcionada.
- Vitrines.
- Pedestais.
- Painéis digitais.
- Elementos gráficos relacionados à exploração espacial.

---

# 4. Atração 2 — Hangar VAB

## 4.1 Referência

O hangar será inspirado no **Vehicle Assembly Building (VAB)** do Kennedy Space Center.

O VAB é utilizado para integração e preparação de veículos espaciais, incluindo o foguete SLS e a espaçonave Orion.

É a principal referência arquitetônica para o ambiente industrial do projeto.

## 4.2 Objetivo

Construir um hangar monumental que transmita a sensação de estar dentro de uma instalação de montagem de foguetes.

O espaço deve ser extremamente alto, amplo e possuir estruturas metálicas, plataformas, pontes rolantes, escadas e equipamentos.

## 4.3 Características arquitetônicas

- Paredes gigantescas.
- Pé-direito muito alto.
- Portões frontais de grandes dimensões.
- Estruturas metálicas aparentes.
- Vigas e travessas.
- Trilhos no teto.
- Pontes rolantes.
- Plataformas de manutenção.
- Passarelas elevadas.
- Escadas industriais.
- Elevadores.
- Tubulações.
- Cabos.
- Painéis técnicos.
- Iluminação industrial.

## 4.4 Composição do hangar

O ambiente deverá possuir:

1. Foguete SLS centralizado.
2. Mobile Launcher sob o foguete.
3. Plataformas de trabalho em diferentes alturas.
4. Pontes rolantes suspensas.
5. Portões gigantes.
6. Equipamentos de manutenção.
7. Área de circulação dos jogadores.
8. Área de observação.
9. Sinalização industrial.
10. Sistemas de iluminação.

## 4.5 Plataformas de manutenção

As plataformas serão distribuídas em diferentes alturas ao redor do foguete.

Requisitos:

- Criar entre 6 e 10 níveis visíveis como referência inicial.
- Utilizar estruturas metálicas.
- Adicionar grades de proteção.
- Criar escadas de acesso.
- Permitir que o jogador explore alguns níveis.
- Utilizar plataformas cenográficas para representar a complexidade do hangar.
- Algumas estruturas poderão executar animações de abertura e recolhimento.

## 4.6 Pontes rolantes e guindastes

Criar uma ou duas pontes rolantes suspensas no teto.

Características:

- Estrutura horizontal.
- Trilhos de movimentação.
- Mecanismo de elevação.
- Gancho ou bloco suspenso.
- Estrutura metálica industrial.

A movimentação poderá ser feita com TweenService.

Na primeira versão, o guindaste poderá realizar apenas movimentos demonstrativos, sem precisar transportar objetos pesados.

---

# 5. Foguete SLS e cápsula Orion

## 5.1 Foguete principal

O foguete principal será o **Space Launch System (SLS)**, utilizando como referência visual a configuração Block 1 com cápsula Orion.

O foguete deverá ser construído em posição vertical dentro do hangar.

## 5.2 Componentes obrigatórios

| Componente | Descrição |
|---|---|
| Orion | Cápsula tripulada localizada no topo |
| Launch Abort System | Torre de escape acima da cápsula |
| Adaptadores | Estruturas de conexão entre os módulos |
| Core Stage | Estágio central com tanque laranja e partes brancas |
| Solid Rocket Boosters | Dois propulsores laterais |
| RS-25 | Quatro motores na parte inferior do estágio central |
| Bocais | Estruturas escuras na base dos motores |

## 5.3 Requisitos visuais

- Dois boosters laterais.
- Estágio central de grande dimensão.
- Tanque laranja destacado.
- Cápsula Orion no topo.
- Torre de escape.
- Quatro motores RS-25.
- Bocais visíveis.
- Detalhes técnicos e marcações.
- Silhueta reconhecível mesmo à distância.

## 5.4 Modelagem

A modelagem poderá combinar:

- Parts para estruturas simples.
- MeshParts para superfícies complexas.
- Models para agrupar componentes.
- Texturas para marcações e detalhes.
- Decals para logotipos e identificações.

O foguete deve ser construído como um conjunto modular, facilitando ajustes individuais.

## 5.5 Interior da cápsula Orion

O jogador deverá conseguir entrar na cápsula e explorar seu interior.

### Elementos internos

- Assentos dos tripulantes.
- Painéis de controle.
- Telas.
- Indicadores.
- Janelas.
- Iluminação interna.
- Porta ou abertura de acesso.

### Funcionalidades

- Acesso por plataforma, escada ou elevador.
- Entrada controlada na cápsula.
- Assentos funcionais usando `Seat` ou `VehicleSeat`.
- Interação com painéis por `ProximityPrompt`.
- Possibilidade de sair da cápsula.
- Posicionamento seguro dos jogadores.

O interior poderá ser simplificado, priorizando a experiência de exploração.

---

# 6. Mobile Launcher

## 6.1 Objetivo

Representar a estrutura móvel de apoio utilizada para sustentar o foguete e permitir conexões com os sistemas terrestres.

O Mobile Launcher deve ficar visualmente conectado ao foguete dentro do hangar.

## 6.2 Elementos visuais

- Base retangular robusta.
- Torre metálica vertical.
- Passarelas.
- Escadas.
- Elevadores.
- Braços de acesso.
- Cabos.
- Tubulações.
- Caixas de equipamentos.
- Conectores.
- Plataformas de serviço.

## 6.3 Braços umbilicais

Representar os braços e conexões utilizados para fornecer serviços ao foguete e à espaçonave.

No jogo, eles poderão representar visualmente:

- Energia.
- Comunicação.
- Dados.
- Controle ambiental.
- Fluidos e gases de serviço.

## 6.4 Interações

- Botão para iniciar demonstração de recolhimento dos braços.
- Luzes de status.
- Painéis explicativos.
- Animações de desconexão.
- Acesso de visitação à estrutura.

---

# 7. Equipamentos do hangar

O hangar deverá possuir diversos equipamentos para transmitir a aparência de uma instalação real de montagem e manutenção.

| Equipamento | Representação |
|---|---|
| Ponte rolante | Viga suspensa com mecanismo de elevação |
| Plataformas | Estruturas metálicas elevadas |
| Escadas industriais | Acesso aos diferentes níveis |
| Elevadores | Plataformas ou cabines móveis |
| Tubulações | Linhas nas paredes e no teto |
| Cabos umbilicais | Conexões entre estruturas |
| Painéis elétricos | Caixas com indicadores luminosos |
| Carrinhos de manutenção | Pequenos veículos de apoio |
| Barreiras | Grades de segurança |
| Sistemas de ventilação | Dutos e grelhas |
| Câmeras | Equipamentos de monitoramento |
| Bancadas | Ferramentas e componentes |
| Caixas técnicas | Equipamentos de suporte |
| Iluminação | Luminárias industriais |

## 7.1 Regras de distribuição

- Não bloquear a visão inicial do SLS.
- Manter corredores de circulação livres.
- Posicionar equipamentos grandes próximos às paredes.
- Criar áreas de manutenção específicas.
- Utilizar modelos reutilizáveis para objetos repetidos.
- Evitar excesso de objetos pequenos sem função visual ou interativa.

---

# 8. Sala de controle

## 8.1 Objetivo

Criar uma sala inspirada nos centros de controle de lançamento da NASA.

O ambiente deverá transmitir a sensação de uma equipe monitorando e coordenando uma missão espacial.

## 8.2 Estrutura

- Sala ampla.
- Fileiras de consoles.
- Cadeiras.
- Monitores individuais.
- Telão principal.
- Painéis de telemetria fictícia.
- Mapas e diagramas.
- Equipamentos de comunicação.
- Iluminação controlada.

## 8.3 Interações

O jogador poderá sentar em uma estação e iniciar uma sequência demonstrativa.

Etapas:

1. Energia: nominal.
2. Comunicação: nominal.
3. Sistemas do foguete: nominal.
4. Plataforma: pronta.
5. Área de lançamento: liberada.
6. Contagem regressiva: iniciada.

As informações devem ser apresentadas como simulação educativa, não como reprodução dos procedimentos reais da NASA.

---

# 9. Atração 3 — Área externa de lançamento

## 9.1 Objetivo

Criar uma área externa que represente a etapa seguinte à montagem do foguete.

O espaço deverá incluir o crawler, a torre de lançamento, a plataforma e os equipamentos de suporte.

## 9.2 Elementos principais

- Pátio externo.
- Caminho de transporte.
- Crawler-Transporter.
- Mobile Launcher.
- Foguete SLS.
- Torre de serviço.
- Plataforma de lançamento.
- Tanques cenográficos.
- Tubulações.
- Trincheira de chamas.
- Defletor de chamas.
- Torre de água.
- Torres de proteção contra raios.
- Cercas e áreas de segurança.

---

# 10. Crawler-Transporter

## 10.1 Objetivo

Criar uma representação do enorme veículo utilizado para transportar o Mobile Launcher entre o VAB e a plataforma de lançamento.

**Importante:** o crawler transporta o Mobile Launcher, que sustenta o foguete. O crawler não transporta o foguete diretamente sobre sua própria estrutura.

## 10.2 Componentes visuais

- Plataforma retangular larga.
- Conjuntos de esteiras.
- Estrutura de sustentação.
- Cabine do operador.
- Escadas.
- Acessos laterais.
- Luzes de sinalização.
- Detalhes mecânicos e hidráulicos.

## 10.3 Funcionalidades

- Jogador pode aproximar-se do crawler.
- Acesso à cabine.
- Assento do operador.
- Botão para iniciar movimentação.
- Animação das esteiras.
- Deslocamento controlado pelo mapa.
- Transporte demonstrativo do Mobile Launcher.

A movimentação poderá utilizar TweenService ou um controlador próprio.

Não será necessário simular a física real do veículo.

---

# 11. Plataforma de lançamento

## 11.1 Objetivo

Representar a área onde o foguete é posicionado antes de uma demonstração de lançamento.

## 11.2 Elementos visuais

- Plataforma de concreto.
- Torre de serviço.
- Mobile Launcher.
- Foguete SLS.
- Trincheira de exaustão.
- Defletor de chamas.
- Torre de água.
- Torres de proteção contra raios.
- Tanques de armazenamento cenográficos.
- Tubulações.
- Cercas.
- Caminho do crawler.

## 11.3 Efeitos visuais

- Luzes de alerta.
- Sirenes.
- Vapor.
- Água.
- Fumaça.
- Partículas.
- Iluminação intensa na base do foguete.

Os efeitos serão demonstrativos e não precisarão reproduzir os fenômenos físicos reais de um lançamento.

---

# 12. Sistemas de gameplay

## 12.1 Exploração

O jogador deverá poder:

- Caminhar livremente pelas áreas liberadas.
- Entrar nos ambientes.
- Subir escadas.
- Utilizar elevadores.
- Acessar plataformas.
- Interagir com painéis.
- Visitar exposições.
- Entrar na cápsula Orion.
- Explorar o crawler.

## 12.2 Missão guiada

Uma sequência de visitação poderá orientar o jogador:

1. Receber briefing na recepção.
2. Visitar o Museu Cape Canaveral.
3. Conhecer a história dos foguetes.
4. Entrar no Hangar VAB.
5. Identificar componentes do SLS.
6. Visitar a cápsula Orion.
7. Explorar os equipamentos.
8. Visitar a sala de controle.
9. Iniciar a sequência demonstrativa.
10. Acompanhar o crawler.
11. Chegar à plataforma.
12. Assistir à demonstração de lançamento.

## 12.3 Recompensas

- Emblema de visitante.
- Emblema de exploração espacial.
- Título de cadete espacial.
- Conquistas por visitar atrações.
- Desbloqueio de áreas especiais.
- Registro de progresso da missão.

---

# 13. Tecnologias do Roblox Studio

| Elemento | Recurso |
|---|---|
| Paredes, pisos e estruturas | `Part` |
| Foguete detalhado | `MeshPart` / `Model` |
| Equipamentos | `Part` / `MeshPart` / `Model` |
| Portões automáticos | Parts + Scripts |
| Guindastes móveis | Models + `TweenService` |
| Monitores e painéis | `SurfaceGui` |
| Interfaces do jogador | `ScreenGui` |
| Elevadores | Models + Scripts |
| Luzes e fumaça | `Lighting` / `ParticleEmitter` |
| Esteiras do crawler | Models + Scripts |
| Assentos da Orion | `Seat` / `VehicleSeat` |
| Interações | `ProximityPrompt` |
| Sons e alarmes | `Sound` |
| Astronautas | Avatares / rigs |
| Animações | `Animator` |

## 13.1 Diretrizes técnicas

- Utilizar `Anchored = true` em estruturas estáticas.
- Organizar objetos em Models.
- Utilizar nomes consistentes.
- Criar componentes reutilizáveis.
- Utilizar ProximityPrompt para interações.
- Utilizar TweenService para movimentos controlados.
- Controlar interações importantes no servidor.
- Simplificar colisões de objetos decorativos.
- Evitar scripts independentes em cada peça.
- Separar lógica de gameplay e elementos visuais.

---

# 14. Estrutura sugerida no Explorer

```text
Workspace
└── NASAComplex
    ├── Reception
    ├── Corridors
    ├── CapeCanaveralMuseum
    │   ├── Architecture
    │   ├── Exhibits
    │   ├── InformationPanels
    │   └── InteractiveDisplays
    ├── VABHangar
    │   ├── Architecture
    │   ├── HighBay
    │   ├── WorkPlatforms
    │   ├── OverheadCranes
    │   ├── IndustrialEquipment
    │   └── SafetySystems
    ├── SLSAssembly
    │   ├── SLSRocket
    │   ├── OrionCapsule
    │   └── MobileLauncher
    ├── LaunchControlCenter
    │   ├── FiringRoom
    │   ├── Consoles
    │   └── MainScreens
    ├── CrawlerYard
    │   └── CrawlerTransporter
    └── LaunchPad
        ├── ServiceTower
        ├── FlameTrench
        ├── FlameDeflector
        ├── WaterTower
        ├── LightningTowers
        └── ServiceTanks

ReplicatedStorage
├── Remotes
└── SharedAssets

ServerScriptService
├── DoorController
├── MissionController
├── LaunchSequenceController
├── CrawlerController
├── ElevatorController
└── OrionInteriorController

StarterGui
├── MissionGui
└── InformationGui
```

---

# 15. Arquitetura dos scripts

| Script | Responsabilidade |
|---|---|
| DoorController | Abrir e fechar portas e portões |
| MissionController | Controlar progresso e etapas da visita |
| LaunchSequenceController | Controlar sequência demonstrativa |
| CrawlerController | Controlar movimento do crawler |
| ElevatorController | Controlar elevadores |
| OrionInteriorController | Gerenciar entrada e saída da cápsula |
| InformationPanelController | Exibir informações das exposições |

## 15.1 Regras de implementação

- Validar no servidor interações que alterem estados globais.
- Não confiar exclusivamente em dados enviados pelo cliente.
- Evitar que jogadores iniciem animações globais conflitantes.
- Prever cancelamento e retorno seguro de animações.
- Garantir que elevadores e portas não prendam personagens.
- Tratar desconexões de jogadores durante interações.
- Utilizar RemoteEvents apenas quando necessário.

---

# 16. Otimização e desempenho

O complexo terá estruturas grandes, muitos modelos e equipamentos.

Para manter o desempenho:

- Utilizar MeshParts para modelos complexos.
- Evitar excesso de peças pequenas.
- Reutilizar modelos.
- Limitar partículas simultâneas.
- Evitar luzes dinâmicas em todos os objetos.
- Simplificar colisões.
- Avaliar o uso de StreamingEnabled.
- Separar atrações em Models.
- Testar em computadores e dispositivos móveis.
- Manter corredores livres de obstáculos desnecessários.

---

# 17. Plano de desenvolvimento

## Fase 1 — Estrutura geral

- [ ] Criar terreno e layout do complexo.
- [ ] Construir recepção.
- [ ] Criar corredores.
- [ ] Definir posição das atrações.
- [ ] Construir estrutura externa do VAB.
- [ ] Construir interior básico do hangar.

## Fase 2 — Atrações

- [ ] Construir Museu Cape Canaveral.
- [ ] Criar exposições.
- [ ] Modelar foguete SLS.
- [ ] Modelar cápsula Orion.
- [ ] Criar Mobile Launcher.
- [ ] Posicionar o conjunto no hangar.
- [ ] Criar sala de controle.

## Fase 3 — Equipamentos

- [ ] Criar plataformas.
- [ ] Criar passarelas.
- [ ] Criar escadas.
- [ ] Criar elevadores.
- [ ] Criar pontes rolantes.
- [ ] Adicionar tubulações.
- [ ] Adicionar cabos.
- [ ] Adicionar equipamentos de manutenção.
- [ ] Adicionar sinalização e iluminação.

## Fase 4 — Interatividade

- [ ] Criar portões automáticos.
- [ ] Criar painéis informativos.
- [ ] Criar elevadores funcionais.
- [ ] Permitir entrada na Orion.
- [ ] Implementar assentos.
- [ ] Criar interações nos consoles.
- [ ] Implementar sequência demonstrativa.
- [ ] Implementar movimento do crawler.

## Fase 5 — Área externa

- [ ] Criar pátio.
- [ ] Modelar crawler.
- [ ] Criar rota de transporte.
- [ ] Construir plataforma.
- [ ] Construir torre.
- [ ] Adicionar tanques e tubulações.
- [ ] Criar trincheira e defletor de chamas.
- [ ] Adicionar efeitos visuais.
- [ ] Implementar demonstração de lançamento.

## Fase 6 — Testes e otimização

- [ ] Testar circulação.
- [ ] Testar colisões.
- [ ] Testar portas e elevadores.
- [ ] Testar entrada e saída da Orion.
- [ ] Testar multiplayer.
- [ ] Testar desempenho em celular.
- [ ] Corrigir problemas visuais e funcionais.

---

# 18. Critérios de aceitação

A primeira versão jogável será considerada pronta quando:

- O jogador conseguir entrar na base.
- As três atrações estiverem conectadas.
- O museu possuir exposições interativas.
- O jogador enxergar o SLS imediatamente ao entrar no VAB.
- O hangar transmitir sensação de escala monumental.
- O foguete possuir dois boosters, estágio central e Orion.
- O Mobile Launcher estiver representado.
- Existirem plataformas e equipamentos de manutenção.
- O jogador conseguir acessar pelo menos uma plataforma elevada.
- A sala de controle possuir telas e consoles.
- O jogador conseguir entrar na Orion, sentar e sair.
- O crawler possuir uma representação reconhecível e movimentação demonstrativa.
- A plataforma de lançamento possuir os elementos principais.
- As interações funcionarem em multiplayer.
- O mapa apresentar desempenho aceitável em computador e celular.

---

# 19. Restrições e observações

1. O projeto é uma experiência virtual e educativa, não uma simulação técnica de engenharia aeroespacial.
2. As dimensões podem ser adaptadas ao Roblox.
3. O VAB é a referência do hangar de montagem do SLS.
4. O Mobile Launcher é a plataforma móvel de apoio.
5. O crawler transporta o Mobile Launcher com o foguete sobre ele.
6. A sala de controle é uma instalação distinta do hangar na referência real.
7. Os painéis de telemetria do jogo podem apresentar dados fictícios.
8. A física real dos equipamentos não precisa ser simulada.
9. Modelos externos devem ser verificados quanto à qualidade e às permissões de uso.
10. A experiência não deve sugerir que é um produto oficial da NASA.

---

# 20. Referências visuais

Utilizar fotografias reais como referência para modelagem e composição dos ambientes.

## Hangar e foguete

- [NASA — Vehicle Assembly Building](https://www.nasa.gov/kennedy/partnerships/vehicleassemblybuilding/)
- [NASA — Space Launch System](https://www.nasa.gov/reference/space-launch-system/)
- [Rocket rollout — Artemis SLS e Saturn V, collectSPACE](https://www.collectspace.com/)

## Crawler

- [NASA — Crawler-Transporter](https://www.nasa.gov/humans-in-space/exploration-ground-systems/the-crawlers/)

## Sala de controle

- [NASA — Launch Control Center](https://www.nasa.gov/humans-in-space/exploration-ground-systems/rocco-a-petrone-launch-control-center/)

## Plataforma de lançamento

- [NASA — Launch Pad 39B](https://www.nasa.gov/humans-in-space/exploration-ground-systems/launch-pad-39b/)

## Visitação e museu

- [Kennedy Space Center Visitor Complex](https://www.kennedyspacecenter.com/)

---

# 21. Orientações para Claude

Esta especificação deve ser utilizada como referência principal para desenvolver o complexo no Roblox Studio.

### Forma de trabalho

1. Não tentar construir o complexo inteiro em uma única etapa.
2. Dividir a implementação por atração e por sistema.
3. Começar pelo layout e pela arquitetura.
4. Utilizar blocos simples para validar dimensões e circulação.
5. Validar a linha de visão do foguete antes de adicionar detalhes.
6. Criar os modelos de forma modular.
7. Organizar corretamente os objetos no Explorer.
8. Implementar scripts somente depois de definir os objetos que eles controlarão.
9. Testar cada sistema isoladamente.
10. Não alterar decisões arquitetônicas sem apresentar a justificativa.

### Prioridade de desenvolvimento

A ordem inicial recomendada é:

1. Layout geral do complexo.
2. Recepção e corredores.
3. Estrutura do Hangar VAB.
4. Foguete SLS e Mobile Launcher.
5. Plataformas e equipamentos.
6. Interior da Orion.
7. Museu Cape Canaveral.
8. Sala de controle.
9. Crawler.
10. Plataforma de lançamento.
11. Interações e sequência demonstrativa.
12. Otimização.

### Resultado esperado

Um complexo espacial no Roblox composto por:

- Museu Cape Canaveral.
- Hangar VAB monumental.
- Foguete SLS.
- Cápsula Orion explorável.
- Mobile Launcher.
- Equipamentos de montagem e manutenção.
- Sala de controle interativa.
- Crawler-Transporter.
- Plataforma externa de lançamento.

A experiência deve combinar exploração livre, informação educativa, interação com equipamentos e uma demonstração visual de lançamento espacial.