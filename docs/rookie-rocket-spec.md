# SPEC.md — Rookie Rocket (Roblox / Luau)
**Evento:** NASA Space Apps Challenge 2026 — *Space Mission Design Game*  
**Engine / Linguagem:** Roblox Studio / Luau (Arquitetura Client-Server Autoritativa)  
**Público-alvo:** Adolescentes (Educativo / Simulação Cooperativa)  
**Guia NPC:** Marcos Pontes (falas fictícias didáticas; fotos e fatos históricos exclusivamente de fontes oficiais da NASA liberadas pelo evento).

> **REGRA FIXA DE CRÉDITOS E TRANSPARÊNCIA:**  
> Todos os pesos, tempos, velocidades e efeitos de equipamentos são **valores didáticos simplificados** para fins de jogabilidade e aprendizado. Essa informação deve estar explicitamente visível na tela de Créditos do jogo.

---

## 1. Visão Geral e Pilares de Arquitetura

1. **Free-Roam Interior (Livre Movimentação):** O jogador **não** fica preso a assentos. Durante toda a missão, os jogadores caminham livremente pelo interior da nave/estação (com gravidade simulada/botas magnéticas ou flutuação EVA na Missão 2), deslocando-se fisicamente entre painéis, pranchetas, escotilhas e janelas.
2. **Janelas Panorâmicas e Observação Espacial:** Naves construídas com escotilhas amplas (`Material = Glass`) e skybox espacial dinâmica, permitindo observar a Terra, estrelas em rotação, plasma de reentrada e módulos externos em tempo real.
3. **Multiplayer Cooperativo (1 a 4 Jogadores):** A missão pode ser jogada Solo ou em Co-op. Em Co-op, a equipe compartilha o limite de peso do foguete, o inventário da nave e colabora simultaneamente nas estações de trabalho.
4. **Autoridade Total no Servidor:** O cliente apenas renderiza interfaces, efeitos de câmera e envia intenções de ação (`RemoteEvent`). O servidor valida pesos, controla cronômetros, calcula estrelas e salva dados no `DataStoreService`.

---

## 2. Fluxo Geral da Missão e Regras de Peso

### 2.1. Pipeline de Execução
```text
[Embarque na Nave (1–4 Jogadores)]
       │
       ▼
[Tela: Preparação da Missão (Sincronizada em Co-op)]
       │  └─ Seleção de Equipamentos (até 2 itens) + Barra de Peso ao Vivo
       ▼
[Botão: LANÇAR] ──(Peso Total > 60 kg)──► [FALHA IMEDIATA: Fala do Marcos Pontes]
       │ (Peso Total <= 60 kg)
       ▼
[Task 1] ──► [Task 2] ──► [Task 3] ──► [Tela de Resultado + Estrelas + Card NASA + Álbum]
   │            │            │
   └──(Falha)───┴──(Falha)───┴──► [Diálogo Explicativo do Marcos Pontes]
                                    ├─ [Tentar a task de novo] (zera tempo da task, mantém itens)
                                    └─ [Recomeçar a missão] (volta à Preparação, libera troca de itens)
```

### 2.2. Sistema de Peso e Bônus de Leveza
* **Peso Base da Nave:** `20 kg`
* **Limite Máximo do Foguete:** `60 kg`
* **Capacidade Útil para Equipamentos:** `40 kg` (compartilhada entre todos os jogadores na nave)
* **Equipamentos por Missão:** 3 opções com pesos fixos de `15 kg`, `20 kg` e `25 kg`.
  * *Nota de design:* `20 kg (nave) + 20 kg + 25 kg = 65 kg` (inválido) e `20 + 15 + 20 + 25 = 80 kg` (inválido). Portanto, a equipe só pode levar **no máximo 2 equipamentos** (especificamente `15 + 20 = 55 kg` ou `15 + 25 = 60 kg`), ou apenas 1 item para maximizar o bônus de leveza.
* **Barra de Peso ao Vivo (UI Preparação):**
  * `<= 50 kg`: **Verde**
  * `51 a 60 kg`: **Amarela**
  * `> 60 kg`: **Vermelha** (o botão **Lançar** permanece clicável para permitir o erro didático)
  * **Texto lateral:** `"Peso {X} / 60 kg · Livre {60 - X} kg"`
* **Bônus de Leveza:**
  $$\text{BonusLeveza} = \left\lfloor \frac{60 - \text{PesoTotal}}{10} \right\rfloor \times 2 \text{ segundos}$$

---

## 3. Sistema de Pontuação e Estrelas

Cada task possui um cronômetro independente no servidor que corre apenas enquanto a task está ativa (incluindo o tempo de caminhada dos jogadores dentro da nave).

$$\text{TempoFinal} = \max(0, \; T_1 + T_2 + T_3 - \text{BonusLeveza})$$

| Tempo Final | Recompensa | Status |
| :--- | :--- | :--- |
| `<= 45 s` | ⭐⭐⭐ | Missão Concluída (Ouro) |
| `46 s` a `70 s` | ⭐⭐ | Missão Concluída (Prata) |
| `71 s` a `100 s` | ⭐ | Missão Concluída (Bronze) |
| `> 100 s` | `0 estrelas` | **Falha:** *"Demorou demais"* |

* **Formato obrigatório na tela de resultado:**  
  `"T1 12 s + T2 18 s + T3 15 s − 4 s de leveza = 41 s · ⭐⭐⭐"`

---

## 4. Especificação das Missões (Level Design, Tasks e Co-op)

### 4.1. Missão 1 · Projeto Mercury (Friendship 7 / Aurora 7)

#### Ambiente e Navegação
* **Cenário:** Interior navegável de cápsula espacial ampliada para escala de movimentação livre (1–4 jogadores), dividida em 3 estações físicas:
  1. **Painel Frontal & Periscópio** (com janela panorâmica ampla frontal).
  2. **Janela Lateral & Mesa de Navegação** (onde fica a prancheta física com o código).
  3. **Console de Rádio & Retropack** (painel de comunicação e alavancas/botões de reentrada).
* **Efeitos Visuais Externos (Janelas):**
  * *Task 1:* Skybox/estrelas girando em alta velocidade fora das janelas; iluminação interna vermelha pulsante.
  * *Task 3:* Efeito de partículas e brilho laranja/vermelho intenso (plasma de reentrada atmosférica) passando pelas janelas.

#### Equipamentos da Missão 1
| Equipamento | Peso | Task Alvo | Efeito Mecânico |
| :--- | :--- | :--- | :--- |
| **Giroscópio** | `15 kg` | Task 1 | Reduz o tempo de segurar a mira em cada ponto: `2.0 s` → `1.2 s` |
| **Manual de Bordo** | `20 kg` | Task 2 | Destaca visualmente o código na prancheta e adiciona `+15 s` ao timer (`30 s` → `45 s`) |
| **Escudo Reforçado** | `25 kg` | Task 3 | Reduz o tempo segurando "Manter Retropack": `10.0 s` → `6.0 s` e reduz o tremor da câmera |

#### Tasks da Missão 1
* **Task 1 · O Colapso do Piloto Automático**
  * **Alerta:** `"FALHA NO SISTEMA AUTOMÁTICO"` + tremor leve de câmera.
  * **Mecânica:** O jogador caminha até as janelas panorâmicas (ou ativa o visor manual sem travar o movimento), centraliza a mira (`+`) sobre **4 pontos vermelhos** externos à nave e segura até o círculo radial completar (`2.0 s` base / `1.2 s` com Giroscópio).
  * **Co-op:** Múltiplos jogadores podem olhar por janelas diferentes e travar pontos simultaneamente.
  * **Falha:** Ultrapassar `40 s`.

* **Task 2 · O Blackout de Comunicação**
  * **Alerta:** `"PERDA DE CONTATO COM A TERRA"` + áudio de estática/chiado no rádio.
  * **Mecânica:** O jogador anda até a mesa de navegação para ler um código gerado aleatoriamente na prancheta física (destacado em amarelo se o *Manual de Bordo* estiver equipado) e digita esse código no painel do rádio. Ao lado do teclado, um botão vermelho **"EJETAR CÁPSULA"** pisca constantemente.
  * **Feedback de Acerto:** Estática cessa e toca o áudio/legenda: *"Friendship 7, we read you. Welcome back."*
  * **Co-op:** Um jogador fica lendo a prancheta enquanto outro já está no painel de rádio digitando o código.
  * **Falha:** Clicar em **"EJETAR CÁPSULA"** ou o timer expirar (`30 s` base / `45 s` com Manual). Digitar código errado exibe apenas `"Código inválido"` e não causa falha.

* **Task 3 · O Alarme do Escudo Térmico**
  * **Alerta:** `"PERIGO: SENSOR DO ESCUDO TÉRMICO INSTÁVEL"` + timer de decisão de `10 s`.
  * **Mecânica:** O jogador corre até o console de reentrada onde há dois botões físicos/UI: **"EJETAR CÁPSULA"** (vermelho) e **"MANTER RETROPACK"** (verde). Ao escolher *Manter*, a cabine ganha tom vermelho de calor, treme, e o jogador deve segurar o botão até a barra encher (`10 s` base / `6 s` com Escudo). Soltar o botão apenas pausa o progresso (não falha).
  * **Co-op:** Se dois ou mais jogadores segurarem os botões redundantes simultaneamente, a trepidação visual é reduzida.
  * **Falha:** Clicar em **"EJETAR CÁPSULA"** ou não tomar nenhuma decisão dentro dos `10 s` iniciais.

---

### 4.2. Missão 2 · Estação Espacial Internacional (ISS)

#### Ambiente e Navegação
* **Cenário:** Módulo habitável da ISS conectado diretamente à **Cupola** (cúpula com 7 janelas panorâmicas voltadas para a Terra) e uma **Airlock** funcional para caminhada espacial (EVA).
* **Efeitos Visuais Externos:** Visão orbital da Terra iluminada, painéis solares externos e os módulos *Unity* e *Zarya* visíveis em tempo real pelas janelas da Cupola.

#### Equipamentos da Missão 2
| Equipamento | Peso | Task Alvo | Efeito Mecânico |
| :--- | :--- | :--- | :--- |
| **Sensor de Pressão** | `15 kg` | Task 1 | Aumenta em `+50%` o tamanho da zona verde no slider de pressão |
| **Luvas Aderentes** | `20 kg` | Task 2 | Permite arrastar os cabos soltos `2x` mais rápido sem escorregar |
| **Kit de Vedação** | `25 kg` | Task 3 | Reduz a velocidade de queda de pressão em `40%` e reduz o tempo de vedação: `3.0 s` → `2.0 s` |

#### Tasks da Missão 2
* **Task 1 · O Acoplamento (Unity & Zarya, STS-88, 1998)**
  * **Alerta:** `"PRESSÃO DO BRAÇO EXCESSIVA"`.
  * **Mecânica:** Dentro da Cupola, olhando os módulos tortos pelas janelas, o jogador interage com o console do braço robótico (`Canadarm`): alinha **4 esferas** sobre **4 alvos (`X`)** e ajusta um **slider de pressão** para mantê-lo dentro da zona verde. Ao completar, toca um `"clack"` mecânico, luzes ficam verdes e os módulos travam externamente.
  * **Co-op:** Um jogador alinha as 4 esferas enquanto outro regula exclusivamente o slider de pressão.
  * **Falha:** Manter a pressão no máximo por `3 s` contínuos (colisão entre módulos) ou ultrapassar `40 s` (módulo Zarya deriva para longe).

* **Task 2 · O Painel Solar Preso (STS-97, 2000)**
  * **Mecânica:** Caminhada espacial (EVA). Os jogadores saem pela Airlock para o exterior da estação (flutuação 3D livre com propulsores suaves e cabo de segurança visual) com a Terra ao fundo. Existem **2 cabos soltos** flutuando; o jogador deve arrastar cada cabo até sua respectiva polia (círculo verde). Se arrastar rápido demais (acima do limite), o cabo escorrega e volta à posição original (sem dar Game Over).
  * **Co-op:** Cada jogador assume um dos cabos e o conduz até a polia simultaneamente.
  * **Falha:** Ultrapassar `45 s`.

* **Task 3 · O Vazamento de 2 mm (Soyuz MS-09, 2018)**
  * **Mecânica:** Alarme sonoro, luzes vermelhas de emergência, som de ar escapando e ponteiro de pressão da cabine caindo continuamente. Sequência obrigatória:
    1. Correr até a escotilha do módulo adjacente e fechá-la via `ProximityPrompt` (reduz a taxa de perda de ar).
    2. Localizar o furo de 2 mm na parede (identificado por partículas de ar sendo sugadas).
    3. Coletar a **"Gaze com Epóxi"** na caixa de ferramentas e segurar o clique sobre o furo (`3.0 s` base / `2.0 s` com Kit de Vedação).
  * **Co-op:** Um jogador corre imediatamente para fechar a escotilha enquanto outro já busca a Gaze com Epóxi e localiza o vazamento.
  * **Falha:** A pressão da cabine atingir `0%`.

---

## 5. Sistema Pedagógico: Diálogos do Marcos Pontes

Toda falha interrompe a partida imediatamente e exibe o modal do NPC **Marcos Pontes** contendo:
1. O que ocorreu tecnicamente;
2. O paralelo com o evento histórico real da NASA;
3. Uma única dica objetiva vinculada aos equipamentos escolhidos.

### Tabela de Gatilhos e Falas
| Gatilho de Falha | Texto do Marcos Pontes |
| :--- | :--- |
| **Peso > 60 kg no Lançamento** | `"{nome}, o foguete só leva 60 kg e a nave estava com {peso} kg. Ele nem saiu da plataforma! Na engenharia espacial cada quilo conta: escolham juntos apenas o que mais ajuda."` |
| **Ejetar na Task 2 (Missão 1)** | `"Ejetar durante a reentrada seria fatal. O John Glenn ficou 4 minutos sem rádio e confiou no treinamento. Às vezes a resposta certa é manter a calma e seguir o procedimento."` |
| **Ejetar na Task 3 (Missão 1)** | `"Era um erro do sensor! O escudo estava preso. Quem ejeta no pânico perde a missão. Manter o retropack foi a decisão real da NASA."` |
| **Pressão Máxima na Task 1 (Missão 2)** | `"Força demais amassa o módulo! Na STS-88, a solução foi aliviar a pressão do braço, não apertar mais."` |
| **Tempo / Pressão Zerada (Sem o item da task)** | `"Faltou tempo, {nome}. O {equipamento} teria ajudado justamente aqui. Na próxima, conversem e decidam qual task é mais difícil para a equipe."` |
| **Tempo / Pressão Zerada (Com o item da task)** | `"Quase lá, {nome}! Mesmo com o {equipamento}, o tempo apertou. Dividam melhor as estações na nave e tentem novamente."` |
| **Sucesso na Missão** | `"Excelente trabalho, equipe! Vocês tomaram decisões de verdadeiros astronautas da NASA. Confira o registro histórico dessa missão no seu álbum!"` |

---

## 6. Arquitetura de Arquivos e Padrões de Código (Luau)

Todos os scripts devem conter comentários claros em **português** para facilitar a manutenção por programadores iniciantes da equipe.

```text
ReplicatedStorage/
 ├── Config/
 │    └── Missoes.lua                 -- ModuleScript ÚNICO com todas as constantes, pesos, timers, estrelas e falas
 └── Remotes/
      ├── SelecionarEquipamento       -- RemoteEvent (Client -> Server)
      ├── IniciarLancamento           -- RemoteEvent (Client -> Server)
      ├── AcaoTask                    -- RemoteEvent (Client -> Server: progresso de pontos, código, escotilha, etc.)
      ├── ReiniciarTaskOuMissao       -- RemoteEvent (Client -> Server: modo "Task" ou "Missao")
      └── SincronizarEstado           -- RemoteEvent (Server -> AllClients: estado da nave, timers, peso, falhas)

ServerScriptService/
 ├── GerenciadorMissao.server.lua     -- Máquina de estados da missão, validação de peso, timers e regras
 └── DataStoreManager.server.lua      -- Persistência segura (pcall) de melhores estrelas por missão e cards do Álbum

StarterPlayer/
 └── StarterPlayerScripts/
      ├── NavegacaoNave.client.lua    -- Gerencia movimentação livre, modo EVA (Task 2 M2) e efeitos de câmera/janela
      ├── UIPreparacao.client.lua     -- Tela de Preparação Co-op, barra de peso ao vivo e seleção de equipamentos
      └── UITasksEFeedback.client.lua -- HUD das tasks, cronômetro, balão do Marcos Pontes, resultado e Álbum NASA
```

### Esqueleto do `ReplicatedStorage/Config/Missoes.lua`
```lua
-- ATENÇÃO: Todos os pesos, tempos e multiplicadores abaixo são VALORES DIDÁTICOS
-- simplificados para balanceamento educativo (sinalizar nos créditos do jogo).

local Missoes = {}

Missoes.RegrasGerais = {
	PesoNave = 20, -- kg
	LimiteFoguete = 60, -- kg
	KgPorBonus = 10, -- a cada 10 kg livres...
	SegundosBonusPorFaixa = 2, -- ...desconta 2 segundos do tempo final
	MaxJogadoresPorNave = 4,
	FaixasEstrelas = {
		TresEstrelas = 45, -- até 45s
		DuasEstrelas = 70, -- até 70s
		UmaEstrela = 100,  -- até 100s
	}
}

Missoes.Lista = {
	[1] = {
		Id = 1,
		Nome = "Projeto Mercury (Friendship 7)",
		Equipamentos = {
			Giroscopio = { Nome = "Giroscópio", Peso = 15, TaskAlvo = 1, TempoSegurar = 1.2 },
			ManualBordo = { Nome = "Manual de Bordo", Peso = 20, TaskAlvo = 2, BonusTempo = 15 },
			EscudoReforcado = { Nome = "Escudo Reforçado", Peso = 25, TaskAlvo = 3, TempoSegurar = 6.0 }
		},
		Tasks = {
			[1] = { Nome = "O Colapso do Piloto Automático", LimiteTempo = 40, TempoBaseSegurar = 2.0, TotalPontos = 4 },
			[2] = { Nome = "O Blackout de Comunicação", LimiteTempo = 30 },
			[3] = { Nome = "O Alarme do Escudo Térmico", TempoDecisao = 10, TempoBaseSegurar = 10.0 }
		}
	},
	[2] = {
		Id = 2,
		Nome = "Estação Espacial Internacional (ISS)",
		Equipamentos = {
			SensorPressao = { Nome = "Sensor de Pressão", Peso = 15, TaskAlvo = 1, MultiplicadorZonaVerde = 1.5 },
			LuvasAderentes = { Nome = "Luvas Aderentes", Peso = 20, TaskAlvo = 2, MultiplicadorVelocidade = 2.0 },
			KitVedacao = { Nome = "Kit de Vedação", Peso = 25, TaskAlvo = 3, ReducaoPerdaAr = 0.6, TempoSegurar = 2.0 }
		},
		Tasks = {
			[1] = { Nome = "O Acoplamento (STS-88)", LimiteTempo = 40, TempoPressaoMaxFalha = 3.0 },
			[2] = { Nome = "O Painel Solar Preso (STS-97)", LimiteTempo = 45, TotalCabos = 2 },
			[3] = { Nome = "O Vazamento de 2 mm (Soyuz MS-09)", TempoBaseSegurar = 3.0, TaxaPerdaArBase = 2.5 }
		}
	}
}

Missoes.FalasMarcos = {
	ExcessoPeso = "{nome}, o foguete só leva 60 kg e a nave estava com {peso} kg. Ele nem saiu da plataforma! Na engenharia espacial cada quilo conta: escolham juntos apenas o que mais ajuda.",
	EjetarBlackout = "Ejetar durante a reentrada seria fatal. O John Glenn ficou 4 minutos sem rádio e confiou no treinamento. Às vezes a resposta certa é manter a calma e seguir o procedimento.",
	EjetarEscudo = "Era um erro do sensor! O escudo estava preso. Quem ejeta no pânico perde a missão. Manter o retropack foi a decisão real da NASA.",
	PressaoMaximaAcoplamento = "Força demais amassa o módulo! Na STS-88, a solução foi aliviar a pressão do braço, não apertar mais.",
	FaltaTempoSemItem = "Faltou tempo, {nome}. O {equipamento} teria ajudado justamente aqui. Na próxima, conversem e decidam qual task é mais difícil para a equipe."
}

return Missoes
```

### Contrato de Segurança (Client vs. Server)
* **Proibido:** O cliente **nunca** envia o tempo gasto na task, o peso total calculado ou a quantidade de estrelas ganhas.
* **Obrigatório:** O servidor registra `os.clock()` no início e no fim de cada task, valida se os equipamentos solicitados pertencem àquela missão e verifica se os jogadores estão próximos o suficiente dos `ProximityPrompts` antes de aceitar ações críticas (como fechar a escotilha ou digitar no rádio).

---

## 7. Ordem de Construção e Critérios de Aceite (Definition of Done)

A implementação deve seguir estritamente esta sequência. **Caso o tempo do hackathon fique curto, corte a Missão 2 inteira, nunca pela metade.**

1. **Fase 1 — Config, Navegação e Preparação:**
   * Criar `ReplicatedStorage/Config/Missoes.lua` com todos os valores parametrizados.
   * Montar o interior da cápsula Mercury com janelas grandes e movimentação livre funcional.
   * Implementar a UI de Preparação (Solo e Co-op) com barra de peso ao vivo (verde/amarela/vermelha) e validação de falha acima de `60 kg` no servidor.
2. **Fase 2 — Missão 1 Completa:**
   * Implementar as 3 estações físicas na cápsula (janelas de alinhamento, prancheta + rádio, console de retropack).
   * Conectar todos os 3 equipamentos (`Giroscópio`, `Manual de Bordo`, `Escudo Reforçado`) alterando mecanicamente suas respectivas tasks.
   * Implementar todas as falas de falha do Marcos Pontes e os botões `"Tentar a task de novo"` e `"Recomeçar a missão"`.
3. **Fase 3 — Pontuação, Álbum e DataStore:**
   * Implementar a tela de resultado com a equação detalhada (`T1 + T2 + T3 - Bônus = Total · Estrelas`).
   * Implementar o Álbum com os cards históricos oficiais da NASA e persistência via `DataStoreService`.
4. **Fase 4 — Missão 2 Completa:**
   * Construir o módulo da ISS com Cupola panorâmica e Airlock para EVA.
   * Implementar as 3 tasks (`STS-88`, `STS-97` em EVA, `Soyuz MS-09`) com suporte a Co-op e os 3 equipamentos (`Sensor de Pressão`, `Luvas Aderentes`, `Kit de Vedação`).

### Checklist de Testes Obrigatórios antes da Entrega
- [ ] Selecionar os 3 equipamentos juntos (`80 kg`) permite clicar em **Lançar**, falha imediatamente na plataforma e exibe a fala correta de excesso de peso do Marcos.
- [ ] Cada um dos 6 equipamentos (3 da Missão 1 + 3 da Missão 2) altera visivelmente e numericamente a sua task alvo.
- [ ] Jogadores conseguem caminhar livremente pela nave durante todas as tasks e observar o espaço pelas janelas panorâmicas.
- [ ] Em Co-op (2+ jogadores), a barra de peso e os objetivos das tasks sincronizam corretamente entre todos os clientes.
- [ ] `"Tentar a task de novo"` zera apenas o cronômetro da task atual e preserva os equipamentos escolhidos.
- [ ] `"Recomeçar a missão"` retorna todos os jogadores para a Preparação e permite trocar os equipamentos.
- [ ] A equação final exibida na tela bate exatamente com a soma dos cronômetros do servidor menos o bônus de leveza.