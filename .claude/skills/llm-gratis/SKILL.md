---
name: llm-gratis
description: Delegar tarefas de texto simples e volumosas a um LLM gratuito sem chave (Kilo/LLM7; Groq/Gemini opcionais) para poupar o limite do Claude. Usar para traduzir/revisar textos de placas e cards, resumir arquivos grandes (specs, logs, relatórios) antes de ler, gerar rascunhos, listas e descrições. Também quando o usuário disser "manda pro modelo grátis", "usa o Groq/Gemini". Não usar para código Luau do mapa.
---

# Delegar a um LLM gratuito

`ask.py` (nesta pasta) manda o pedido e devolve só a resposta. O ganho vem de **eu não ler a entrada grande**: o arquivo vai direto para o modelo gratuito e eu recebo só o resultado curto.

## Quando compensa

- Entrada grande e saída pequena: resumir spec, log do Output, relatório, `data.json`.
- Texto em volume: traduzir/revisar placas e cards do museu, gerar descrições de exposições.
- **Não** usar para código Luau, geradores, decisões de arquitetura ou qualquer coisa que eu precise revisar linha a linha (aí a economia some).
- Se a tarefa é pequena (cabe numa resposta curta minha), fazer direto: delegar custa uma chamada.

## Regras

- Passar arquivos com `-f` (não dar `cat`/`Read` antes, senão gasto os tokens do mesmo jeito).
- Pedir saída curta e no formato exato que preciso (lista, tabela, JSON).
- Conferir o resultado por amostragem; modelos gratuitos erram mais.
- **Privacidade:** os provedores sem chave (Kilo, LLM7) podem registrar prompts e respostas. Mandar só conteúdo do projeto que pode ser público (specs, textos de placas, logs do Output); nada de chaves, senhas, `.env` ou dados pessoais.
- Padrão: `kilo` (sem chave, 200 req/hora por IP, contexto 1M, ~5–10 s). Reserva: `-p llm7` (sem chave, contexto 128K). Groq/Gemini só se houver chave em `~/.config/llm-gratis/keys.env`.
- Se um provedor falhar (429, catálogo mudou), tentar o outro ou outro modelo com `-m`.

## Uso

```bash
.claude/skills/llm-gratis/ask.py -f spec-v3.md "Liste em até 10 linhas tudo que a spec diz sobre a sala de observação, com o número da seção."
.claude/skills/llm-gratis/ask.py -f build/museum/cards.json "Revise o inglês destes textos; devolva só as linhas alteradas como 'antes -> depois'."
pbpaste | .claude/skills/llm-gratis/ask.py "Resuma este erro do Output em 3 linhas e diga o arquivo/linha provável."
```

Opções: `-p kilo|llm7|groq|gemini` (padrão kilo, ou `LLM_GRATIS_PROVIDER`), `-m modelo` (kilo: `nvidia/nemotron-3.5-lightning:free`, `kilo-auto/free`, `nvidia/nemotron-3-ultra-550b-a55b:free` (lento, mais forte); llm7: `gpt-oss:20b`; groq: `openai/gpt-oss-120b`, `openai/gpt-oss-20b`, `qwen/qwen3.8-27b`; gemini: `gemini-3.8-flash`, `gemini-2.5-flash`), `-s` instrução de sistema, `--max-tokens`.

## Chaves (opcional)

Em `~/.config/llm-gratis/keys.env` (permissão 600), uma por linha:

```
GROQ_API_KEY=...
GEMINI_API_KEY=...
```

Groq: https://console.groq.com/keys · Gemini: https://aistudio.google.com/apikey
