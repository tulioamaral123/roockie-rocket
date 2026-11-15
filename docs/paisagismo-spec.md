# Rookie Rocket — Paisagismo e ambientação externa

## 1. Objetivo

Complementar o paisagismo já existente do complexo com acesso de visitantes, estacionamento, jardins, lago e nuvens suaves, preservando a circulação, a visibilidade e o funcionamento do centro espacial inspirado na Flórida.

A proposta é visual: não implementar direção de veículos, transporte, novas missões ou sistemas de simulação como parte desta tarefa.

## Estado atual verificado em 15/11/2026

- No checkout `/Users/tulioamaral/Documents/nasa`, branch `claude/rookie-rocket` (commit `ab6e01c`), a Fase 1 aplica material `Grass` verde às baseplates externas e suas divisões.
- A Fase 23, `build/phase23_landscape.luau`, já cria `NASAComplex.Landscape.Trees`: palmeiras sabal e carvalhos com semente fixa, testes de espaço e exclusões para lançamento, visibilidade da plataforma e eixo da recepção. O runner já inclui a Fase 23.
- A consulta ao Studio aberto, place ID `116695605898974`, encontrou 39 palmeiras, 31 carvalhos, baseplate com `Grass` e nenhum objeto `Clouds` em `Terrain`. Isso confirma a presença desses elementos, não a qualidade visual deles nem o estado publicado mais recente.
- `IMPLEMENTATION.md` registra aplicação de grama e árvores e diz que a aparência ainda precisava de conferência. O estacionamento da Fase 11 é **do crawler**, não o estacionamento de visitantes solicitado aqui.
- As tarefas 5, 6 e 7 ainda listavam `build/run_in_studio.luau` como reservado na verificação; confira `TASKS.md` novamente antes de modificar qualquer arquivo compartilhado. Há outras tarefas aguardando teste no Studio.
- Não confirmei nesta revisão a presença ou ausência de um lago ou estacionamento de visitantes no place inteiro; inspecione os locais e geradores antes de criar esses elementos.

## 2. Antes de começar

1. Leia `CLAUDE.md`, `AGENTS.md`, `TASKS.md`, `spec-v3.md` e os trechos relevantes das especificações do mapa. Verifique as tarefas em andamento e as reservas de arquivos antes de editar.
2. Inspecione o mapa atual no Studio e no código. Confirme a localização da recepção, do planetário, museu, centro de controle, VAB, plataforma, entradas, caminhos, pontos de navegação e limites do terreno. As referências abaixo são aproximações de uma inspeção anterior, sujeitas a mudanças.
3. Preserve o fluxo de geração por fases e as regras de idempotência. Se criar uma fase de paisagismo, registre-a e integre-a ao processo de reconstrução apenas quando os arquivos necessários estiverem disponíveis para esta tarefa. Não edite manualmente o place como fonte definitiva.
4. O `build/run_in_studio.luau` e outros arquivos compartilhados já apareceram reservados por outras tarefas. Confira `TASKS.md` atualizado e siga a regra do projeto caso ainda haja conflito.
5. A reconstrução anterior relatou uma falha na validação de circulação da fase 16, relacionada a um pedestal. Verifique o estado atual e reporte separadamente qualquer falha anterior à sua mudança.
6. Use textos visíveis em inglês. Para modelos 3D externos, siga a regra do projeto: apenas Roblox Creator Store, registrando ID e licença em `assets/LICENSES.md`. Prefira geometria simples do próprio projeto quando apropriado.

## 3. Direção visual

- Centro espacial contemporâneo, com paisagismo inspirado na costa da Flórida: gramados, palmeiras esparsas, árvores de porte variado e arbustos baixos.
- Organize a paisagem em áreas de visitantes próximas à entrada e vegetação mais natural nas bordas do complexo.
- Use cores naturais e iluminação equilibrada; o foguete, o VAB e o museu devem continuar sendo os pontos focais.
- Varie escala e rotação de poucos modelos leves para evitar repetição evidente. Não coloque vegetação dentro de prédios ou encobrindo portas, janelas e placas.
- O cenário deve parecer integrado ao nível do solo existente, sem peças flutuantes, z-fighting ou degraus inesperados.

## 4. Entrada, acesso e estacionamento

Criar uma área de chegada em frente à recepção, após confirmar onde fica a entrada usada pelo jogador.

- Via de acesso visualmente conectada ao estacionamento e ao complexo, com superfície e bordas claramente distinguíveis do gramado.
- Estacionamento proporcional à escala do mapa, com vagas demarcadas e algumas vagas acessíveis próximas ao caminho de entrada.
- Caminho contínuo de pedestres do estacionamento até a porta, com faixa de travessia quando houver cruzamento com a via. Manter espaço livre para circulação e acesso.
- Acrescentar canteiros baixos, bancos e iluminação espaçada. Placas e sinais, caso existam, devem estar em inglês.
- Veículos decorativos são opcionais; se adicionados, não devem obstruir vagas acessíveis, caminhos ou acessos. A área não exige veículos dirigíveis.
- Validar que o spawn, a seta do tutorial e as portas existentes não fiquem encobertos ou presos.

## 5. Jardins da recepção e do museu

- Aproveitar o gramado e as árvores já existentes; acrescentar canteiros e vegetação pontual ao redor da recepção e do planetário, respeitando suas fundações, entradas e caminhos.
- Distribuir pequenos grupos de árvores e palmeiras, com arbustos e plantas baixas para compor o cenário.
- Manter uma faixa livre junto às portas, janelas, sinais e rotas do jogador. Não cobrir exposições ou telas visíveis do interior.
- Usar variações moderadas de tamanho e distância entre plantas. A composição deve continuar legível a partir do ponto de vista de quem entra no jogo.

## 6. Lago e área natural

- Avaliar primeiro uma área livre a oeste do complexo para um lago irregular; confirmar no Studio a posição, o terreno, as rotas e os limites antes de fixar coordenadas.
- Construir uma margem visualmente natural, com vegetação baixa e algumas árvores afastadas da água. Acrescentar um pequeno mirante ou caminho de observação ligado à área de visitantes, se houver espaço seguro.
- Escolher a solução de água compatível com o terreno e os sistemas existentes. Se for apenas decorativa, evitar dar a entender que há natação ou travessia implementada.
- Evitar superfícies transparentes caras, interseções com a baseplate e bordas em que o jogador possa ficar preso ou cair para fora do mapa.
- Não ocupar a rota de pedestres para a plataforma, áreas de segurança ou espaços necessários a futuras fases.

## 7. Entorno do VAB e da plataforma

- Aproveitar a grama e a vegetação já existentes; complementar apenas onde necessário, sem alterar o funcionamento da infraestrutura.
- Manter completamente livres portões, saída de pedestres, crawlerway, plataforma, área de observação e rotas de acesso.
- Posicionar árvores de modo que não interceptem o conjunto de transporte durante todo o percurso, inclusive recuo e deslocamento lateral do crawler.
- Preservar a visão do SLS a partir do portão frontal e a vista da plataforma a partir da área de observação. Evitar árvores altas perto das linhas de visão e dos elementos móveis.
- Não adicionar obstáculos físicos novos dentro de zonas de segurança ou rotas de navegação.

## 8. Céu e nuvens

- Adicionar nuvens leves e espaçadas, preferencialmente utilizando os recursos nativos de atmosfera e nuvens já compatíveis com o projeto.
- Conferir a iluminação existente antes de alterar cobertura, densidade, cor ou atmosfera. Preservar o contraste dos prédios e não escurecer excessivamente a cena.
- Verificar o resultado a partir da entrada, do VAB e da plataforma, inclusive olhando para o foguete. Evitar que nuvens ocultem continuamente pontos importantes.

## 9. Organização técnica

- Aproveitar a Fase 23 existente. Decidir, conforme as reservas atuais, se a ampliação pertence à própria Fase 23 ou a uma fase complementar; não duplicar as árvores existentes. Toda fase deve seguir o padrão de `BuildPhase` e limpeza idempotente do projeto.
- Garantir que reexecutar a fase não duplique árvores, vias, iluminação ou configurações de nuvens. Não apagar elementos de outras fases. A Fase 23 sorteia árvores antes de uma possível fase posterior: reserve as futuras áreas de estacionamento, lago e caminhos na lógica de distribuição, ou defina outra ordem segura; valide reconstrução limpa e reexecução independente sem sobreposições.
- Usar nomes claros para grupos, como `EntranceLandscape`, `Parking`, `MuseumGardens`, `Lake` e `OuterVegetation`, adaptando-os às convenções já existentes.
- Preservar caminhos, pontos de navegação e propriedades de outras fases. Registrar quaisquer dependências ou alterações compartilhadas necessárias.
- Usar quantidades moderadas de peças e iluminação; agrupar elementos quando fizer sentido e evitar efeitos e scripts por planta. Considerar streaming e desempenho em dispositivos modestos.

## 10. Ordem sugerida

1. Inspecionar o mapa e delimitar as áreas permitidas e proibidas.
2. Construir entrada, acesso e estacionamento; validar a circulação.
3. Acrescentar jardins próximos à recepção e ao museu.
4. Definir a posição do lago e construir margens e mirante, reconciliando as áreas ocupadas com a Fase 23.
5. Completar a vegetação distante, respeitando o VAB, crawlerway e plataforma.
6. Ajustar nuvens e iluminação, revisar a cena em diferentes pontos de vista.
7. Executar as validações do projeto e um playtest completo de circulação.

## 11. Critérios de aceite

- A entrada possui acesso de pedestres e estacionamento legíveis; o jogador chega à recepção sem obstáculos.
- Jardins e árvores não cobrem entradas, janelas, placas, exposições ou indicadores essenciais.
- Lago e mirante ficam em área livre, sem conflito com rotas, limites ou zonas operacionais.
- O portão do VAB e o percurso completo do crawler permanecem desobstruídos; a visão do SLS e da plataforma permanece livre.
- Reexecutar a nova fase não duplica nem remove conteúdo de outras fases.
- Nuvens e iluminação deixam o cenário legível e mantêm o foguete visível.
- Validar as regras dimensionais, varredura do trajeto e playtest do percurso descritos em `CLAUDE.md`. Executar `stylua --check build` e `selene build` se estiverem instalados.
- Registrar no resultado arquivos e assets utilizados, suas licenças quando aplicável, fases a executar no Studio, testes realizados, falhas preexistentes e limitações. Atualizar `IMPLEMENTATION.md` e `TASKS.md` conforme as regras do projeto.

---

## Implementação (15/11/2026)

**Mapa conferido no Studio:** entrada da recepção voltada para −Z (marquise em (0, 11, −4)); spawn dentro da recepção em (0, 0, 12); planetário X 44..136, Z −12..68, porta em (60, 11, −9); frente (Z < 0) e oeste (X < −100) só com grama; iluminação de dia (ClockTime 13, Atmosphere e Sky da Fase 5), sem nuvens. Não havia lago nem estacionamento de visitantes. A falha antiga da Fase 16 (pedestal no planetário) não se repete no place atual.

**Fase 23 (alterada):** reserva as áreas da Fase 24 (estrada, estacionamento, praça e calçadas, lago, caminho do lago, jardins do planetário) e cria a pasta `Landscape` sem `BuildPhase` (a limpeza de uma fase não apaga a outra). Reexecutada: 70 árvores, nenhuma sobre a Fase 24.

**Fase 24 (nova, `build/phase24_outdoor.luau`):**
- `EntranceLandscape`: estrada X −500..500, Z −121..−99 (asfalto, faixas brancas e tracejado amarelo), praça X −24..24, Z −44..−6, calçada até a estrada, faixa de pedestres em X −5..5, desembarque do outro lado com bancos e placa VISITOR DROP-OFF, placa VISITOR ENTRANCE, 4 canteiros, 2 bancos e 8 postes de luz (PointLight sem sombra).
- `Parking`: estacionamento X −160..−40, Z −97..−28 com 24 vagas demarcadas em 2 fileiras, entrada pela estrada, 2 vagas acessíveis (azuis) junto à calçada que leva à praça, placas VISITOR PARKING e ACCESSIBLE PARKING, 3 postes e 6 carros decorativos fora das vagas acessíveis.
- `MuseumGardens`: 3 canteiros e arbustos ao sul do planetário, porta em X ≈ 60 livre.
- `Lake`: lago em (−232, 15) feito de 5 discos opacos (sem transparência), areia na margem, pedras e juncos; barreira invisível de 14 na margem e colisores de 12 no mirante (não se entra na água, nem pulando); mirante de madeira com guarda-corpo, banco e placa LAKE OVERLOOK, ligado ao estacionamento por um caminho.
- `OuterVegetation`: 40 tufos de arbustos na grama livre, fora das zonas reservadas.
- Nuvens nativas (`Terrain.Clouds`): Cover 0,5, Density 0,3, brancas; iluminação mantida.
- Cerca de 580 peças e 14 luzes; nenhum modelo externo nem asset novo.

**Validações (Studio, Edit):** nenhuma peça da Fase 24 encosta em peça de outra fase (fora grama e paisagismo); nenhuma árvore sobre a Fase 24; pathfinding do estacionamento e do desembarque até a porta da recepção: ok (dentro, a porta automática abre no jogo); do estacionamento até a ponta do mirante: ok; até o meio do lago, de 4 lados, com e sem pulo: sem caminho. Complexo de lançamento, rota do crawler e visão da área de observação ficam fora de todas as áreas usadas (zonas reservadas).

**Não verificado:** aparência (captura de tela do Studio indisponível), celular, playtest completo do percurso e varredura do crawler rodada de novo (nada foi colocado perto dela). `stylua`/`selene` não instalados.

**Para reconstruir:** Fase 23 e depois Fase 24 (o runner já inclui as duas, nessa ordem).
