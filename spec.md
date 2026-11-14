# NASA Space Adventure --- Especificação do Projeto Roblox

> Documento de referência para planejamento e desenvolvimento no Roblox
> Studio.\
> **Objetivo:** descrever a arquitetura, o fluxo de exploração, as
> dimensões, os ambientes, os elementos visuais e os requisitos técnicos
> do mapa.\
> **Importante:** este documento especifica o cenário. Não solicita a
> implementação de foguetes funcionais, sistemas de lançamento, tycoon
> ou mecânicas de construção.\
> **Revisão 2 (14/11/2026):** incorpora o que foi acrescentado durante
> a implementação no Roblox Studio: medidas adotadas, orientação do
> spawn, sistemas interativos implementados e o acesso da tripulação à
> cápsula Orion (§7.8). As decisões arquitetônicas originais foram
> mantidas. O acesso da tripulação é exploratório: não há lançamento,
> combustível, missões nem progressão.

------------------------------------------------------------------------

## 1. Visão geral

**Nome de trabalho:** NASA Space Adventure\
**Plataforma:** Roblox\
**Estilo:** experiência de exploração espacial, educativa e imersiva\
**Referência visual:** instalações da NASA, museus espaciais e o Vehicle
Assembly Building (VAB)\
**Foguete em destaque:** NASA Space Launch System (SLS), representado em
escala visual adaptada ao Roblox\
**Museu:** espaço imersivo com cúpula de planetário

O jogador deve nascer dentro de uma base inspirada na NASA e percorrer
uma sequência linear de ambientes até chegar a um hangar monumental. O
percurso deve criar uma progressão visual: instalação institucional,
corredor de transição, museu espacial, corredor industrial e, por fim, o
hangar com o foguete SLS.

### 1.1 Experiência principal do jogador

1.  O jogador aparece na recepção da base NASA.
2.  Enxerga a saída e atravessa o primeiro corredor.
3.  Entra no museu imersivo Space Adventure.
4.  Explora as exposições sob a grande cúpula.
5.  Atravessa um segundo corredor, agora com estética industrial.
6.  Entra no hangar por uma abertura frontal.
7.  Ao cruzar a entrada do hangar, vê imediatamente o foguete SLS
    centralizado e em destaque.
8.  Opcionalmente, veste um traje no vestiário da tripulação, sobe pelo
    elevador da torre de serviço, atravessa o braço de acesso e entra na
    cápsula Orion para se sentar em um dos quatro assentos (§7.8).

### 1.2 Decisões já definidas

-   A base será inspirada em uma instalação da NASA.
-   O foguete principal será o NASA SLS.
-   O foguete ficará dentro de um hangar.
-   A entrada do hangar será frontal.
-   O foguete deverá estar visível imediatamente ao entrar.
-   O museu terá atmosfera imersiva e teto em cúpula, como um
    planetário.
-   O projeto atual é de especificação do mapa; a implementação pode ser
    feita em uma etapa posterior.
-   O jogador nasce virado para **−Z**, de frente para o painel
    institucional (§3.3).
-   O jogador pode vestir um traje e entrar na Orion pelo acesso da
    tripulação (§7.8), que é opcional e não altera a sequência linear.

------------------------------------------------------------------------

## 2. Planta geral e coordenadas

### 2.1 Sistema de coordenadas

Adotar um sistema cartesiano consistente:

-   **X:** largura do complexo.
-   **Y:** altura.
-   **Z:** comprimento e direção de progressão do jogador.
-   O eixo central do complexo fica em **X = 0**.
-   O jogador progride no sentido de **Z positivo**.

As coordenadas são referências de layout para montagem no Roblox Studio.
Ajustes locais podem ser feitos para alinhar paredes, portas, pisos e
modelos.

### 2.2 Sequência dos ambientes

  -----------------------------------------------------------------------
  Ambiente         Intervalo      Largura X  Comprimento Z         Altura
               aproximado em                               
                           Z                               
  ----------- -------------- -------------- -------------- --------------
  Base NASA            0--55       70 studs       55 studs       24 studs

  Corredor 1          55--90       14 studs       35 studs       12 studs

  Museu Space        90--170       90 studs       80 studs       42 studs
  Adventure                                                

  Corredor 2        170--210       16 studs       40 studs       14 studs

  Hangar SLS        210--320      140 studs      110 studs      150 studs
  -----------------------------------------------------------------------

Centros aproximados em Z:

-   Base: Z = 27,5
-   Corredor 1: Z = 72,5
-   Museu: Z = 130
-   Corredor 2: Z = 190
-   Hangar: Z = 265

**Área aproximada dos pisos dos cinco ambientes:** 27.580 studs².\
Essa soma considera as dimensões retangulares indicadas; não inclui
paredes, estruturas externas ou áreas técnicas adicionais.

### 2.3 Continuidade

Os ambientes devem se conectar sem degraus ou vãos inesperados. Portas e
passagens devem estar alinhadas ao eixo central, salvo quando houver
indicação contrária. A passagem deve ser intuitiva, sem exigir que o
jogador procure a próxima área.

Convenções adotadas na implementação:

-   O topo de todos os pisos fica em **Y = 0**, com laje de Y −1 a 0.
-   As dimensões da tabela são **medidas internas**; as paredes ficam
    por fora.
-   As divisórias entre ambientes ficam centradas em Z = 55, 90, 170 e
    210, com aberturas no eixo X = 0.

------------------------------------------------------------------------

## 3. Base NASA --- recepção e spawn

### 3.1 Conceito

Uma recepção ampla, organizada e institucional, inspirada em instalações
modernas da NASA. Deve transmitir tecnologia, pesquisa e exploração
espacial, sem parecer uma loja ou um tycoon.

**Dimensões:** 70 × 55 × 24 studs.

### 3.2 Organização

-   Área de spawn próxima à entrada.
-   Balcão de recepção à esquerda de quem nasce.
-   Painel institucional visível à frente.
-   Telas informativas à direita.
-   Bancos ou sofás em uma área de espera.
-   Saída posicionada ao fundo, alinhada ao primeiro corredor.

### 3.3 Coordenadas de referência

  Elemento                Posição aproximada
  ----------------------- --------------------
  Spawn                   (0, 3, 12)
  Balcão                  (-20, 0, 15)
  Painel institucional    (0, 8, 3)
  Painel de informações   (22, 4, 15)
  Porta de saída          (0, 0, 53)
  Área de espera          (15, 0, 35)

As posições representam referências de organização. Dimensionar cada
objeto de acordo com sua geometria e orientação.

**Orientação do spawn (decidida):** o jogador nasce virado para **−Z**.
Só assim as posições acima ficam coerentes com §3.2: painel
institucional à frente, balcão à esquerda e telas à direita. A saída
(Z = 55) fica às costas e é indicada por placa e por uma faixa azul no
piso.

A saída da recepção tem portas automáticas de vidro de 14 × 12 studs
(§10).

### 3.4 Elementos visuais

-   Balcão de recepção.
-   Computadores e monitores.
-   Cadeiras e sofás.
-   Painel institucional com identidade visual NASA Space Adventure.
-   Telas com informações da experiência.
-   Portas automáticas.
-   Vasos ou elementos decorativos discretos.
-   Iluminação branca e uniforme.
-   Grandes superfícies de vidro, quando fizer sentido.

### 3.5 Paleta

-   Branco: `#FFFFFF`
-   Cinza claro: `#E7E9EA`
-   Cinza médio: `#AAB3BB`
-   Azul institucional: `#244B70`
-   Vermelho de destaque: `#D33D32`

A recepção deve ser clara, limpa e bem iluminada. Evitar excesso de
objetos pequenos.

------------------------------------------------------------------------

## 4. Corredor 1 --- transição para o museu

**Dimensões:** 14 × 35 × 12 studs.

### 4.1 Conceito

Corredor moderno e limpo, funcionando como transição entre a recepção e
a experiência imersiva do museu.

### 4.2 Elementos

-   Piso contínuo em cinza claro.
-   Paredes brancas ou cinza muito claro.
-   Trechos de vidro.
-   Iluminação linear no teto.
-   Quadros ou painéis com imagens de exploração espacial.
-   Sinalização direcional.
-   Porta ou abertura ampla na entrada do museu.

### 4.3 Sinalização

Na entrada do museu, usar uma identificação legível:

**SPACE ADVENTURE --- EXPLORE THE UNIVERSE**

A sinalização deve ser visível antes de o jogador atravessar a entrada.

Na implementação, a entrada do museu é um portal de 12 × 9 studs dentro
do corredor de 14 × 12 studs. Isso deixa espaço para o letreiro acima do
portal.

------------------------------------------------------------------------

## 5. Museu Space Adventure --- planetário imersivo

### 5.1 Conceito e dimensões

O museu deve ser o principal ambiente de exploração educativa. O espaço
será aberto, imersivo e dominado por uma cúpula de planetário.

-   **Área do museu:** 90 × 80 studs.
-   **Altura máxima:** 42 studs.
-   **Cúpula central:** aproximadamente 68 studs de diâmetro e até 42
    studs de altura.

A cúpula pode ser construída com segmentos, nervuras e painéis. A
geometria final deve respeitar a circulação e não bloquear a visão das
exposições.

### 5.2 Cúpula

-   Estrutura circular ou poligonal aproximando uma cúpula.
-   Nervuras metálicas visíveis.
-   Painéis escuros ou azul profundo.
-   Projeção visual de estrelas e nebulosas.
-   Planetas suspensos em diferentes alturas.
-   Iluminação azul indireta.
-   Centro visual livre o suficiente para destacar o sistema solar.

A cúpula deve criar sensação de amplitude. Evitar excesso de peças
pequenas e luzes individuais.

Medidas adotadas: o salão principal tem 18 studs de altura. A cúpula é
um polígono de 16 lados que nasce em Y = 18 e chega a Y = 42, com
abertura circular no teto do salão. O céu estrelado e as nebulosas são
feitos apenas com SurfaceGui, sem peças extras.

### 5.3 Organização interna

O salão principal deve permanecer aberto, sem uma sequência de salas
fechadas. Organizar as exposições em zonas temáticas ao redor da área
central.

Manter um caminho de circulação contínuo, com largura de referência de
aproximadamente **8 studs**. O jogador deve conseguir contornar as
exposições sem ficar preso entre objetos.

### 5.4 Zonas de exposição

#### A. Sistema Solar

-   Sol como elemento central de destaque.
-   Oito planetas representados em escala visual simplificada.
-   Lua em posição de destaque complementar.
-   Estrelas e elementos de fundo.
-   Órbitas visuais para explicar o movimento dos planetas.

Não é necessário representar distâncias ou tamanhos em escala científica
real. Priorizar leitura visual e espaço para circulação.

#### B. Exploração humana

-   Manequins de astronautas.
-   Trajes espaciais.
-   Capacetes e equipamentos.
-   Painéis sobre missões tripuladas.
-   Representações de atividades extraveiculares.

#### C. Foguetes e espaçonaves

-   Miniatura do SLS.
-   Miniatura do Saturn V.
-   Cápsula Orion.
-   Painéis explicativos comparando veículos e missões.

#### D. Exploração planetária

-   Cenário inspirado em Marte.
-   Rover em exposição.
-   Sondas espaciais.
-   Superfície rochosa cenográfica.
-   Painéis sobre exploração robótica.

#### E. Ciência e descobertas

-   Satélites.
-   Telescópios e sondas.
-   Telas informativas.
-   Painéis sobre observação do universo e pesquisa espacial.

As placas e painéis do mapa usam textos em inglês, coerentes com o
letreiro do §4.3.

### 5.5 Paleta e iluminação

-   Fundo espacial: `#080D20`
-   Azul escuro: `#101D3D`
-   Azul profundo: `#153D72`
-   Azul médio: `#397EC4`
-   Azul claro: `#8ECDFB`

A iluminação deve ser mais escura que a recepção, mas suficiente para o
jogador enxergar o caminho, as exposições e outros jogadores. Usar luzes
de destaque nas peças principais.

------------------------------------------------------------------------

## 6. Corredor 2 --- transição industrial

**Dimensões:** 16 × 40 × 14 studs.

### 6.1 Conceito

O segundo corredor deve mudar claramente a linguagem visual: sair do
ambiente educativo do museu e entrar em uma área técnica de acesso ao
hangar.

### 6.2 Elementos

-   Paredes de concreto e metal.
-   Tubulações e dutos aparentes.
-   Estruturas metálicas.
-   Faixas de segurança amarelas.
-   Luzes industriais e de emergência.
-   Placas de acesso restrito.
-   Portas industriais deslizantes.
-   Janelas laterais opcionais para antecipar a escala do hangar.

### 6.3 Porta de entrada do hangar

-   Abertura industrial ampla.
-   Dimensão de referência da porta: 24 × 30 studs.
-   Porta deslizante ou portão segmentado.
-   A abertura deve permitir visão direta do foguete centralizado.

Mesmo que o portão seja decorativo na primeira versão, sua estrutura
deve parecer compatível com a escala do hangar.

Na implementação, o Corredor 2 tem uma porta industrial deslizante
(aberta) perto de Z = 176. O pórtico de 24 × 30 studs fica na parede
frontal do hangar, com o portão segmentado recolhido, ou seja, aberto.

------------------------------------------------------------------------

## 7. Hangar NASA SLS

### 7.1 Conceito e dimensões

O hangar será o grande momento visual da experiência. Deve transmitir
escala monumental, tecnologia e ambiente de montagem aeroespacial,
inspirado no Vehicle Assembly Building da NASA.

-   **Dimensões:** 140 × 110 × 150 studs.
-   **Centro aproximado:** X = 0, Z = 265.
-   **Foguete:** SLS Block 1, com aproximadamente 117 studs de altura na
    escala visual do mapa.

A altura do foguete é uma decisão de composição para o Roblox, não uma
reprodução física em escala 1:1.

### 7.2 Composição visual

O foguete deve ficar no centro do hangar, em posição vertical. A entrada
frontal deve enquadrar o foguete para que o jogador o veja assim que
atravessar o portão.

Elementos principais:

-   Foguete SLS central.
-   Plataforma de montagem na base.
-   Torres de serviço laterais.
-   Passarelas e escadas.
-   Estruturas metálicas de suporte.
-   Guindastes ou vigas superiores.
-   Veículos de manutenção nas laterais.
-   Sala de observação elevada.
-   Portões industriais.
-   Iluminação de grande altura.

### 7.3 Foguete SLS --- componentes visuais

Representar os principais componentes reconhecíveis:

1.  Cápsula Orion no topo.
2.  Sistema de escape da cápsula.
3.  Estágio superior.
4.  Estágio central laranja.
5.  Dois propulsores laterais.
6.  Conjunto de motores RS-25 na parte inferior.

O foguete deve ser composto por partes agrupadas em um único Model
lógico, mantendo componentes separados quando isso facilitar a edição. A
silhueta geral deve ser reconhecível à distância.

Na implementação, o SLS fica sobre o lançador móvel, com deck em
Y = 10. O foguete ocupa de Y ≈ 10,5 a Y ≈ 127,5. O módulo de serviço da
Orion termina em Y = 111,5, e o módulo da tripulação vai de Y = 111,5 a
Y = 115.

### 7.4 Torres e plataforma

-   Duas torres de serviço em posições laterais ao foguete, como
    referência em X ≈ -20 e X ≈ +20.
-   Passarelas conectando as torres ao foguete.
-   Escadas e plataformas em níveis diferentes.
-   Plataforma móvel ou base de montagem sob o foguete.
-   Estruturas de suporte com aparência industrial.

As torres não devem ocultar a silhueta principal do foguete quando o
jogador entra pela frente. Ajustar alturas, afastamentos e vãos para
manter a leitura visual.

Medidas adotadas:

-   As torres vão do deck (Y = 10) até Y ≈ 105. Têm passarelas até o
    foguete em Y = 40, 60 e 100 e escadas de marinheiro na face externa.
-   A torre esquerda (X ≈ −20) foi prolongada até Y ≈ 119, para chegar à
    altura da Orion e receber o braço de acesso da tripulação (§7.8).
-   A escada do lançador fica à frente e à esquerda (X −22..−16, Z
    234..245) e leva ao vestiário da tripulação.

### 7.5 Sala de observação

Criar uma sala elevada em uma das laterais do hangar, como referência
próxima de (45, 35, 250).

-   Janelas amplas voltadas para o foguete.
-   Estrutura de metal e vidro.
-   Console ou painel de observação.
-   Acesso por escada ou elevador cenográfico.
-   Área suficiente para jogadores observarem o hangar.

Medidas adotadas: a sala fica em X 44..70 e Z 238..262, com piso em
Y = 35. As janelas são voltadas para o foguete e para o portão frontal.
O acesso é por uma escada de 35 degraus junto à parede lateral, com
passarela até a porta.

### 7.6 Portões

-   Portão frontal na região de Z ≈ 210.
-   Portão de manutenção na região de Z ≈ 315.
-   Portas de aparência industrial, compatíveis com a altura do hangar.
-   O portão frontal deve permanecer aberto ou permitir a visão do
    foguete na experiência inicial.

Medidas adotadas: o portão de manutenção tem 40 × 100 studs, fica
fechado e está em Z ≈ 319.

### 7.7 Paleta

-   Cinza escuro: `#555B60`
-   Cinza metálico: `#8A9298`
-   Cinza claro: `#D5D7D8`
-   Amarelo de segurança: `#E5B52E`
-   Laranja/vermelho industrial: `#B94C2B`

A iluminação deve combinar luzes industriais superiores com focos
direcionados ao foguete. Evitar deixar o hangar tão escuro que os
detalhes desapareçam.

### 7.8 Acesso da tripulação à Orion

*Acrescentado na Revisão 2, a pedido.* Trata-se de um percurso opcional
e exploratório dentro do hangar. Não é um sistema de lançamento.

**Percurso:** escada do lançador → vestiário → elevador → braço de
acesso → White Room → escotilha → cabine da Orion.

  -----------------------------------------------------------------------------
  Elemento                Posição de referência        Observações
  ----------------------- ---------------------------- ------------------------
  Vestiário (Crew         X −24..−14,5; Z 246..256;    Sobre o lançador; a
  Suit-Up Room)           Y 10..19                     escada chega nele

  Elevador da             X −22,6..−17,4;              Cabine inferior em
  tripulação              Z 255,6..262                 Y = 10,1 e superior em
                                                       Y = 111,5

  Braço de acesso         X −17..−3,2; Z 263,5..266,5; Sai do topo da torre
                          Y = 111,5                    esquerda

  White Room              X −6,5..−3,2; Z 263..267;    Encostada na cápsula,
                          Y 111,5..118                 aberta do lado da Orion

  Cabine da Orion         Centro (0, −60, 265);        Interior em escala
  (interior)              Ø 32 no piso, Ø 19 no teto,  humana, sob o hangar
                          15 de altura
  -----------------------------------------------------------------------------

Elementos:

-   **Vestiário:** quatro armários com o traje laranja OCSS (Orion Crew
    Survival System), placas e banco. O jogador veste ou tira o traje
    pelo prompt do armário.
    -   O traje cobre o corpo em laranja, com luvas, botas, capacete de
        vidro e patch azul.
    -   Acessórios como cabelo e chapéus ficam ocultos enquanto o traje
        está vestido.
    -   O traje é opcional e some quando o personagem renasce.
    -   O texto do prompt muda conforme o estado: *Put on suit* ou
        *Take off suit*.
-   **Elevador:** cada cabine tem portas deslizantes e uma luz de
    status.
    -   O prompt fecha as portas das duas cabines e escurece a tela dos
        ocupantes, com o texto do destino.
    -   Em seguida, leva todos para a outra cabine e reabre as portas.
    -   Enquanto o jogador está dentro da cabine, os prompts dos
        armários vizinhos ficam desativados para ele, para não
        competirem pela tecla E.
    -   É um elevador cenográfico; a escada de marinheiro da torre
        continua disponível.
-   **Plataforma final:** deck no topo da torre esquerda, com
    guarda-corpos, o braço de acesso e a White Room.
-   **Escotilha:** fica na lateral −X do módulo da tripulação. O prompt
    escurece a tela e leva o jogador para a cabine; a escotilha interna
    o traz de volta à White Room.
-   **Cabine:** a Orion, na escala do foguete, tem cerca de 3,5 studs de
    altura e não comporta um personagem. Por isso o interior é um modelo
    separado, em escala humana, posicionado sob o hangar e escondido pela
    Baseplate. É um polígono de 16 lados, com 32 studs de diâmetro no
    piso, 19 no teto e 15 de altura. A cabine tem:
    -   quatro assentos reclinados (CDR, PLT, MS1, MS2), em duas
        fileiras, com a de trás numa plataforma elevada. O prompt
        *Take seat* some quando o assento está ocupado e permite trocar
        de assento sem pular;
    -   à frente, um console com três telas (unidades de display) e
        controladores manuais;
    -   cinco janelas com céu estrelado;
    -   painéis de chaves (POWER e LIFE SUPPORT) e corrimãos;
    -   atrás, a escotilha com placa de saída, o compartimento de
        higiene, armários de estiva, bolsas de carga e uma placa
        informativa;
    -   no teto, um anel de luz e o túnel de acoplamento.

Restrições:

-   O acesso da tripulação não pode bloquear a escada do lançador, a
    visão do foguete pela entrada frontal nem a circulação do hangar.
-   Não incluir contagem regressiva, ignição, decolagem ou qualquer
    simulação de voo sem solicitação explícita.

------------------------------------------------------------------------

## 8. Materiais e linguagem visual

Usar materiais consistentes para reforçar a identidade de cada área.

  Aplicação                         Material sugerido
  --------------------------------- ------------------------------------------
  Pisos da base e áreas comuns      Concrete
  Paredes internas claras           SmoothPlastic
  Janelas e divisórias              Glass
  Estruturas metálicas              Metal
  Pisos e plataformas industriais   DiamondPlate
  Cúpula                            Metal e SmoothPlastic
  Estágio central do SLS            Material metálico com acabamento laranja
  Propulsores e peças externas      SmoothPlastic ou Metal
  Luzes e detalhes luminosos        Neon
  Painéis informativos              SurfaceGui sobre peças apropriadas

Não usar Neon em grandes superfícies sem necessidade; reservar para
sinalização, telas, linhas de luz e detalhes.

------------------------------------------------------------------------

## 9. Organização sugerida no Roblox Studio

Manter os ambientes separados em Models para facilitar edição, teste e
otimização.

``` text
Workspace
├── Map
│   ├── NASA_Base
│   │   ├── Floor
│   │   ├── Walls
│   │   ├── Reception
│   │   ├── Furniture
│   │   └── SpawnLocation
│   ├── Corridor_01
│   │   ├── Floor
│   │   ├── Walls
│   │   ├── Doors
│   │   └── Decorations
│   ├── Space_Adventure
│   │   ├── Floor
│   │   ├── Walls
│   │   ├── Dome
│   │   ├── Solar_System
│   │   ├── Astronaut_Exhibition
│   │   ├── Rocket_Exhibition
│   │   ├── Mars_Exhibition
│   │   ├── Science_Exhibition
│   │   └── Screens
│   ├── Corridor_02
│   │   ├── Floor
│   │   ├── Industrial_Structure
│   │   ├── Pipes
│   │   ├── Doors
│   │   └── Windows
│   └── Rocket_Hangar
│       ├── Floor
│       ├── Structure
│       ├── Gates
│       ├── SLS_Rocket
│       ├── Launch_Platform
│       ├── Gantry
│       ├── Maintenance_Vehicles
│       ├── Observation_Room
│       └── Crew_Access
│           ├── Suit_Room
│           ├── Crew_Elevator
│           ├── Crew_Access_Arm
│           └── Orion_Cabin
├── Lighting_Objects
└── Atmosphere_Objects

ReplicatedStorage
├── Assets
└── CrewFade

ServerScriptService
└── Map_Systems
    ├── AutomaticDoors
    └── CrewAccess

StarterPlayer
└── StarterPlayerScripts
    ├── PlanetOrbits
    └── CrewClient
```

O `Map` deve ficar **diretamente** em `Workspace`. Os scripts procuram
`Workspace.Map`, e mover o mapa para dentro de outra pasta interrompe
portas, planetas e o acesso da tripulação.

Scripts implementados (um por sistema, nenhum em objetos individuais):

  -------------------------------------------------------------------------
  Script               Local                         Função
  -------------------- ----------------------------- ----------------------
  `AutomaticDoors`     `ServerScriptService/         Abre Models com o
  (Script)             Map_Systems`                  atributo
                                                     `AutoDoor = true`
                                                     quando um jogador se
                                                     aproxima

  `PlanetOrbits`       `StarterPlayer/               Gira os planetas no
  (LocalScript)        StarterPlayerScripts`         cliente, só como
                                                     efeito visual

  `CrewAccess`         `ServerScriptService/         Trata os
  (Script)             Map_Systems`                  ProximityPrompts com
                                                     o atributo
                                                     `CrewAction`: `Suit`,
                                                     `Elevator`,
                                                     `Teleport` e `Sit`;
                                                     move as portas do
                                                     elevador

  `CrewClient`         `StarterPlayer/               Escurece a tela nas
  (LocalScript)        StarterPlayerScripts`         transições, ajusta o
                                                     texto do prompt do
                                                     traje e desativa os
                                                     armários dentro do
                                                     elevador

  `CrewFade`           `ReplicatedStorage`           Avisa o cliente de
  (RemoteEvent)                                      quando escurecer e
                                                     clarear a tela
  -------------------------------------------------------------------------

Os nomes podem ser mantidos em inglês para facilitar consistência com
nomes de instâncias e scripts. O mapa visual deve continuar organizado
por ambiente.

------------------------------------------------------------------------

## 10. Interatividade --- implementada e futura

A primeira etapa pode ser inteiramente explorável, sem sistemas
complexos. Se a experiência evoluir, considerar:

-   Portas automáticas.
-   Painéis informativos.
-   Interação com exposições.
-   Rotação lenta dos planetas.
-   Telas informativas.
-   Abertura e fechamento dos portões do hangar.
-   Elevador ou acesso à sala de observação.
-   Efeitos ambientais de iluminação.

Esses itens são possibilidades futuras, não requisitos para concluir a
arquitetura estática.

**Já implementado (Revisão 2):**

-   Portas automáticas de vidro na saída da recepção. Abrem num raio de
    13 studs e fecham quando não há jogador por perto.
-   Rotação lenta dos planetas do sistema solar, apenas visual, no
    cliente.
-   Acesso da tripulação à Orion (§7.8):
    -   trajes no vestiário;
    -   elevador cenográfico na torre esquerda;
    -   escotilha;
    -   assentos na cabine.

Continuam como possibilidades futuras:

-   Interação com exposições.
-   Telas dinâmicas.
-   Abertura dos portões do hangar.
-   Elevador da sala de observação.
-   Efeitos ambientais.

------------------------------------------------------------------------

## 11. Requisitos técnicos e otimização

A experiência deve funcionar bem em computadores e dispositivos
modestos.

-   Ativar `StreamingEnabled` quando adequado ao tamanho final do mapa.
-   Agrupar objetos decorativos em Models.
-   Preferir MeshParts para formas complexas, como foguete e planetas.
-   Evitar excesso de peças pequenas na cúpula.
-   Reutilizar materiais e componentes.
-   Desativar colisão em objetos decorativos que não precisam ser
    tocados.
-   Limitar luzes dinâmicas e sombras simultâneas.
-   Evitar scripts individuais em cada objeto.
-   Manter o SLS organizado em componentes dentro de um Model.
-   Testar a experiência com vários jogadores.
-   Conferir colisões, pontos de travamento e visibilidade em diferentes
    configurações gráficas.

------------------------------------------------------------------------

## 12. Ordem recomendada de produção

A ordem abaixo é uma recomendação para uma futura implementação, não uma
solicitação para iniciar a construção agora.

1.  **Estrutura geral:** terreno, pisos, paredes e conexão dos cinco
    ambientes.
2.  **Arquitetura:** corredores, cúpula, hangar, portas e janelas.
3.  **Elementos principais:** SLS, planetas, exposições e plataformas.
4.  **Decoração:** móveis, placas, telas, tubulações e veículos.
5.  **Iluminação:** iluminação institucional, imersiva e industrial.
6.  **Interatividade:** somente após a estrutura visual estar estável.
7.  **Testes:** circulação, colisões, desempenho e multiplayer.
8.  **Acesso da tripulação** (acrescentado na Revisão 2): vestiário,
    elevador, braço de acesso, White Room e cabine da Orion (§7.8).

------------------------------------------------------------------------

## 13. Critérios de aceitação

Considerar o mapa arquitetonicamente concluído quando:

-   [ ] O jogador nasce dentro da recepção NASA.
-   [ ] A saída da base é fácil de identificar.
-   [ ] O primeiro corredor conecta corretamente a base ao museu.
-   [ ] O museu possui cúpula imersiva e exposições reconhecíveis.
-   [ ] Existe caminho contínuo para circular pelo museu.
-   [ ] O segundo corredor apresenta linguagem visual industrial.
-   [ ] A entrada do hangar é frontal.
-   [ ] O SLS é visto imediatamente ao entrar no hangar.
-   [ ] O foguete está centralizado e tem silhueta reconhecível.
-   [ ] As torres e passarelas complementam, sem esconder, o foguete.
-   [ ] A sala de observação é visível e acessível, caso incluída.
-   [ ] Não há vãos, colisões ou bloqueios inesperados no percurso.
-   [ ] O mapa mantém desempenho aceitável em multiplayer.

Critérios do acesso da tripulação (§7.8):

-   [ ] O jogador consegue vestir e tirar o traje no vestiário.
-   [ ] O elevador leva os ocupantes entre o lançador e o braço de
    acesso, nos dois sentidos.
-   [ ] As portas do elevador fecham durante a viagem e reabrem na
    chegada.
-   [ ] A escotilha leva à cabine da Orion e de volta, com a tela
    escurecendo na transição.
-   [ ] Os quatro assentos da cabine podem ser ocupados, e é possível
    trocar de assento.
-   [ ] O acesso não bloqueia a escada do lançador nem a visão do
    foguete pela entrada frontal.

------------------------------------------------------------------------

## 14. Orientações para uma IA de desenvolvimento

Ao usar este documento como contexto para uma IA de programação ou
assistência no Roblox Studio:

1.  Trate este arquivo como a especificação de referência do mapa.
2.  Não altere as decisões já definidas sem explicar o motivo e pedir
    confirmação.
3.  Não transforme o projeto em tycoon, simulador de construção de
    foguetes ou jogo de lançamento.
4.  Não implemente sistemas de lançamento, combustível, missões ou
    progressão sem solicitação explícita.
5.  Priorize a arquitetura e a composição visual dos ambientes.
6.  Preserve a sequência linear: **Base NASA → Corredor 1 → Museu Space
    Adventure → Corredor 2 → Hangar SLS**.
7.  Preserve a entrada frontal do hangar e a visão imediata do foguete.
8.  Use as dimensões e coordenadas como referências de planejamento,
    ajustando detalhes para garantir conexões e proporções coerentes.
9.  Se precisar criar scripts, faça isso somente quando solicitado e
    explique em qual serviço ou objeto do Roblox Studio cada script deve
    ficar.
10. Antes de mudanças estruturais grandes, apresente a proposta e seus
    impactos.
11. Mantenha o `Map` diretamente em `Workspace` e preserve os nomes das
    pastas do §9, porque os scripts dependem deles.
12. O acesso da tripulação (§7.8) é exploratório. Não o transforme em
    lançamento, missão ou progressão sem solicitação explícita.

### Resumo executivo

Criar um mapa Roblox de exploração espacial com cinco ambientes
conectados em sequência. O jogador nasce em uma recepção inspirada na
NASA, atravessa um corredor moderno, visita um museu imersivo sob uma
cúpula de planetário, passa por um corredor industrial e chega a um
hangar monumental. No centro do hangar está um foguete NASA SLS
vertical, em escala visual adaptada ao Roblox, visível imediatamente
pela entrada frontal. O foco é a ambientação, a arquitetura e a
exploração visual. Como extra opcional, o jogador pode vestir um traje,
subir pela torre de serviço e entrar na cápsula Orion para se sentar
com a tripulação, sem nenhuma mecânica de lançamento.
