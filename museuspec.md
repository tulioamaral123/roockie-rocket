# Museu Espacial no Roblox: spec de design e construcao

Projeto: **Estagiario Espacial** (nome provisorio), NASA Space Apps Challenge 2026, sede Goiania.
Data: 14/11/2026. Plataforma: **Roblox (principal)**, Roblox Studio + Luau, PC e celular.
Este documento substitui o spec gerado no ChatGPT ("NASA Space Museum"). Onde os dois discordam, vale este.

---

## 0. Leia primeiro (para o Claude e para quem vai construir)

1. Leia o documento inteiro antes de criar qualquer arquivo. A secao 12 diz a ordem de construcao.
2. **Nao invente fatos.** Datas, numeros tecnicos, nomes de tripulantes e origem de artefatos vem de fonte NASA (ou Smithsonian), com link. Todo texto de exposicao nasce com `Verificado = false` e so aparece no modo de demo depois que o responsavel pelo conteudo confere (secao 9). Os dados deste spec foram conferidos em bases oficiais da NASA em 14/11/2026 (secao 16, com o ID de cada fonte). O que nao foi confirmado em fonte oficial esta marcado **(nao verificado)**. **Fotos: so imagens reais de bancos de dados da NASA** (images.nasa.gov), nunca imagens geradas por IA ou tiradas de sites de terceiros (secao 16.3).
3. **Nao invente APIs do Roblox.** Em duvida, consulte create.roblox.com/docs. As APIs citadas aqui existem, mas confira assinaturas antes de usar.
4. **Nenhum fato no codigo.** Textos e numeros moram nos modulos de conteudo (`Conteudo/`); o codigo so le e exibe.
5. **Um sistema, muitas exposicoes.** Nunca um script por placa. Uma placa nova = um arquivo de dados + uma tag no modelo.
6. Teste cada etapa no Studio (Play, e o emulador de dispositivo para celular) antes de dizer que terminou. Diga com clareza o que exige trabalho manual no Studio (modelagem, encaixe de modelos, iluminacao).
7. Idioma de todo texto exibido: **portugues do Brasil**, com acentos.

---

## 1. Intencao

O jogo e o centro: o jogador e um estagiario de agencia espacial que monta missoes, lanca e ganha **cards de missoes reais da NASA**. O museu e o **complemento educativo**: o lugar onde o jogador vive a historia da exploracao espacial e onde ficam os cards que conquistou.

**Criterio de sucesso:** um jurado entra no museu e fica **impressionado com a historia da NASA**. Isso vem de tres coisas, nesta ordem:

1. **Escala:** entrar e ver o Saturn V inteiro sobre a cabeca, em tamanho real.
2. **Historia em sequencia:** caminhar de Mercury ate Artemis e entender a progressao.
3. **Um momento forte:** o show de lancamento, com luz, som e contagem regressiva.

O visitante deve sentir que esta num museu espacial de verdade, nao num mapa comum do Roblox.

### Metas
- Museu fiel ao real em proporcoes, cores, marcacoes e informacao.
- Experiencia do usuario impecavel em PC e celular: nada quebra, nada trava, toda janela fecha, todo texto e legivel.
- Ligacao clara com o jogo: cards conquistados acendem vitrines no museu.

### Fora do escopo agora
- Qualquer versao web: por enquanto o projeto e so Roblox.
- As fases do jogo em si (estao sendo redefinidas). O museu so expoe os pontos de ligacao (secao 7).

### Anti-metas (falhou, mesmo que "funcione")
- Parecer lobby de jogo, com barras de RPG, moedas, pop-ups e neon.
- Modelos de estilos diferentes lado a lado sem acabamento comum.
- Qualquer fato errado ou sem fonte numa placa.
- Painel que abre vazio, interacao que nao responde, tela que nao fecha.
- Acidentes reais tratados como atracao (memorial e silencio e respeito).

---

## 2. Decisoes ja tomadas pelo time

| Tema | Decisao |
|---|---|
| Plataforma | Roblox e o principal, 3D, inclusive celular |
| Estilo visual | **Realista e limpo**: proporcoes e cores reais, materiais do Roblox, iluminacao forte de museu. Nada de fotorrealismo pesado nem cartoon |
| Espaco | **Uma unica grande sala** (salao). Sem divisao em salas separadas. Areas sao "ilhas" dentro do salao |
| Cards | O album de cards de missao fica **dentro do museu** |
| Marca NASA | **Pode usar** o logo da NASA (decisao do time). Nos veiculos, as marcacoes aparecem como no objeto real. Observacao: os termos do Space Apps pedem permissao escrita para usar o "meatball"/"worm"; o time vai confirmar com o Local Lead de Goiania. Deixe o logo numa unica textura trocavel (`Config.Marca`) para poder trocar pelo logo do Space Apps sem refazer nada |
| Modelos | Modelos 3D prontos de antes + modelos gerados por varias IAs, ajustados ao estilo comum (secao 10) |
| Fluxo de trabalho | Codigo em arquivos com **Rojo** + git; mapa e modelos montados no Studio via **Team Create** (secao 11) |
| Jogo | Primeiro um jogador; o servidor Roblox pode ter varios, mas cada um vive o museu sozinho (shows e paineis sao locais) |

---

## 3. O salao (layout)

Inspirado no Apollo/Saturn V Center do Kennedy Space Center Visitor Complex: um grande salao com o Saturn V deitado e suspenso, estagios separados, iluminado de baixo. Fonte NASA (KSC-98pc1004): o centro tem ~9.300 m2 (100.000 pes2) e expoe um Saturn V Apollo restaurado de 363 pes (110,6 m), antes exposto perto do VAB; outra foto oficial mostra visitantes "sob os motores do Saturn V em exposicao" (KSC-99pp1144). A disposicao exata (altura de suspensao, distancia entre estagios) **(nao verificado)**: tirar das fotos oficiais da secao 16.3 antes de modelar.

### 3.1 Escala
- Referencia de escala: `Config.METROS_POR_STUD = 0.28` (convencao da documentacao do Roblox). Antes de montar, coloque um boneco R15 padrao ao lado de uma barra de 1,80 m e confirme que a proporcao parece certa; se nao parecer, ajuste a constante uma vez e use-a em tudo.
- Toda medida real passa por `Escala.metros(m)` (helper em `Shared/Utilidades`). Nenhum tamanho fixo em studs espalhado pelo codigo.
- Saturn V: 363 pes = **110,6 m** de comprimento; primeiro estagio com 33 pes = **10,1 m** de diametro (fonte NASA, secao 16.1) -> ~395 x 36 studs.

### 3.2 Dimensoes propostas (ajustar no greybox)
- Salao: ~180 m x 100 m. Teto principal ~28 m.
- **Atrio de vidro** numa ponta do salao, com teto de vidro a ~45 m e ceu visivel: e o "Jardim de foguetes" dentro do mesmo salao (os foguetes ficam em pe e precisam de altura).
- Andar do jogador a 16 studs/s atravessa o salao em ~40 s. Se ficar longo demais nos testes, encurte o salao, nao aumente a velocidade.

### 3.3 Mapa do salao (percurso cronologico, sentido horario)

```
            ATRIO DE VIDRO (ceu visivel)
        +-------------------------------+
        |  2  JARDIM DE FOGUETES        |
        |     (Redstone, Atlas, ...)    |
+-------+-------------------------------+--------+
|  1 PIONEIROS     ======= SATURN V =========   4 |
|  Mercury/Gemini  (suspenso, eixo central,     ATLANTIS
|                   estagios separados)          + HUBBLE
|  0 ENTRADA       3 APOLLO (sob o Saturn V):     |
|  recepcao, robo  CM Apollo, Apollo 11, linha    5 MEMORIAL
|  mapa            do tempo, DIORAMA DO SHOW     (nicho rebaixado)
|                                                  |
|  8 PAREDE DE MISSOES   7 MODERNA     6 MARTE     |
|  (album de cards)      ISS/Webb/     rovers      |
|                        Artemis                   |
+--------------------------------------------------+
```

- O Saturn V e a **espinha** do salao: visivel de qualquer ponto, ajuda a se orientar.
- Ao entrar (area 0), a primeira coisa no campo de visao e o motor F-1 do primeiro estagio, de frente, em escala real. Esse e o "uau" dos primeiros 5 segundos.
- Corredores largos (minimo ~6 m), sem becos sem saida.
- O memorial (5) fica num **nicho rebaixado** (piso alguns degraus abaixo, paredes altas, luz baixa), ainda dentro do salao, mas acusticamente isolado: som ambiente cai a quase zero ao entrar.

---

## 4. As ilhas e suas exposicoes

Cada item abaixo vira um arquivo em `Conteudo/Exposicoes/`. "Demo" = precisa estar pronto para os jurados. "Depois" = entra se der tempo.

### 0. Entrada e recepcao (Demo)
- Portal de entrada, balcao de informacoes, totem com o mapa do salao, robo-guia (o mesmo robo do jogo) que cumprimenta o jogador pelo nome na primeira visita.
- Sem catracas, bilheteria nem estacionamento (era do spec antigo; nao agregam nada).

### 1. Pioneiros: Mercury e Gemini (Demo: Mercury; Gemini depois)
- Capsula Mercury com interacao 360 e componentes clicaveis (escudo termico, janela, paraquedas, retrofoguetes).
- Painel "Corrida espacial": Sputnik 1 e o comeco da NASA.
- Painel Mercury Seven: os sete astronautas escolhidos pela NASA em 27/4/1959 (fonte 8772556), com retratos oficiais.
- Traje espacial Mercury em vitrine.

### 2. Jardim de foguetes (Depois; na demo, ao menos 2 foguetes)
- Foguetes em pe sob o vidro: Mercury-Redstone e Mercury-Atlas primeiro (ligados a Mercury). Depois Juno I (Jupiter-C, lancou o Explorer 1 em 31/1/1958) e Gemini-Titan II. Fonte NASA (KSC-03pd2174, foto de 2003): o Rocket Garden real tem "oito foguetes autenticos", incluindo um Mercury-Atlas, e replicas de capsulas Mercury, Gemini e Apollo em que se pode entrar. A lista completa atual de foguetes **(nao verificado em fonte oficial)**.
- Cada foguete: ficha tecnica (altura, combustivel, motores, lancamentos), botao "ver estagios".

### 3. Apollo e Saturn V (Demo, prioridade maxima)
- **Saturn V suspenso**, com tres estagios: S-IC (5 motores F-1), S-II (5 motores J-2), S-IVB (1 motor J-2), unidade de instrumentos (entre o S-IVB e a nave), e a nave Apollo: modulo lunar, modulo de servico, modulo de comando e sistema de escape de lancamento. Medidas e empuxos conferidos na secao 16.1.
- Hotspots em cada estagio e em cada motor: o que faz, propelentes, empuxo, quando se separa.
- **Modulo de comando Apollo** em vitrine: exterior detalhado; na demo, o interior pode ser visto pela escotilha (camera entra num ponto fixo com os paineis iluminados).
- **Linha do tempo da Apollo 11** num painel longo: preparacao, lancamento, viagem, alunissagem, caminhada, retorno. Cada etapa clicavel.
- **Apollo Treasures** (Depois): vitrines de artefatos, cada um rotulado como **original, replica ou reconstrucao digital**. No Roblox quase tudo e reconstrucao digital: diga isso na placa.
- **Diorama do show de lancamento** (secao 6).

### 4. Space Shuttle Atlantis e Hubble (Demo: Atlantis; Hubble depois)
- Atlantis inclinado, elevado, com as portas do compartimento de carga abertas e o braco robotico estendido, como na exposicao real: **inclinado a 43,21 graus**, portas do compartimento abertas "para parecer como estava no espaco" (KSC-2012-6314), braco robotico Canadarm instalado e estendido (KSC-2013-2877). Orbitador: **37,2 m** (122 pes) de comprimento, **23,8 m** (78 pes) de envergadura, **17,4 m** (57 pes) de altura na pista (nasa.gov/reference/the-space-shuttle).
- Interacoes: abrir/fechar portas do compartimento (animacao), ver o braco robotico, hotspots (bocal dos motores, telhas termicas, asas, cauda, cabine).
- Cabine (Depois): ponto de camera fixo dentro, com paineis principais explicados.
- Hubble ao lado, em escala real: a exposicao real tem uma maquete do Hubble em tamanho real e um modelo em tamanho real de parte da ISS (KSC-2012-6314). Atlantis levou a missao de manutencao do Hubble STS-125 (maio de 2009; fonte s125e009990, que mostra astronautas no braco robotico do Atlantis).

### 5. Memorial (Demo, simples e respeitoso)
- Apollo 1, Challenger, Columbia: nomes das tripulacoes, data, o que aconteceu, a licao de engenharia que ficou.
- Nada interativo alem de ler. Sem musica ou com silencio. Luz baixa e quente.

### 6. Marte (Depois; na demo, um rover em exposicao)
- Curiosity ou Perseverance em escala real, Ingenuity ao lado.
- Painel "atraso de comunicacao Terra-Marte" (explica por que rovers sao semiautonomos). Os minutos de atraso **(nao verificado)**: nao achei o numero numa pagina oficial da NASA; nao exibir ate confirmar.
- Simulacao de rover: Depois.

### 7. Exploracao moderna (Depois; na demo, ao menos Artemis/Orion)
- ISS (modelo de parte da estacao em tamanho real, como no complexo real, ou modelo reduzido rotulado como tal), James Webb (espelho dourado), SLS e Orion (Artemis).

### 8. Parede de missoes (Demo)
Ver secao 7.

---

## 5. Experiencia de interacao

### 5.1 Aproximar e examinar
- `ProximityPrompt` em cada exposicao: texto "Examinar" + nome do objeto ("Examinar Saturn V"). No celular vira botao tocavel automaticamente.
- `MaxActivationDistance` vem dos dados da exposicao (objeto enorme = distancia maior). `RequiresLineOfSight = false` em objetos grandes.
- Um prompt por vez na tela; prompts discretos (estilo padrao, sem cores berrantes).

### 5.2 Painel de exposicao (UI)
Ocupa a lateral direita no PC (~40% da largura) e a metade de baixo no celular. O mundo continua visivel.

```
+-------------------------------------+
| SATURN V                     [X]    |
| Programa Apollo  |  1967-1973  (*)  |
|-------------------------------------|
| [ imagem ou visualizacao 3D ]       |
|-------------------------------------|
| Historia (texto curto, 3-5 linhas)  |
| Dados tecnicos (tabela)             |
| Voce sabia? (curiosidade)           |
|-------------------------------------|
| [Ver componentes] [Ouvir] [Fontes]  |
| Reconstrucao digital | Foto: NASA   |
+-------------------------------------+
(*) datas so aparecem se Verificado
```

- Estilo de painel cientifico de museu: fundo azul-marinho translucido, texto branco, destaque laranja, cantos pouco arredondados, uma familia tipografica (ex.: `Enum.Font.Gotham`/`GothamBold` ou a equivalente atual em `Font.new`).
- Fechar: botao X, tecla Esc/E de novo, ou afastar-se alem da distancia do prompt.
- Abrir o painel registra "exposicao vista" no diario (secao 8).

### 5.3 Visualizacao de componentes
- **Hotspots:** cada componente e um `Attachment` dentro do modelo, com nome igual ao `Id` do componente nos dados. Ao clicar "Ver componentes", aparecem marcadores (`BillboardGui`) nesses attachments; tocar num marcador mostra nome, funcao, material, missao e curiosidade.
- **Vista de estagios** (Saturn V e foguetes do jardim): cada estagio e um submodelo; "Ver estagios" afasta os estagios ao longo do eixo com `TweenService` (tween de um `CFrameValue` aplicado com `PivotTo`), com rotulo em cada um. "Voltar" junta de novo. No Saturn V real os estagios ja ficam um pouco separados; a animacao so aumenta a separacao.
- **Camera de exame:** ao ver componentes, a camera passa para `Scriptable`, orbita o objeto (arrastar/deslizar gira, roda/pinca aproxima) e volta ao normal ao fechar. Respeitar a opcao "reduzir movimento de camera".

### 5.4 Audio-guia
- Botao "Ouvir" toca a narracao da exposicao, sempre com legenda na tela.
- Na demo, se ainda nao houver narracoes gravadas, o botao fica oculto (nao mostrar botao que nao faz nada).

---

## 6. Show de lancamento (Demo, o momento forte)

Inspirado na sala de controle de lancamento que antecede o salao do Saturn V real. Aqui fica **dentro do salao**, na ilha Apollo.

**Componentes:**
- Uma bancada de console de lancamento (paineis com luzes) diante de um telao.
- Um **diorama**: plataforma de lancamento com um Saturn V em escala reduzida (ex. 1:20), que decola de verdade dentro do diorama, com fumaca (`ParticleEmitter`) e fogo.
- O Saturn V de tamanho real, acima, acompanha: luzes sob cada estagio acendem na ordem da separacao.

**Sequencia (~90 s, roteirizada por dados em `Conteudo/Shows/LancamentoApollo.lua`):**
1. Jogador ativa o prompt "Assistir ao lancamento".
2. Luzes do salao caem (tween em `Lighting` so no cliente), console acende.
3. Apresentacao da missao no telao (texto + legenda).
4. Verificacao dos sistemas: luzes do console ficam verdes uma a uma, com falas de controle ("Go/No go") legendadas.
5. Contagem regressiva de 10, com som.
6. Ignicao e decolagem no diorama; vibracao leve de camera (desligavel).
7. Separacao do primeiro estagio, do segundo, insercao em orbita: a cada evento, o estagio correspondente do Saturn V real se ilumina e aparece um rotulo.
8. Luzes voltam. Painel final: "Isto e uma representacao educativa simplificada."

- O show e **local** (roda no cliente de quem ativou); outros jogadores nao sao afetados.
- Audio: efeitos e locucao proprios ou de dominio publico da NASA com credito. Audios historicos so se a fonte permitir.
- Pode ser interrompido a qualquer momento (botao "Sair do show").

---

## 7. Ligacao com o jogo: Parede de missoes

### 7.1 Parede de missoes (o album)
- Uma parede longa na ilha 8 com uma **vitrine por card**. Card bloqueado = silhueta escura com "?" e o nome da fase que o libera. Card conquistado = vitrine acende, mostra a maquete do satelite/nave (se houver modelo) e a foto real.
- Ao conquistar um card no jogo, a proxima vez que o jogador entra no museu a vitrine nova esta acesa e o robo aponta para ela ("Olha a sua missao aqui!").
- Painel do card (mesmo estilo da 5.2) com os campos do card: foto real da NASA (com credito), nome e ano da missao, para que serve, curiosidade, o que tem em comum com a missao do jogador.
- **Ligacao com as ilhas:** quando o card tem parente no salao (ex.: card LRO -> ilha Apollo/Lua; card James Webb -> ilha moderna), o painel do card tem um botao "Ver no museu" que mostra um caminho no chao ate a exposicao relacionada.
- As fases do jogo estao em redefinicao: a lista de cards vem de `Conteudo/Cards/` e cresce so nos dados. Cards atuais propostos (a confirmar com o time): Terra/Aqua, Landsat 9, LRO, TESS, Kepler, James Webb.

### 7.2 Como o jogador chega e sai do museu
- O museu **nao e o ponto de partida** do jogo e **nao tem Centro de Controle**: as missoes comecam no proprio jogo, fora do museu. Quem decide onde o jogador nasce e como ele vai ao museu e o time do jogo.
- O museu so oferece dois pontos de ligacao: um `SpawnLocation`/ponto de chegada na entrada (ilha 0), com `Neutral = false` para nao virar o spawn padrao, e um portal de saida na entrada que dispara `MuseuEventos.SairDoMuseu` (um `BindableEvent` no cliente). O time do jogo decide o que fazer com esse evento (teleportar de volta, abrir menu etc.).
- O museu **nao implementa o jogo**.

### 7.3 Contrato com o jogo (API no servidor)
```lua
-- ServerScriptService/Servicos/CardService
CardService.Desbloquear(player: Player, cardId: string) -> boolean
CardService.TemCard(player: Player, cardId: string) -> boolean
CardService.Listar(player: Player) -> {string}
```
- Valida que `cardId` existe em `Conteudo/Cards`. Desbloqueio e so no servidor; o cliente nunca pede "me de um card".
- Ao desbloquear, avisa o cliente (`Remotes.CardDesbloqueado`) e salva via `ProgressoService`.

---

## 8. Sistemas de visita

| Sistema | Demo? | O que faz |
|---|---|---|
| Visita livre | Demo | Padrao. Sem objetivos obrigatorios |
| Diario do visitante | Demo (simples) | Lista exposicoes vistas, cards, shows assistidos. Mostra "12 de 30 exposicoes". Nada de pontos ou ranking |
| Mapa do salao | Demo (simples) | Planta 2D com "voce esta aqui", nome das ilhas, icones das exposicoes vistas/nao vistas. Tecla M e botao no celular |
| Visita guiada pelo robo | Depois | Robo anda ate a proxima ilha, fala uma introducao, recomenda a proxima. Interrompivel |
| Simulacoes (Mercury, Apollo, Shuttle, rover) | Depois | Experiencias separadas, sempre rotuladas como simplificadas |
| Idiomas EN/ES | Depois | A estrutura ja nasce pronta (secao 9.3) |

### 8.1 Interface durante a visita
Minimalista: so o prompt quando perto de algo, e no canto superior direito tres icones (mapa, diario, configuracoes). Nada de barras permanentes.

### 8.2 Acessibilidade (Demo)
Em Configuracoes: tamanho do texto (3 niveis), legendas sempre ligadas por padrao, reduzir movimento de camera (desliga vibracao e orbita automatica), volume de ambiente e de narracao separados, desligar som ambiente. Contraste: texto branco sobre fundo escuro com opacidade suficiente.

---

## 9. Conteudo confiavel

### 9.1 Formato de uma exposicao
```lua
-- ReplicatedStorage/Conteudo/Exposicoes/SaturnV.lua
return {
	Id = "saturn_v",
	Ilha = "apollo",
	Nome = "Saturn V",
	Categoria = "Veiculo lancador",
	Programa = "Apollo",
	Periodo = "1967-1973",            -- Apollo 4 (7/11/1967) a Skylab 1 (14/5/1973), secao 16.1
	Tipo = "reconstrucao_digital",    -- "original" | "replica" | "reconstrucao_digital"
	Historia = "...",
	DadosTecnicos = {
		{ Rotulo = "Altura", Valor = "110,6 m" },      -- 363 pes, fonte 9903401
		{ Rotulo = "Diametro maximo", Valor = "10,1 m" },
		{ Rotulo = "Estagios", Valor = "3" },
	},
	Curiosidade = "...",
	Componentes = {
		{ Id = "s_ic", Nome = "S-IC (1o estagio)", Funcao = "...", Material = "...", Curiosidade = "..." },
		{ Id = "motor_f1_1", Nome = "Motor F-1", Funcao = "...", Propelentes = "...", Empuxo = "..." },
	},
	Interacoes = { "VerComponentes", "VerEstagios" },
	DistanciaPrompt = 40,                 -- studs
	Imagem = { AssetId = "rbxassetid://...", Credito = "NASA" },
	Fontes = {
		{ Titulo = "...", Url = "https://www.nasa.gov/..." },
	},
	Verificado = false,
	VerificadoPor = nil,                  -- nome de quem conferiu
}
```
Os textos ficam no proprio arquivo em portugues; para traducao, ver 9.3.

### 9.2 Validador
`Shared/ValidadorConteudo` roda no inicio do servidor e checa cada exposicao e card:
- Campos obrigatorios presentes e do tipo certo (`Id`, `Nome`, `Historia`, `Tipo`, `Fontes` com ao menos 1 URL, `Verificado`).
- `Id` unico; todo `Componentes[i].Id` tem `Attachment` correspondente no modelo; todo modelo com a tag `Exposicao` tem dados.
- Imagem sem `Credito` = erro.
- Resultado: exposicao invalida **nao recebe prompt** e gera `warn` claro no Output (`[Conteudo] saturn_v: falta Fontes`).
- `Config.MODO = "dev"` mostra exposicoes nao verificadas com uma faixa "NAO VERIFICADO". `Config.MODO = "demo"` esconde o painel de quem tem `Verificado = false` (o modelo continua no salao, so sem prompt).

### 9.3 Textos de interface
Todo texto de UI (botoes, menus, mensagens do robo) fica em `Conteudo/Textos/ptBR.lua`, acessado por chave (`Textos.get("painel.fechar")`). EN/ES depois sao outros arquivos com as mesmas chaves.

### 9.4 Fluxo de conteudo
O responsavel pelo conteudo (sem Studio) escreve e confere os arquivos de `Conteudo/` no git. Fontes preferidas: nasa.gov, NASA History Office (history.nasa.gov), images.nasa.gov (fotos, com credito), Smithsonian National Air and Space Museum. Fotos precisam ser enviadas ao Roblox como imagens (Creator Hub) e passam por moderacao: **envie cedo**.

---

## 10. Arte, modelos e ambientacao

### 10.1 Estilo "realista e limpo"
- Proporcoes e cores reais. Marcacoes dos veiculos como no real (bandeira, "USA", "NASA", nomes).
- Materiais do Roblox (`SmoothPlastic`, `Metal`, `DiamondPlate`, `Glass`, `Concrete`, `Fabric`) ou `MaterialVariant` proprios. Evite aparencia de plastico brilhante.
- **Paleta do edificio:** piso de concreto polido cinza, paredes cinza-escuras, estrutura metalica aparente, placas azul-marinho com texto branco e detalhe laranja. O edificio e neutro para os veiculos brilharem.

### 10.2 Unificar modelos de fontes diferentes
Todo modelo importado (pronto, de IA ou da Toolbox) passa por este checklist antes de entrar no salao:
1. **Apague todos os scripts** que vierem dentro do modelo (modelos da Toolbox costumam trazer scripts maliciosos).
2. Confira a licenca/origem e anote em `docs/modelos.md` (nome, fonte, licenca, quem importou). NASA 3D Resources (nasa3d.arc.nasa.gov / science.nasa.gov) e uma boa fonte de modelos oficiais.
3. Escala: ajuste com `Model:ScaleTo` ate bater a medida real via `Escala.metros`.
4. Materiais e cores trocados para a paleta e materiais do estilo (nada de texturas de outros estilos convivendo).
5. Malhas: respeite o limite de triangulos por `MeshPart` do Roblox (conferir o limite atual na documentacao); divida objetos grandes em partes. `RenderFidelity = Automatic`. `CollisionFidelity = Box` ou `Hull` em pecas que o jogador nao toca de perto.
6. Ancore tudo (`Anchored = true`), confira se nada flutua ou atravessa o piso.
7. Coloque os `Attachment` dos componentes (nome = `Id` nos dados) e a tag `Exposicao` + atributo `ExposicaoId` no modelo raiz.

### 10.3 Iluminacao
- `Lighting.Technology = Future` (no celular o Roblox reduz sozinho). `Atmosphere` leve no atrio.
- Salao em penumbra; **veiculos com luz de destaque** (`SpotLight`/`SurfaceLight`) vindo de baixo e dos lados. O Saturn V e iluminado por baixo ao longo do comprimento.
- Atrio de vidro com luz do dia. Memorial com luz baixa e quente.
- Evite dezenas de luzes com sombra: use sombras so nas principais.

### 10.4 Som
- Um `SoundGroup` para ambiente, outro para narracao, outro para efeitos (volume nas configuracoes).
- Zonas de som: partes invisiveis com a tag `ZonaAudio` e atributo `Ambiente` ("salao", "atrio", "memorial"). O cliente checa em que zona o personagem esta (poucas vezes por segundo) e faz crossfade.
- Salao: reverberacao de espaco grande, murmurio discreto, passos. Atrio: vento leve. Memorial: quase silencio.
- Sons proprios, do Creator Store com licenca, ou de dominio publico da NASA com credito.

### 10.5 Vida no salao (Depois)
NPCs visitantes discretos parados em pontos de observacao (sem pathfinding pesado), telas com loops de video/imagem, luzes de console piscando.

---

## 11. Arquitetura tecnica

### 11.1 Fluxo de trabalho
- **Rojo** sincroniza a pasta `src/` com o Studio. Codigo e conteudo vivem no git (GitHub), revisados la.
- **Team Create** para o mapa: salao, modelos, luzes, sons. O mapa nao vai para o Rojo (o projeto Rojo so mapeia pastas de codigo e conteudo, deixando `Workspace` livre).
- **MCP do Roblox Studio** (studio-rust-mcp-server, oficial da Roblox) para o Claude agir dentro do Studio: inserir pecas, rodar codigo, conferir o Output.
- Antes de editar um arquivo, `git pull`. Uma pessoa por vez mexe em cada sistema.

### 11.2 Estrutura de pastas (src/ -> Studio)
```
src/
  ReplicatedStorage/
    Shared/
      Config.lua              -- MODO, METROS_POR_STUD, Marca, limites
      Tipos.lua               -- tipos Luau das exposicoes e cards
      Utilidades/Escala.lua
      ValidadorConteudo.lua
    Conteudo/
      Exposicoes/*.lua
      Cards/*.lua
      Shows/LancamentoApollo.lua
      Textos/ptBR.lua
    Remotes/ (criados pelo servidor no boot)
  ServerScriptService/
    Servicos/
      ExposicaoService.lua    -- tags -> prompts, valida distancia, registra visita
      ProgressoService.lua    -- DataStore, cache, autosave
      CardService.lua         -- API para o jogo (7.3)
    Boot.server.lua
  StarterPlayer/StarterPlayerScripts/
    Controladores/
      InteracaoController.lua
      PainelController.lua    -- painel de exposicao e de card
      ComponentesController.lua -- hotspots, estagios, camera de exame
      ShowController.lua
      AudioController.lua
      MapaController.lua
      DiarioController.lua
      ConfigController.lua
    UI/                        -- construtores de UI em codigo, um por tela
    Boot.client.lua
```

### 11.3 Servidor x cliente
- **Servidor:** cria remotes, le tags (`CollectionService`) e cria os `ProximityPrompt`s, valida distancia quando um prompt e acionado (`ProximityPrompt.Triggered` ja chega no servidor com o player), registra progresso, desbloqueia cards, salva.
- **Cliente:** UI, camera, shows, luz local, audio, hotspots.
- O cliente nunca grava progresso direto; so o servidor, a partir de eventos que ele mesmo validou.

### 11.4 Persistencia (ProgressoService)
- `DataStoreService:GetDataStore("Progresso_v1")`, chave `"jogador_" .. UserId`.
- Dados: `{ versao = 1, exposicoesVistas = {[id]=true}, cards = {[id]=true}, showsVistos = {...}, config = {texto=..., legendas=..., reduzirMovimento=..., volumes=...}, primeiraVisita = bool }`.
- Carrega ao entrar (com `pcall` e ate 3 tentativas com espera); mantem cache em memoria; salva com `UpdateAsync` a cada ~60 s se houve mudanca, no `PlayerRemoving` e no `game:BindToClose`. Nunca salvar a cada movimento.
- Se o carregamento falhar, o jogador entra com progresso vazio marcado como "nao salvar" e recebe aviso discreto (para nao sobrescrever dados bons).
- No Studio, ligar "Enable Studio Access to API Services" para testar.

### 11.5 Desempenho
- `Workspace.StreamingEnabled = true`. O salao e um so espaco, entao: Saturn V e Atlantis com `ModelStreamingMode = Persistent` (sao vistos de longe); exposicoes pequenas `Atomic`.
- Meta: 60 fps num PC medio e jogavel (30+ fps) num celular medio. Teste com o emulador de dispositivo do Studio e, antes da demo, num celular real.
- Reaproveitar malhas (os 5 F-1 sao a mesma malha), poucas luzes com sombra, particulas so durante o show.
- Ferramentas: MicroProfiler (Ctrl+F6) e Developer Console (F9) para medir.

### 11.6 Controles
- PC: WASD, mouse, E para prompt, M mapa, Esc fecha.
- Celular: joystick padrao do Roblox, prompts tocaveis, botoes de mapa/diario/config grandes (minimo ~44 px), painel em baixo.
- Gamepad: o `ProximityPrompt` ja suporta; nao e prioridade.

---

## 12. Ordem de construcao (marcos)

Cada marco so termina quando os criterios dele passam no Studio. **M0 a M6 sao a demo dos jurados.** M7 em diante, se der tempo.

| Marco | Entrega | Pronto quando |
|---|---|---|
| M0 Base | Projeto Rojo, pastas, Config, Escala, Validador, ProgressoService, Boot | Studio sincroniza; validador acusa um arquivo de teste quebrado; progresso salva e volta ao reentrar |
| M1 Salao em greybox | Salao em blocos simples na escala certa, atrio, ilhas marcadas, Saturn V de placeholder (cilindros no tamanho real), iluminacao base | Andar do 0 ao 8 sem travar; o "uau" da entrada ja funciona so com volumes e luz; celular roda |
| M2 Saturn V completo | Modelo final, estagios, motores, hotspots, painel, vista de estagios | Todos os componentes abrem conteudo; vista de estagios anima e volta; sem erros no Output |
| M3 Painel e linha do tempo | Sistema de painel generico, Mercury, linha do tempo Apollo 11, CM Apollo, memorial | Nova exposicao entra so com dados + tag; textos verificados aparecem, nao verificados nao (modo demo) |
| M4 Atlantis | Modelo, portas do compartimento animadas, braco robotico, hotspots | Abre/fecha sem atravessar pecas; legivel no celular |
| M5 Parede de missoes | Vitrines, silhuetas, CardService, botao "Ver no museu", ponto de chegada e portal de saida (7.2) | `CardService.Desbloquear` pela linha de comando do Studio acende a vitrine e salva |
| M6 Show de lancamento | Console, diorama, sincronia com o Saturn V real, audio e legendas | Show completo sem falha 5 vezes seguidas; "sair do show" funciona em qualquer ponto |
| M7 Ilhas restantes | Jardim de foguetes, Marte, Moderna, Hubble | Mesmo criterio da 11.5 e 9.2 |
| M8 Polimento | Audio por zonas, mapa, diario, configuracoes de acessibilidade, robo na recepcao | Checklist da secao 13 inteiro |
| M9+ Depois | Visita guiada, simulacoes, cabines internas, NPCs, EN/ES | Cada um com criterio proprio |

---

## 13. Criterios de aceitacao da experiencia (checklist final)

- [ ] Ao entrar, o Saturn V esta no campo de visao em ate 5 segundos.
- [ ] Toda exposicao com prompt abre conteudo completo; nenhum painel vazio.
- [ ] Toda janela fecha (X, Esc, afastar-se) no PC e no celular.
- [ ] Nenhum texto exibido sem `Verificado = true` no modo demo; toda imagem tem credito.
- [ ] Nada flutuando, nada atravessando o piso, nenhuma exposicao inacessivel por colisao.
- [ ] Output sem erros vermelhos durante um percurso completo.
- [ ] Progresso (exposicoes, cards, configuracoes) volta ao sair e entrar.
- [ ] Show de lancamento sem falha 5 vezes seguidas.
- [ ] 30+ fps no celular de teste durante o show.
- [ ] Legendas em toda fala; movimento de camera desligavel.
- [ ] Toda simulacao/animacao marcada como representacao educativa simplificada.

---

## 14. Chamadas de quem escreveu este spec (o time pode mudar)

- Atrio de vidro para o jardim de foguetes (o Rocket Garden real e ao ar livre; aqui fica dentro do salao unico).
- Show de lancamento com diorama + iluminacao do Saturn V real, em vez de video.
- Robo do jogo como guia e anfitriao do museu.
- Catracas, bilheteria, estacionamento, banheiros e loja do spec antigo foram cortados.
- Cada jogador ve shows e paineis sozinho, mesmo com outros no servidor.
- `METROS_POR_STUD = 0.28` como ponto de partida, confirmado no greybox.
- Dimensoes do salao sao estimativa para o greybox.

## 15. Em aberto (decidir com o time)

- Nome do robo e do jogo (provisorios).
- Lista final de fases e cards (fases em redefinicao).
- Confirmacao com o Local Lead sobre o uso do logo da NASA na marca do jogo.
- Quais modelos prontos o time ja tem (listar em `docs/modelos.md` para saber o que falta modelar).

---

## 16. Fontes oficiais conferidas (14/11/2026)

Todas as fontes abaixo sao bases oficiais da NASA. Para abrir uma fonte: `https://images.nasa.gov/details/<ID>` (ou a URL indicada). As descricoes oficiais em ingles estao na propria pagina de cada ID.

### 16.1 Dados conferidos

| Dado | Valor oficial | Fonte NASA |
|---|---|---|
| Altura do Saturn V | 363 pes (110,6 m) | 9903401, 6404597 |
| Estagio S-IC | 138 pes (42,1 m) x 33 pes (10,1 m); 5 motores F-1; oxigenio liquido + querosene; mais de 7.500.000 libras-forca de empuxo | 9903033, 0100982 |
| Motor F-1 | 19 pes (5,8 m) de altura, 12,5 pes (3,8 m) na saida do bocal; 1.500.000 libras-forca cada; o S-IC queimava 15 t de propelente por segundo | 6862832 |
| Estagio S-II | 5 motores J-2, 200.000 libras-forca cada; hidrogenio liquido + oxigenio liquido | 9801770, 6778744 |
| Estagio S-IVB | 59 pes (18 m) x 22 pes (6,7 m); 1 motor J-2 | 0600309, 6757797 |
| Unidade de instrumentos | 3 pes (0,9 m) de altura x 21 pes (6,4 m) de diametro, entre o S-IVB e a nave; feita pela IBM | 0100984 |
| Nave Apollo | modulo lunar, modulo de servico, modulo de comando e sistema de escape | 0100985 |
| Primeiro voo do Saturn V | Apollo 4, 7/11/1967 | 9903407 |
| Ultimo voo do Saturn V | Skylab 1, 14/5/1973 | S73-23918 |
| Apollo/Saturn V Center | ~100.000 pes2; Saturn V restaurado de 363 pes, antes exposto perto do VAB | KSC-98pc1004 |
| Apollo 11: lancamento | 16/7/1969, 8h32 CDT, plataforma 39A; Armstrong (comandante), Collins (piloto do modulo de comando), Aldrin (piloto do modulo lunar) | 6901001 |
| Apollo 11: caminhada | 20/7/1969 | as11-40-5902 |
| Apollo 11: amerissagem | 24/7/1969, 11h49 CDT, modulo de comando Columbia | 372772main_GPN-2000-001212_full |
| Orbitador do onibus espacial | 122 pes (37,2 m) x 78 pes (23,8 m) de envergadura x 57 pes (17,4 m) de altura na pista | https://www.nasa.gov/reference/the-space-shuttle/ |
| Exposicao do Atlantis | inclinado a 43,21 graus, portas do compartimento abertas; predio de 90.000 pes2; maquete do Hubble em tamanho real; modelo de parte da ISS em tamanho real | KSC-2012-6314 |
| Canadarm no Atlantis | braco robotico instalado e estendido | KSC-2013-2877, KSC-2013-2587 |
| Carreira do Atlantis | 33 missoes, 307 dias no espaco, 125.935.769 milhas | KSC-2012-6314 |
| Sputnik | lancado pela URSS em 4/10/1957 | 9248168 |
| Explorer 1 | primeiro satelite dos EUA, num Jupiter-C (Juno I), 31/1/1958 | 6414025, 0102332 |
| Mercury Seven | escolhidos pela NASA em 27/4/1959 | 8772556 |
| Freedom 7 | Alan Shepard, primeiro astronauta americano, voo suborbital, 5/5/1961 | 6100884 |
| Friendship 7 | John Glenn, Mercury-Atlas 6, 20/2/1962 | KSC-S63-01207 |
| Rocket Garden | oito foguetes autenticos, incluindo um Mercury-Atlas; replicas de capsulas Mercury, Gemini e Apollo (foto de 2003) | KSC-03pd2174 |
| Apollo 1 | tripulacao: Virgil "Gus" Grissom, Edward H. White II, Roger B. Chaffee | KSC-07PD-0183 |
| Space Mirror Memorial | memorial aos astronautas no KSC Visitor Complex | KSC-07PD-0181 |
| Columbia STS-107 | retrato oficial dos sete tripulantes | 0300309 |

### 16.2 Ainda nao verificado em fonte oficial (nao exibir ate confirmar)
- Lista completa e atual dos foguetes do Rocket Garden (a fonte oficial e de 2003).
- Disposicao exata do Saturn V no salao real (altura, espacamento dos estagios): tirar das fotos.
- Atraso de comunicacao Terra-Marte em minutos.
- Retrato oficial da tripulacao do Challenger (STS-51L): procurar em images.nasa.gov por "51-L crew"; **nao usar foto do acidente**.
- Textos dos cards (ano, para que serve, curiosidade): conferir na pagina oficial de cada missao (science.nasa.gov) antes de escrever.

### 16.3 Fotos reais escolhidas (images.nasa.gov)

Regras:
- **So fotos reais de bancos de dados oficiais da NASA** (images.nasa.gov / images-api.nasa.gov, photojournal.jpl.nasa.gov). Nada gerado por IA, nada de sites de terceiros.
- Guarde o ID e o credito exatos de cada foto em `Imagem = { NasaId = "...", Credito = "..." }` no arquivo de conteudo. Credito: o campo de fotografo/credito da pagina oficial; quando vazio, "NASA".
- Algumas fotos JPL tem credito compartilhado (ex.: "NASA/JPL-Caltech/MSSS"); copie o credito inteiro.
- Para buscar mais: `https://images-api.nasa.gov/search?media_type=image&q=<termo>`; para os dados de uma foto: `https://images-api.nasa.gov/search?nasa_id=<ID>`.
- Baixe a maior resolucao, envie ao Roblox (Creator Hub) e anote o `rbxassetid` ao lado do `NasaId`.

| Exposicao | Foto | ID | Credito |
|---|---|---|---|
| Saturn V (salao real) | Visitantes sob os motores do Saturn V em exposicao | KSC-99pp1144 | NASA |
| Saturn V (salao real) | Vista aerea do Apollo/Saturn V Center | KSC-98pc1004 | NASA |
| Saturn V | Lancamento da Apollo 11 | 6901001 | NASA |
| Motor F-1 | Motor F-1 completo, com medidas | 6862832 | NASA |
| S-IC | Corte do primeiro estagio com componentes | 9903033 | NASA |
| Apollo 11 | Aldrin caminha perto da perna do modulo lunar | as11-40-5902 | NASA |
| Apollo 11 | Terra nascendo sobre a Lua | as11-44-6550 | NASA |
| Apollo 11 | Modulo de comando Columbia apos a amerissagem | 372772main_GPN-2000-001212_full | NASA |
| Mercury | Lancamento do Freedom 7 (Mercury-Redstone) | 6100884 | NASA |
| Mercury | Glenn entra na Friendship 7 | KSC-S63-01207 | NASA |
| Mercury | Glenn olha a Terra pela janela da Friendship 7 | KSC-JohnGlenn-0008 | NASA |
| Mercury Seven | Retratos oficiais (Shepard, Cooper, Schirra, Grissom...) | 8772553, 8772556, 8892072, 8772558 | NASA |
| Corrida espacial | Texto oficial sobre o Sputnik e a equipe de von Braun | 9248168 | NASA |
| Juno I / Explorer 1 | Explorer 1 sobre o Jupiter-C | 6414025 | NASA |
| Gemini-Titan II | Lancamento do Gemini-Titan II n. 1 | S64-21560 | NASA |
| Rocket Garden | Vista do Rocket Garden | KSC-03pd2174 | NASA |
| Rocket Garden | Vista aerea do Rocket Garden | KSC-2009-3194 | NASA/Kim Shiflett |
| Atlantis | Atlantis sendo inclinado para exposicao | KSC-2012-6314 | NASA/Dimitri Gerondidakis |
| Atlantis | Compartimento de carga aberto | KSC-2013-2317 | NASA/Kim Shiflett |
| Atlantis | Canadarm instalado e estendido | KSC-2013-2877 | NASA |
| Hubble | Astronautas do STS-125 no braco robotico durante caminhada | s125e009990 | NASA |
| Memorial | Space Mirror Memorial | KSC-07PD-0181 | NASA |
| Memorial | Tripulacao da Apollo 1 (retrato oficial) | S66-30236 | NASA |
| Memorial | Tripulacao do Columbia STS-107 (retrato oficial) | 0300309 | NASA |
| Marte | Selfie do Curiosity em Buckskin | PIA19808 | NASA/JPL-Caltech/MSSS |
| Marte | Cratera Jezero vista pelo Perseverance | PIA24745 | NASA/JPL-Caltech/ASU/MSSS |
| Marte | Modelo de voo do Ingenuity | PIA23882 | NASA/JPL-Caltech |
| Moderna | Espelho primario do Webb montado | GSFC_20171208_Archive_e000422 | NASA |
| Moderna | SLS e Orion do Artemis I na plataforma 39B | KSC-20220915-PH-JNP01_0001 | NASA/Jason Parrish |
| Moderna | ISS com a Terra ao fundo | iss020e005813 | NASA |
| Card Terra | Queimadas na Amazonia vistas pelo Terra | PIA23546 | NASA/JPL-Caltech/Earth Observatory |
| Card Aqua | Aqua em orbita (ilustracao oficial) | PIA18156 | NASA |
| Card Landsat 9 | Atlas V com o Landsat 9 antes do lancamento | NHQ202109260004 | NASA/Bill Ingalls |
| Card LRO | LRO sendo preparado antes do voo | KSC-2009-2994 | NASA |
| Card TESS | Modelo do TESS e lente de camera reserva | NHQ201803280022 | NASA/Bill Ingalls |
| Card Kepler | Modelo do Kepler numa coletiva | 200902190007HQ | NASA/Paul E. Alers |

Observacao: PIA18156 (Aqua) e ilustracao oficial da NASA, nao foto; o painel deve dizer "Ilustracao: NASA".

