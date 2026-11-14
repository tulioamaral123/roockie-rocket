# Colaboração Linux + MacBook

O Linux é onde o Claude Code e o Codex escrevem o código. O MacBook roda o Roblox Studio. Duas vias levam código ao Studio (ver `ROJO.md` e `CLAUDE.md`):

- **Rojo** (no Mac, `rojo serve`): scripts listados em `default.project.json` (missão Friendship 7) entram no Studio ao salvar.
- **Geradores** (`build/phase*.luau`): rodados no Studio pelo servidor HTTP local e `run_in_studio.luau`.

O Rojo só conecta o Studio aos arquivos do próprio Mac (localhost). Entre os computadores, o caminho é sempre o GitHub.

## Fluxo

```
Linux (Claude/Codex, worktrees)  --push/PR-->  GitHub  --pull-->  MacBook  --rojo serve / geradores-->  Studio
        \______________________ SSH pela Tailscale (rede privada) ______________________/
                          comandos permitidos: studio-mcp, status, sync, serve-*
```

1. **Sem acesso remoto** (já funciona): o Linux faz push de uma branch; o Mac faz pull (GitHub Desktop ou VS Code), com o `rojo serve` ligado os scripts mudam no Studio, e os geradores são rodados quando o mapa muda.
2. **Com acesso remoto** (depois do setup abaixo): o Claude Code ou o Codex do Linux usam o MCP do Studio do Mac pela rede privada. Assim, rodam Luau, inserem modelos da Creator Store, fazem playtest e capturam a tela sem gastar a IA da conta do Mac.

## Trabalho em paralelo

- Cada agente trabalha em um worktree próprio: `scripts/worktree-novo.sh claude <tarefa>` ou `scripts/worktree-novo.sh codex <tarefa>`.
- `TASKS.md` diz quem está mexendo em quais arquivos. Duas tarefas abertas não compartilham arquivos.
- Tudo entra na `main` por Pull Request.
- `Place1.rbxl` só é commitado pelo Mac.

## Setup do acesso remoto

Nada fica exposto na internet. A Tailscale cria uma rede privada só entre os computadores logados na mesma conta, e o SSH do Mac só aceita a chave do Linux, presa ao porteiro `scripts/mac/ssh-gate.sh`.

### Mac 1: Tailscale
Instalar a Tailscale (App Store ou tailscale.com/download), entrar e anotar o nome da máquina que aparece no app (ex.: `macbook-tulio`). O Linux precisa entrar na mesma rede (mesma conta, ou convite pelo painel da Tailscale).

### Mac 2: Login remoto
Ajustes do Sistema → Geral → Compartilhamento → **Login Remoto** ligado, em "Permitir acesso para" escolher **somente o seu usuário**. Anotar o nome de usuário (`whoami` no Terminal).

### Mac 3: porteiro e chave do Linux
No Terminal do Mac, dentro do repositório:

```bash
mkdir -p ~/bin ~/.ssh && cp scripts/mac/ssh-gate.sh ~/bin/roockie-ssh-gate.sh && chmod 755 ~/bin/roockie-ssh-gate.sh
```

Se o repositório não estiver em `~/Documents/nasa`, editar a linha `REPO=` do `~/bin/roockie-ssh-gate.sh`.

Depois, adicionar ao final de `~/.ssh/authorized_keys` uma linha (a chave pública vem do Linux):

```
restrict,command="/Users/USUARIO/bin/roockie-ssh-gate.sh" ssh-ed25519 AAAA... roockie-linux
```

`restrict` desliga terminal, redirecionamento de portas e agente; `command=` faz a chave só rodar o porteiro.

### Mac 4: Studio
Abrir o `Place1.rbxl`, depois Assistant → … → Manage MCP Servers → **Enable Studio as MCP server**. O Studio precisa ficar aberto enquanto o Linux trabalha.

### Linux
1. Criar a chave: `ssh-keygen -t ed25519 -f ~/.ssh/roockie_mac -C roockie-linux` e mandar o conteúdo de `~/.ssh/roockie_mac.pub` para o Mac.
2. Em `~/.ssh/config`:
   ```
   Host roockie-mac
       HostName NOME-DA-MAQUINA-NA-TAILSCALE
       User USUARIO-DO-MAC
       IdentityFile ~/.ssh/roockie_mac
       IdentitiesOnly yes
   ```
3. Testar: `ssh roockie-mac status`.
4. Registrar o MCP (só no Linux, escopo de usuário, para não afetar o Mac):
   ```bash
   claude mcp add --scope user Roblox_Studio_Mac -- ssh -T roockie-mac studio-mcp
   codex mcp add roblox_studio_mac -- ssh -T roockie-mac studio-mcp
   ```
5. No Claude Code: `/mcp` deve mostrar `Roblox_Studio_Mac` conectado; pedir `list_roblox_studios`.

### Comandos remotos
| Comando | O que faz no Mac |
|---|---|
| `ssh roockie-mac status` | `git status` do repositório |
| `ssh roockie-mac sync <branch>` | troca para a branch e faz pull (recusa se houver mudança não commitada) |
| `ssh roockie-mac serve-start` / `serve-stop` | liga/desliga o servidor local de `build/` (127.0.0.1:8765) para os geradores |
| `ssh roockie-mac studio-mcp` | usado pelo Claude/Codex como servidor MCP |

Atenção: `sync` troca os arquivos do disco, inclusive o `Place1.rbxl`, mas o Studio continua com o place que já estava aberto. Não salvar o place por cima depois de trocar de branch sem reabrir.

## Limites conhecidos

- O MCP do Studio é oficial, mas a Roblox só documenta uso local. Rodar o `StudioMCP` por SSH é uma montagem nossa e precisa ser testado.
- O Mac precisa estar ligado, com o Studio aberto e logado. Se o Mac dormir, a conexão cai.
- O `sync` usa a chave SSH do GitHub do próprio Mac. Se ela tiver senha guardada só no Chaveiro, o `git fetch` pela sessão remota pode falhar; nesse caso o Mac faz o pull pelo GitHub Desktop.
- Clientes MCP podem ler e alterar o place aberto. Só conectar agentes de confiança.
