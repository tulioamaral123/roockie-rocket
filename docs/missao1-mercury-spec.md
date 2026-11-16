# Missão 1 · Projeto Mercury (Friendship 7) — spec

Recorte da missão 1 a partir de [`docs/rookie-rocket-spec.md`](rookie-rocket-spec.md) (spec completa, com a missão 2 e a arquitetura). Textos visíveis no jogo em inglês; as falas abaixo estão em português como na spec original e foram traduzidas em `build/rookie/shared/Missoes.luau`.

> **Regra fixa de créditos:** todos os pesos, tempos, velocidades e efeitos de equipamentos são **valores didáticos simplificados** para jogabilidade e aprendizado, e isso aparece na tela de Créditos. As falas do Marcos Pontes são fictícias.

---

## 1. Fluxo da missão

```text
[Escolha com a Ana no topo do foguete: missão → equipamentos (até 2) → traje → embarque]
       │  (peso > 60 kg) ──► FALHA IMEDIATA na plataforma + fala do Marcos
       ▼  (peso ≤ 60 kg)
[Lançamento: contagem de 12 s (co-op: outros tripulantes podem embarcar)]
       ▼
[Task 1] ──► [Task 2] ──► [Task 3] ──► [Parabéns + aprendizado] ──► [Resultado + estrelas] ──► [The real mission / Álbum]
   └──(falha)──┴──(falha)──┴──► [Marcos explica] ─┬─ Retry task (zera o tempo da task, mantém itens)
                                                   └─ Restart mission (volta ao embarque, libera troca de itens)
```

## 2. Peso e bônus de leveza

- Nave: **20 kg**. Limite do foguete: **60 kg**. Livre para equipamentos: **40 kg**, compartilhados pela tripulação.
- Equipamentos de 15, 20 e 25 kg: no máximo **2** (15 + 20 = 55 kg ou 15 + 25 = 60 kg); 20 + 25 = 65 kg é inválido e serve de erro didático.
- Barra de peso: ≤ 50 kg verde, 51–60 amarela, > 60 vermelha (o embarque continua clicável para o erro didático).
- **Bônus de leveza** = ⌊(60 − peso) / 10⌋ × 2 s.

## 3. Pontuação

Cada task tem cronômetro no servidor, que corre enquanto ela está ativa (inclui andar dentro da nave).

**Tempo final** = max(0, T1 + T2 + T3 − bônus de leveza)

| Tempo final | Estrelas | Status |
| :--- | :--- | :--- |
| ≤ 45 s | ⭐⭐⭐ | Ouro |
| 46–70 s | ⭐⭐ | Prata |
| 71–100 s | ⭐ | Bronze |
| > 100 s | 0 | Falha: "Took too long" |

Tela de resultado: `T1 12 s + T2 18 s + T3 15 s − 4 s lightness = 41 s · ⭐⭐⭐`

## 4. Ambiente

Cápsula navegável para 1 a 4 jogadores (Fase 19, `NASAComplex.RookieRocket.Mercury`, origem em (−3000, 1200, 0)), com gravidade local mais leve, 4 assentos e três estações:

1. **Painel frontal e periscópio**, com janela panorâmica frontal.
2. **Janela lateral e mesa de navegação**, com a prancheta do código.
3. **Rádio e retropack**: painel de comunicação e botões de reentrada.

Efeitos nas janelas: na Task 1, estrelas girando rápido e luz interna vermelha pulsando; na Task 3, plasma de reentrada laranja e vermelho passando pelas janelas.

## 5. Equipamentos

| Equipamento | Peso | Task | Efeito |
| :--- | :--- | :--- | :--- |
| **Gyroscope** (giroscópio) | 15 kg | 1 | Tempo para travar cada alvo: 2,0 s → 1,2 s |
| **Flight Manual** (manual de bordo) | 20 kg | 2 | Destaca o código na prancheta e dá +15 s (30 s → 45 s) |
| **Reinforced Shield** (escudo reforçado) | 25 kg | 3 | Segurar o retropack: 10 s → 6 s, e menos tremor de câmera |

## 6. Tasks

### Task 1 · The Autopilot Failure (falha do piloto automático)
- **Alerta:** "AUTOMATIC CONTROL FAILURE" + tremor leve.
- **Mecânica:** centralizar a mira (+) sobre **4 pontos vermelhos** externos e segurar até o círculo completar (2,0 s; 1,2 s com o giroscópio).
- **Co-op:** vários jogadores travam pontos ao mesmo tempo.
- **Falha:** passar de **40 s**.

### Task 2 · The Communication Blackout (blackout de comunicação)
- **Alerta:** "LOSS OF CONTACT WITH EARTH" + estática no rádio.
- **Mecânica:** ler o código sorteado na prancheta da mesa de navegação (destacado com o manual) e digitá-lo no rádio. Ao lado do teclado, um botão vermelho **EJECT CAPSULE** pisca.
- **Acerto:** a estática para e toca "Friendship 7, we read you. Welcome back."
- **Co-op:** um lê a prancheta enquanto outro digita no rádio.
- **Falha:** apertar **EJECT CAPSULE** ou o tempo acabar (30 s; 45 s com o manual). Código errado mostra só "Invalid code".

### Task 3 · The Heat Shield Alarm (alarme do escudo térmico)
- **Alerta:** "DANGER: HEAT SHIELD SENSOR UNSTABLE" + 10 s para decidir.
- **Mecânica:** no console de reentrada, escolher **EJECT CAPSULE** (vermelho) ou **HOLD RETROPACK** (verde). Mantendo, a cabine fica vermelha de calor e treme; segurar até a barra encher (10 s; 6 s com o escudo). Soltar só pausa.
- **Co-op:** dois ou mais segurando os botões redundantes reduz a trepidação.
- **Falha:** apertar **EJECT CAPSULE** ou não decidir nos 10 s iniciais.

## 7. Falas do Marcos Pontes (missão 1)

Cada falha interrompe a partida e mostra o Marcos com: o que aconteceu, o paralelo com o evento real e uma dica ligada aos equipamentos.

| Gatilho | Fala |
| :--- | :--- |
| Peso > 60 kg no lançamento | "{nome}, o foguete só leva 60 kg e a nave estava com {peso} kg. Ele nem saiu da plataforma! Na engenharia espacial cada quilo conta: escolham juntos apenas o que mais ajuda." |
| Ejetar na Task 2 | "Ejetar durante a reentrada seria fatal. O John Glenn ficou 4 minutos sem rádio e confiou no treinamento. Às vezes a resposta certa é manter a calma e seguir o procedimento." |
| Ejetar na Task 3 | "Era um erro do sensor! O escudo estava preso. Quem ejeta no pânico perde a missão. Manter o retropack foi a decisão real da NASA." |
| Tempo esgotado sem o item da task | "Faltou tempo, {nome}. O {equipamento} teria ajudado justamente aqui. Na próxima, conversem e decidam qual task é mais difícil para a equipe." |
| Tempo esgotado com o item da task | "Quase lá, {nome}! Mesmo com o {equipamento}, o tempo apertou. Dividam melhor as estações na nave e tentem novamente." |
| Sucesso | "Excelente trabalho, equipe! Vocês tomaram decisões de verdadeiros astronautas da NASA. Confira o registro histórico dessa missão no seu álbum!" |

---

## 8. Como está no jogo hoje (mudanças depois da spec original)

- **Embarque:** a escolha é feita com a Ana no topo do foguete, no **Mission Flight Manifest** em duas abas: missão (descrição e guia das tasks) → equipamentos com ícones, peso e checklist (traje, itens, peso). O servidor valida traje, até 2 itens e 60 kg antes do embarque. O antigo quiosque Mission Briefing do LCC foi retirado.
- **Traje obrigatório:** vestido num armário do Crew Suit-Up Room (com espelho).
- **Lançamento:** 12 s de contagem; nesse tempo toca a **cutscene da decolagem** (o SLS sai da plataforma 39B) e o jogador volta sentado na cápsula. Em co-op, quem embarca durante a contagem vê o restante.
- **Assentos:** a tripulação entra já sentada; os 4 assentos ficam voltados para o painel.
- **Task 1:** feita no **painel de atitude em frente ao assento** (FlightPanel): ao clicar, o painel aproxima e o jogador mexe a mira sobre os 4 alvos, em vez de andar até as janelas.
- **Navegação:** setas no chão apontam a estação da task atual, por um caminho calculado dentro da nave.
- **Fim da missão:** tela de **parabéns e aprendizado** (ciência de cada task e o fato real ligado a ela), depois o resultado com a equação e as estrelas, e o card **The real mission** (Friendship 7, 20/02/1962, com fontes da NASA). Áreas de cada task: Task 1 Física (inércia/mecânica) e Engenharia de Automação e Controle; Task 2 Física (ondas eletromagnéticas) e Engenharia de Telecomunicações; Task 3 Física (termodinâmica) e Engenharia de Materiais.
- **Fatos conferidos (NASA):** Friendship 7 em 20/02/1962, 3 órbitas em 4 h 55 min; Glenn guiou a cápsula à mão quando ela saiu de atitude; apagão de rádio de 4 min 20 s; o sinal de escudo solto era um interruptor com defeito e o retropack ficou preso.

Arquivos principais: `build/rookie/shared/Missoes.luau` (números e textos), `build/rookie/server/{Sessao,TasksMercury,GerenciadorMissao.server}.luau`, `build/rookie/client/{RookieClient.client,Mira,Hud,Modais,Decolagem,Capsule}.luau`, `build/guide/client/MissionSelect.luau`, `build/phase19_rookie_mercury.luau` (cápsula). Contrato de peças: `docs/rookie-contrato.md`.
