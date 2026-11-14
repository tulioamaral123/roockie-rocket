# NASA SPACE ADVENTURE — SPEC DE CONSTRUÇÃO DO MAPA

**Versão:** 3.1 — Revisão arquitetônica, corrigida contra o mapa construído  
**Plataforma:** Roblox Studio  
**Escopo:** Construção física, arquitetura, dimensões, organização espacial e compatibilidade futura com transporte do SLS.

Esta spec substitui o `spec-ultimate.md` e o adendo técnico 2.0 no que diz respeito à construção física. O `spec.md` continua valendo para tudo o que já foi construído e que esta versão não altera (coordenadas, recepção, corredores, museu, iluminação).

---

## 0. Correções da revisão 3.1

A versão 3.0 foi conferida contra a geometria dos geradores em `build/`. As correções abaixo já estão incorporadas no texto das seções indicadas.

| # | Problema na 3.0 | Correção | Seção |
|---|---|---|---|
| 1 | "Saída frontal" do conjunto. O portão frontal (24 × 30, Z = 210) dá no Corredor 2 e no museu. | A saída do conjunto é pelo **portão dos fundos** (Z ≈ 320), ampliado de 40 × 100 para 80 × 140. A área externa fica em Z > 320. | 3.2, 3.3, 9 |
| 2 | Ponte rolante: gancho desce até Y 128,5 em Z ≈ 285, no eixo X = 0. O topo do SLS passa a 133. | Gancho recolhido acima de Y 136 ou estacionado fora do envelope. Viga em Y 136 mantida (folga de 3 studs). | 3.4 |
| 3 | Não existe crawler. O deck do lançador está em Y 10, sobre pedestais. | Crawler de Y 0 a 7, base do ML de Y 7 a 15,5 (8,5 de altura). Tudo o que está sobre o deck sobe +5,5 studs. | 4.1, 4.4 |
| 4 | O vestiário está sobre o deck do lançador (X −24..−14,5), e não numa estrutura fixa. | O vestiário vai para uma sala fixa do VAB, ao lado da escada do lançador. | 6.2 |
| 5 | Existem duas torres de serviço (X ±20); a spec prevê uma. | A torre esquerda vira a torre móvel. A torre direita é removida (está dentro do envelope). | 5.2 |
| 6 | Letreiro "SPACE LAUNCH SYSTEM" na parede dos fundos (X ±30, Y 106–122) fica dentro da nova abertura. | Letreiro removido ou reposicionado acima do portão (Y > 140) ou em parede lateral. | 3.2 |
| 7 | Museu "Cape Canaveral" × planetário Space Adventure já construído. | O planetário é preservado. Só muda o nome da pasta. | 7 |
| 8 | Torre de serviço fixa na plataforma, além da torre do ML. | No Pad 39B a torre do ML faz esse papel. A plataforma não tem torre de serviço fixa; ficam as torres de para-raios e a torre de água. | 9, 9.2, 11 |
| 9 | Sem saída de pedestres do VAB para a área externa. | Porta de pedestres própria, fora da rota do crawler. | 3.5, 10 |
| 10 | Retorno da escotilha da Orion para coordenada fixa. | O retorno é calculado a partir da posição atual da White Room. | 5.4 |
| 11 | Renomear `Map` para `NASAComplex` quebra `AutomaticDoors` e `CrewAccess`. | Renomear junto com o ajuste desses scripts. | 11.1 |

---

## 1. Objetivo desta versão

Esta versão define exclusivamente a construção do complexo espacial.

O foco é garantir que:
- O mapa preserve as estruturas que já foram construídas.
- O SLS tenha um único modelo.
- O conjunto de transporte consiga atravessar o VAB.
- O Mobile Launcher tenha dimensões compatíveis com o hangar.
- As estruturas de acesso à tripulação estejam corretamente posicionadas.
- A área externa tenha espaço para receber o conjunto.
- A arquitetura permita adicionar sistemas de missão futuramente.

Não implementar nesta etapa:
- Sistema de missões.
- Contagem regressiva funcional.
- Decolagem.
- Transporte automatizado.
- Persistência de progresso.
- DataStore.
- BadgeService.
- Sistema de recompensas.
- Multiplayer de eventos globais.

Esses sistemas serão especificados em uma versão futura.

---

## 2. Decisões de arquitetura

### 2.1 Quantidade de foguetes

O complexo terá apenas um foguete SLS.

O mesmo Model será utilizado futuramente no VAB e na plataforma de lançamento.

Não criar:
- SLS duplicado na plataforma.
- SLS exclusivo para demonstrações.
- Cópias ocultas do foguete para animações.

### 2.2 Organização do conjunto

O conjunto físico será dividido em três partes:

1. Crawler-Transporter.
2. Mobile Launcher.
3. SLS.

O SLS ficará apoiado sobre o Mobile Launcher.

O Mobile Launcher será sustentado pelo crawler durante o transporte.

A torre do Mobile Launcher ficará ao lado do foguete.

### 2.3 Referência de escala

Preservar as dimensões já utilizadas no projeto sempre que possível.

| Elemento | Dimensão |
|---|---|
| Hangar VAB | 140 × 110 × 150 studs (X −70..70, Z 210..320) |
| SLS | 117 studs de altura |
| Crawler | 7 studs de altura (Y 0..7) |
| Base do Mobile Launcher | 8,5 studs de altura (Y 7..15,5) |
| Torre do Mobile Launcher | 110 studs acima da base (topo em Y 125,5) |
| Portão de saída do conjunto (fundos) | 80 × 140 studs |

As dimensões são valores de construção e poderão sofrer ajustes locais após a montagem do conjunto.

### 2.4 Eixos

Mantém-se o sistema do `spec.md`: X = largura, Y = altura, Z = progressão do jogador, eixo central em X = 0. O conjunto sai do VAB no sentido **+Z**, pelo portão dos fundos, o mesmo sentido em que o jogador progride.

---

## 3. Hangar VAB

### 3.1 Dimensões

Preservar:

- Largura: 140 studs.
- Profundidade: 110 studs.
- Altura: 150 studs.

Não reconstruir o hangar inteiro para utilizar as dimensões de 140 × 150 × 180 da especificação anterior.

### 3.2 Portões

O hangar tem dois portões, com funções diferentes.

**Portão frontal (Z = 210) — acesso dos jogadores**
- Mantido como está: 24 × 30, aberto, ligado ao Corredor 2.
- Não é usado pelo conjunto de transporte.

**Portão dos fundos (Z ≈ 320) — saída do conjunto**

O atual portão de manutenção (40 × 100) deverá ser ampliado.

Dimensões mínimas planejadas:

- Largura: 80 studs (X −40..40).
- Altura: 140 studs.
- A parede dos fundos tem 152 de altura; acima do portão restam cerca de 12 studs de parede.

O portão deverá permitir a passagem do conjunto completo.

Requisitos:
- Abertura livre.
- Ausência de colunas internas na passagem.
- Trilhos e mecanismos fora do envelope do conjunto.
- Nenhuma decoração pendurada invadindo a abertura.
- Espaço para movimentação na entrada e saída.
- O letreiro "SPACE LAUNCH SYSTEM" (hoje em X ±30, Y 106–122 na parede dos fundos) deverá ser removido da abertura e reposicionado acima do portão (Y > 140) ou numa parede lateral.

O mecanismo de abertura poderá ser construído nesta fase, mesmo que ainda não seja funcional.

### 3.3 Interior

Manter:
- Foguete centralizado (X = 0, Z = 265).
- Estruturas metálicas.
- Plataformas industriais.
- Passarelas.
- Pontes rolantes.
- Iluminação industrial.
- Equipamentos laterais.
- Área de observação (X 44–70, fora do envelope).

A posição do conjunto deve permitir uma saída alinhada ao portão dos fundos, seguindo o eixo X = 0 no sentido +Z.

### 3.4 Espaço livre

Reservar um corredor de circulação desde a posição inicial do conjunto até o portão dos fundos.

Envelope de transporte dentro do VAB:
- X −34..34 (largura de 68).
- Y 0..133.
- Z do início do conjunto até Z = 320.

Nenhuma estrutura fixa poderá ocupar o envelope de transporte.

Itens existentes que precisam ser ajustados:
- **Ponte rolante:** o bloco do gancho (hoje Y 128,5–131,5, em Z ≈ 285) deverá ser recolhido acima de Y 136 ou estacionado fora de X −34..34. A viga, em Y 136–139, pode permanecer.
- **Torre de serviço direita (X ≈ 20):** está dentro do envelope. Ver §5.2.

Itens que já estão fora do envelope e podem permanecer: caminhão utilitário (X −48..−42), plataforma tesoura (X 42..48), sala de observação e sua escada (X 44–70).

As estruturas decorativas poderão ficar próximas à rota, mas não deverão invadir a área de segurança.

### 3.5 Saída de pedestres

Criar uma porta de pedestres no VAB para a área externa, separada do portão dos fundos e fora da rota do crawler.

Os jogadores não devem precisar atravessar o envelope de transporte para chegar à área externa ou à sala de controle.

---

## 4. Envelope de transporte

### 4.1 Altura

O conjunto deverá respeitar a seguinte referência:

| Elemento | Faixa em Y |
|---|---|
| Crawler | 0..7 |
| Base do Mobile Launcher | 7..15,5 |
| Torre | 15,5..125,5 (110 acima da base) |
| SLS | 16..133 (117 acima do ponto de apoio; o apoio fica 0,5 acima do deck, nos holddown posts) |

Altura máxima prevista: 133 studs.

Portão: 140 studs.

Folga vertical: 7 studs.

A torre e o foguete ficam lado a lado. Suas alturas não devem ser somadas entre si.

### 4.2 Largura

O conjunto deverá possuir largura máxima planejada de 68 studs.

O portão terá 80 studs de largura.

Folga total: 12 studs.

Deixar pelo menos 6 studs de cada lado.

Referência atual: o deck do lançador tem 48 × 40 (X −24..24, Z 245..285).

### 4.3 Validação

Antes de detalhar os equipamentos:

1. Criar o crawler como bloco.
2. Criar a base do Mobile Launcher.
3. Criar a torre como bloco.
4. Criar o SLS.
5. Montar o conjunto.
6. Criar um volume de colisão representando o envelope máximo.
7. Testar a passagem pelo portão dos fundos.
8. Testar a entrada e a saída.
9. Verificar se o conjunto não colide com teto, paredes, ponte rolante ou equipamentos.

Somente depois da validação começar os detalhes.

### 4.4 Ajuste do conjunto existente

Hoje o lançador está sobre pedestais (Y 0..3), com o deck de Y 3 a 10, sem crawler embaixo.

Com o crawler de Y 0 a 7 e a base do ML de Y 7 a 15,5, tudo o que está sobre o deck sobe **+5,5 studs**.

A base tem 8,5 (e não 9) para que o topo do SLS fique em 133 e a folga vertical no portão seja de 7 studs. O SLS mede 117 e fica 0,5 acima do deck, sobre os holddown posts.


| Elemento | Hoje | Depois |
|---|---|---|
| Topo do deck | Y 10 | Y 15,5 |
| Base do SLS | Y 10,5 | Y 16 |
| Topo do SLS (torre de escape) | Y 127,5 | Y 133 |
| Cabine inferior do elevador | Y 10,1 | Y 15,6 |
| Cabine superior do elevador / deck do braço | Y 111,5 | Y 117 |
| Topo da torre esquerda | ≈ Y 119,5 | ≈ Y 125 |
| White Room e braço de acesso | acompanham o deck superior | +5,5 |

Os pedestais atuais (Y 0..3) são substituídos pelo crawler. A escada de acesso ao deck passa a ter 15,5 de altura.

---

## 5. Mobile Launcher

### 5.1 Estrutura

A torre do Mobile Launcher deverá ser construída como parte do conjunto móvel.

Ela não deverá ser confundida com a estrutura fixa do hangar.

Elementos:
- Torre metálica.
- Plataformas.
- Escadas.
- Elevadores.
- Braços de acesso.
- Braços umbilicais.
- Cabos.
- Tubulações.
- Passarelas.
- Área de acesso à Orion.

### 5.2 Torre móvel

A torre deverá ter aproximadamente 110 studs de altura acima da base.

O modelo poderá ser simplificado, mas deverá apresentar:
- Estrutura metálica vertical.
- Plataformas distribuídas por níveis.
- Escadas e elevadores.
- Passarelas.
- Braços de conexão.
- Área de acesso à cápsula.

Aproveitamento do que existe:
- **Torre esquerda (X ≈ −20):** vira a torre móvel. Já tem o elevador, o deck superior, o braço de acesso e a White Room. Passa a fazer parte de `MobileLauncher.ServiceTower`.
- **Torre direita (X ≈ 20):** removida. Está dentro do envelope e o Mobile Launcher real tem uma única torre. Os braços que ela tinha nos níveis 40 e 60 podem ser recriados na torre esquerda, se necessário.

### 5.3 Acesso da tripulação

O acesso à cápsula Orion deverá acompanhar o Mobile Launcher quando o conjunto for transportado.

O conjunto móvel deverá conter:
- Elevador de acesso.
- Escadas.
- Plataforma de acesso.
- White Room cenográfica.
- Braço de acesso à Orion.

A White Room deverá ficar posicionada junto à entrada da cápsula.

Não manter a White Room presa a uma estrutura fixa do VAB se ela precisar acompanhar o foguete até a plataforma.

### 5.4 Interior da Orion

O interior em escala humana continua sendo um modelo separado, abaixo do hangar (centro em 0, −60, 265), acessado por teleporte pela escotilha.

Ele pode permanecer fixo. Porém, o teleporte de volta deverá usar a posição atual da White Room (por exemplo, um `Attachment` ou Part de referência dentro de `WhiteRoom`), e não uma coordenada fixa. Assim, quem sair da cápsula com o conjunto na plataforma reaparece na White Room da plataforma, e não no VAB.

---

## 6. Estruturas fixas do VAB

As estruturas existentes que não fazem parte do Mobile Launcher devem permanecer fixas.

Podem permanecer no VAB:
- Vestiários.
- Salas técnicas.
- Áreas administrativas.
- Salas de observação.
- Plataformas fixas de manutenção.
- Equipamentos de suporte.
- Elevadores de serviço do prédio.
- Escadas de emergência.

Essas estruturas não deverão ser transportadas pelo crawler.

### 6.1 Separação entre acesso fixo e móvel

O projeto terá dois tipos de acesso:

**Acesso fixo do VAB**
- Utilizado para manutenção e visitação dentro do hangar.
- Não acompanha o foguete.
- Permanece preso à arquitetura do edifício.

**Acesso móvel do Mobile Launcher**
- Acompanha o foguete.
- Utilizado para acesso à cápsula.
- Inclui plataformas, elevadores, passarelas e White Room.

Apenas o acesso que precisa acompanhar a Orion deve ser construído no Mobile Launcher.

### 6.2 Vestiário

O vestiário (Crew Suit-Up Room) hoje está **sobre o deck do lançador** (X −24..−14,5, Z 246..256), ou seja, faria parte do conjunto móvel.

Ele deverá ser movido para uma sala fixa do VAB, no piso do hangar, ao lado da escada de acesso ao lançador e fora do envelope (X < −34).

Percurso resultante: vestiário (fixo, VAB) → escada do lançador → elevador (móvel) → braço de acesso → White Room → escotilha → interior da Orion.

Quando o conjunto estiver na plataforma, o vestiário fica no VAB. O traje é opcional, então isso não bloqueia o acesso à Orion na plataforma.

---

## 7. Museu

Preservar o museu já construído: o planetário **Space Adventure** (90 × 80, cúpula até Y 42, zonas A–E), conforme o `spec.md`.

A pasta passa a se chamar `CapeCanaveralMuseum` na hierarquia do §11, mas a arquitetura, a cúpula e as exposições não mudam.

Elementos:
- Fachada.
- Área de recepção.
- Exposições.
- Modelos de foguetes.
- Cápsulas.
- Satélites.
- Painéis informativos.
- Telas.
- Iluminação de exposição.

O museu não precisa ser alterado para acomodar o transporte do SLS.

A conexão com o VAB deve continuar clara e acessível.

---

## 8. Sala de controle

Nesta versão, a sala de controle será construída como ambiente físico e cenográfico.

Elementos:
- Consoles.
- Cadeiras.
- Monitores.
- Telão principal.
- Painéis.
- Iluminação.
- Mapas e diagramas.

Não implementar a sequência funcional de lançamento nesta etapa.

Os consoles deverão ser posicionados de maneira que futuramente possam receber interações.

Reservar pelo menos um console principal com espaço para uma interface de início de operação.

O acesso à sala de controle deverá continuar independente da rota do crawler (ver §3.5).

---

## 9. Área externa

Construir a área externa, em Z > 320, para receber o mesmo conjunto que sai pelo portão dos fundos do VAB.

Elementos:
- Pátio.
- Rota do crawler.
- Área de posicionamento do Mobile Launcher.
- Plataforma de lançamento.
- Tanques cenográficos.
- Tubulações.
- Trincheira de chamas.
- Defletor.
- Torre de água.
- Torres de proteção contra raios.
- Cercas.
- Área de observação.

A plataforma **não tem torre de serviço fixa**. Como no Pad 39B, a torre do Mobile Launcher faz esse papel quando o conjunto chega.

### 9.1 Área de estacionamento do crawler

Reservar uma área lateral à plataforma para o crawler.

A área deverá permitir:
- Separação do Mobile Launcher.
- Estacionamento.
- Retorno.
- Reconexão.

Não colocar edifícios, postes ou estruturas fixas nessa área.

### 9.2 Plataforma

A plataforma deverá possuir espaço para o Mobile Launcher e o SLS.

Os pontos de conexão (umbilicais de solo, apoios do ML) deverão ser compatíveis com a posição final do conjunto.

As torres de para-raios e a torre de água ficam fora do envelope do conjunto e da área de estacionamento do crawler.

---

## 10. Rota do crawler

Construir a rota antes de adicionar detalhes no pátio.

Requisitos:
- Largura suficiente para o conjunto.
- Curvas suaves.
- Piso nivelado.
- Ausência de obstáculos.
- Espaço para manobras.
- Conexão direta entre o portão dos fundos do VAB e a plataforma.

Reservar uma zona de exclusão ao redor de toda a rota.

A zona de exclusão deverá ser livre de:
- Jogadores durante a movimentação futura.
- Edifícios.
- Árvores.
- Postes.
- Equipamentos decorativos.
- Objetos com colisão.

Os caminhos de pedestres (saída de pedestres do VAB, acesso à sala de controle e à área de observação) não podem cruzar a rota. Se for inevitável, usar passarela elevada acima de Y 140.

A largura exata da rota será definida a partir do envelope final do conjunto e das curvas necessárias.

---

## 11. Organização técnica do mapa

Estrutura sugerida:

```text
Workspace
└── NASAComplex
    ├── Reception
    ├── Corridors
    ├── CapeCanaveralMuseum
    │   ├── Architecture
    │   ├── Exhibits
    │   └── InformationPanels
    │
    ├── VABHangar
    │   ├── Architecture
    │   ├── FrontGate
    │   ├── RearGate
    │   ├── PedestrianExit
    │   ├── CrewSuitUpRoom
    │   ├── FixedPlatforms
    │   ├── FixedElevators
    │   ├── FixedAccessTowers
    │   ├── Cranes
    │   └── IndustrialEquipment
    │
    ├── TransportSystem
    │   ├── TransportAssembly
    │   │   ├── CrawlerTransporter
    │   │   ├── MobileLauncher
    │   │   │   ├── Base
    │   │   │   ├── ServiceTower
    │   │   │   ├── AccessArms
    │   │   │   ├── WhiteRoom
    │   │   │   └── Platforms
    │   │   └── SLSRocket
    │   │       ├── OrionCapsule
    │   │       ├── LaunchAbortSystem
    │   │       ├── CoreStage
    │   │       ├── Boosters
    │   │       └── Engines
    │   │
    │   └── CrawlerRoute
    │
    ├── OrionInterior
    │
    ├── LaunchControlCenter
    │   ├── Architecture
    │   ├── Consoles
    │   └── MainScreens
    │
    ├── LaunchPad
    │   ├── Architecture
    │   ├── FlameTrench
    │   ├── FlameDeflector
    │   ├── WaterTower
    │   ├── LightningTowers
    │   └── ServiceTanks
    │
    └── SafetyZones
```

### 11.1 Migração da hierarquia atual

Hoje o mapa está em `Workspace.Map`, com o hangar em `Map.Rocket_Hangar` (`Launch_Platform`, `Gantry`, `SLS_Rocket`, `Gates` etc.).

- Os scripts `AutomaticDoors` e `CrewAccess` procuram atributos (`AutoDoor`, `CrewAction`) dentro do `Map`. Renomear para `NASAComplex` exige ajustar esses scripts no mesmo passo.
- Os geradores em `build/` também referenciam `Map` e os nomes atuais. Atualizar os geradores junto, para que continuem idempotentes.
- O atributo `BuildPhase` continua valendo para identificar o que cada gerador criou.

---

## 12. Preparação para movimentação futura

Embora o transporte funcional esteja fora do escopo atual, a construção deverá facilitar sua implementação.

### 12.1 Organização dos modelos

- O conjunto de transporte deverá possuir uma referência central.
- A posição inicial deverá ser definida no VAB.
- A posição final deverá ser definida na plataforma.
- O crawler deverá possuir uma referência própria.
- O Mobile Launcher deverá possuir uma referência própria.
- O SLS deverá possuir uma referência própria.
- Os braços umbilicais deverão ser organizados separadamente.
- A White Room deverá ter uma referência de retorno para a escotilha (§5.4).

### 12.2 Pivôs

Definir pivôs consistentes para:
- TransportAssembly.
- CrawlerTransporter.
- MobileLauncher.
- SLSRocket.
- Braços umbilicais.

Os pivôs devem facilitar futuras movimentações sem exigir reposicionamento manual de centenas de peças.

### 12.3 Movimento futuro e clientes

A movimentação global deverá ser autorizada pelo servidor.

Para evitar movimento visual truncado em conjuntos grandes, a implementação futura poderá utilizar:

1. Servidor publica estado, destino e horário de início.
2. Clientes interpolam visualmente o movimento.
3. Servidor permanece responsável pelo estado verdadeiro.
4. Ao finalizar, todos recebem a posição final oficial.

Essa interpolação visual não poderá conceder autoridade ao cliente para iniciar ou modificar o transporte.

---

## 13. Critérios de aceitação do mapa

- [ ] Hangar preservado em 140 × 110 × 150 studs.
- [ ] SLS com aproximadamente 117 studs.
- [ ] Existe apenas um Model do SLS.
- [ ] Mobile Launcher integrado ao conjunto de transporte, sobre o crawler.
- [ ] Torre móvel dimensionada para 110 studs acima da base.
- [ ] Existe uma única torre no Mobile Launcher.
- [ ] Portão dos fundos com 80 × 140 studs de abertura.
- [ ] Conjunto passa pelo portão dos fundos sem colisões.
- [ ] Existe folga lateral mínima de 6 studs.
- [ ] Existe folga vertical mínima de 7 studs.
- [ ] Ponte rolante fora do envelope (gancho acima de Y 136 ou fora do eixo).
- [ ] Estruturas fixas não invadem a rota.
- [ ] Acesso móvel à Orion acompanha o Mobile Launcher.
- [ ] Vestiário fixo no VAB, fora do Mobile Launcher.
- [ ] Saída da Orion leva à posição atual da White Room.
- [ ] Existe saída de pedestres do VAB fora da rota.
- [ ] Sala de controle está construída.
- [ ] Museu (planetário) preservado e conectado ao complexo.
- [ ] Plataforma comporta o conjunto completo, sem torre de serviço fixa.
- [ ] Existe área de estacionamento para o crawler.
- [ ] A rota está livre de obstáculos e não é cruzada por caminhos de pedestres.
- [ ] `AutomaticDoors` e `CrewAccess` funcionam após a migração da hierarquia.
- [ ] O mapa está preparado para futura movimentação do conjunto.

---

## 14. Ordem de construção

### Etapa 1 — Validação dimensional
- Ampliar o portão dos fundos para 80 × 140 e reposicionar o letreiro.
- Recolher ou estacionar o gancho da ponte rolante.
- Conferir a altura do hangar.
- Criar blocos de referência.
- Montar o envelope de transporte.
- Testar a passagem.

### Etapa 2 — Conjunto móvel
- Criar o crawler sob o lançador, substituindo os pedestais.
- Ajustar a base do Mobile Launcher para Y 7..15,5.
- Subir +5,5 studs tudo o que está sobre o deck.
- Transformar a torre esquerda em torre móvel e remover a torre direita.
- Posicionar o SLS.
- Criar a estrutura central e pivôs.

### Etapa 3 — Acesso à tripulação
- Mover o vestiário para uma sala fixa do VAB.
- Preservar acessos fixos.
- Conferir o acesso móvel (elevador, braço, White Room) na torre móvel.
- Tornar o retorno da escotilha relativo à White Room.
- Conferir acesso e circulação.

### Etapa 4 — VAB
- Criar a saída de pedestres.
- Completar plataformas fixas.
- Completar guindastes.
- Completar iluminação.
- Completar equipamentos industriais.
- Conferir rota livre.

### Etapa 5 — Área externa
- Construir a plataforma.
- Construir o pátio.
- Construir rota do crawler.
- Criar estacionamento.
- Posicionar torres de para-raios, torre de água e equipamentos.
- Construir a sala de controle com acesso independente da rota.

### Etapa 6 — Migração e acabamento
- Migrar a hierarquia para `NASAComplex` e ajustar scripts e geradores.
- Detalhar estruturas.
- Aplicar materiais.
- Adicionar sinalização.
- Adicionar iluminação.
- Otimizar modelos.
- Testar circulação e o percurso da tripulação.

---

## 15. Fora do escopo desta versão

Não desenvolver ainda:
- MissionController.
- CrawlerController funcional.
- LaunchSequenceController.
- PlayerSafetyController funcional.
- DataStore.
- BadgeService.
- Recompensas.
- Contagem regressiva.
- Decolagem.
- Sistema de cooldown.
- Sistema de eventos multiplayer.

A prioridade é terminar a arquitetura física e garantir que o conjunto caiba e possa percorrer o caminho planejado.

**Resultado esperado:** um complexo espacial visualmente completo, com VAB, SLS, Mobile Launcher, museu, sala de controle e plataforma, preparado para receber sistemas de transporte e lançamento em uma versão posterior.
