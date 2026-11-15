# GitHub + VS Code + Rojo — guia de uso

## Como o projeto está dividido

| O quê | Onde fica | Como chega ao Studio |
|---|---|---|
| Scripts das missões Rookie Rocket | `build/rookie/**/*.luau` | **Rojo**, em tempo real (`default.project.json`) |
| Scripts do museu | `build/museum/{server,client,shared}` | **Rojo** |
| Scripts do mapa: portas (AutomaticDoors), tripulação (CrewAccess) | `build/systems/server/` → `ServerScriptService.Map_Systems` | **Rojo** |
| Scripts do mapa no cliente: planetas (PlanetOrbits), tela do elevador (CrewClient) | `build/systems/client/` → `StarterPlayerScripts.MapClient` | **Rojo** |
| Mapa (peças, luzes, placas) | `build/phase*.luau` | Servidor HTTP + `run_in_studio.luau` (ver `CLAUDE.md`) |

Regras:
- O Rojo gerencia só as pastas de scripts acima. O resto do place (Workspace, Lighting) fica intocado.
- Com o Rojo conectado, as fases veem o atributo `RojoManaged` e não reinstalam os scripts; só criam as peças.
- Não use `rojo build` para gerar o place: o mapa não está no projeto Rojo.

## Instalação (uma vez)

No Terminal:

1. Baixar o Rokit, o instalador oficial de ferramentas do Rojo (Mac com Apple Silicon):

```bash
curl -sSLo /tmp/rokit.zip https://github.com/rojo-rbx/rokit/releases/download/v1.2.0/rokit-1.2.0-macos-aarch64.zip && unzip -o /tmp/rokit.zip -d /tmp/rokit && /tmp/rokit/rokit self-install
```

2. Fechar e abrir o Terminal. Depois instalar o Rojo 7.7.1, fixado em `rokit.toml`; responda "yes" para confiar no Rojo:

```bash
cd ~/Documents/nasa && rokit install
```

3. Instalar o plugin do Rojo no Studio, depois fechar e abrir o Studio:

```bash
cd ~/Documents/nasa && rojo plugin install
```

No VS Code:

4. Abrir a pasta `~/Documents/nasa` (File → Open Folder).
5. Extensões (já instaladas neste Mac em 15/11/2026): **Rojo** (`evaera.vscode-rojo`), **Luau Language Server** (`JohnnyMorganz.luau-lsp`) e **Claude Code** (`anthropic.claude-code`). Se o aviso não aparecer, abra Extensions e digite `@recommended`.
6. Opcional: no Command Palette (Cmd+Shift+P), rodar "Shell Command: Install 'code' command in PATH".
7. GitHub: o repositório já está ligado em `git@github.com:tulioamaral123/roockie-rocket.git`, por SSH, e funciona. A aba Source Control do VS Code usa esse git para commit, push e pull. Para ver PRs e issues no editor, instale a extensão "GitHub Pull Requests" e entre com a sua conta.

## Uso diário

1. Abrir o `Place1.rbxl` no Studio e a pasta no VS Code.
2. Iniciar o servidor Rojo, de uma destas formas:
   - VS Code: Cmd+Shift+P → "Rojo: Open menu" → `default.project.json` → Start.
   - Terminal: `cd ~/Documents/nasa && rojo serve`
3. No Studio, abrir a aba Plugins → Rojo → **Connect** (localhost:34872).
4. Editar qualquer arquivo em `build/rookie/`, `build/museum/` ou `build/systems/` e salvar: o script muda no Studio na hora.
5. Ao terminar, fazer commit e push pela aba Source Control (ou `git`), e salvar o place no Studio (Ctrl+S).

## Problemas comuns

- **O Rojo pede para substituir instâncias ao conectar.** É normal na primeira conexão: os scripts já existiam, criados pelas Fases 18 e 21. Aceite.
- **`rojo: command not found`.** Abra um Terminal novo depois do `rokit self-install`; ele adiciona `~/.rokit/bin` ao PATH.
- **O plugin não aparece.** Feche o Studio por completo e abra de novo depois do `rojo plugin install`.

## Programar com o Claude gastando menos tokens

1. No VS Code, abra o Claude Code pelo ícone ✱ na barra lateral (ou Cmd+Esc).
2. Peça mudanças citando o arquivo: "em `build/systems/server/CrewAccess.server.luau`, faça X". Ele edita o arquivo, o Rojo leva ao Studio.
3. Teste você mesmo no Studio (Play). Se der erro, copie **só a linha vermelha** do Output e cole no chat.
4. Uma conversa por tarefa: terminou, `/clear` (ou conversa nova).
5. Tarefas simples: modelo Sonnet (`/model`). Deixe o Opus para o difícil.
6. Evite pedir screenshots ou "olha no Studio": é o que mais gasta.
7. Mudar o mapa (peças) ainda exige rodar os geradores pelo HTTP; agrupe essas mudanças.
