# GitHub + VS Code + Rojo — guia de uso

## Como o projeto está dividido

| O quê | Onde fica | Como chega ao Studio |
|---|---|---|
| Scripts da missão Friendship 7 | `build/mission/*.luau` | **Rojo**, em tempo real (`default.project.json`) |
| Mapa (peças, luzes, placas) e scripts embutidos nos geradores (CrewAccess, AutomaticDoors, PlanetOrbits, CrewClient) | `build/phase*.luau` | Servidor HTTP + `run_in_studio.luau` (ver `CLAUDE.md`) |

Regras:
- O Rojo só gerencia as pastas `MissionSystem` (ReplicatedStorage e ServerScriptService) e `StarterPlayerScripts.MissionClient`. O resto do place (Workspace, Lighting, os outros scripts) fica intocado.
- Com o Rojo conectado, a Fase 15 vê o atributo `RojoManaged` e não reinstala os scripts; só cria as peças.
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
5. Aceitar as extensões recomendadas: **Rojo** (`evaera.vscode-rojo`) e **Luau Language Server** (`JohnnyMorganz.luau-lsp`). Se o aviso não aparecer, abra Extensions e digite `@recommended`.
6. Opcional: no Command Palette (Cmd+Shift+P), rodar "Shell Command: Install 'code' command in PATH".
7. GitHub: o repositório já está ligado em `git@github.com:tulioamaral123/roockie-rocket.git`, por SSH, e funciona. A aba Source Control do VS Code usa esse git para commit, push e pull. Para ver PRs e issues no editor, instale a extensão "GitHub Pull Requests" e entre com a sua conta.

## Uso diário

1. Abrir o `Place1.rbxl` no Studio e a pasta no VS Code.
2. Iniciar o servidor Rojo, de uma destas formas:
   - VS Code: Cmd+Shift+P → "Rojo: Open menu" → `default.project.json` → Start.
   - Terminal: `cd ~/Documents/nasa && rojo serve`
3. No Studio, abrir a aba Plugins → Rojo → **Connect** (localhost:34872).
4. Editar qualquer arquivo em `build/mission/` e salvar: o script muda no Studio na hora.
5. Ao terminar, fazer commit e push pela aba Source Control (ou `git`), e salvar o place no Studio (Ctrl+S).

## Problemas comuns

- **O Rojo pede para substituir instâncias ao conectar.** É normal na primeira conexão: os scripts já existiam, criados pela Fase 15. Aceite.
- **`rojo: command not found`.** Abra um Terminal novo depois do `rokit self-install`; ele adiciona `~/.rokit/bin` ao PATH.
- **O plugin não aparece.** Feche o Studio por completo e abra de novo depois do `rojo plugin install`.
