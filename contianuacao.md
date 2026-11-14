# Continuação — missão Friendship 7 (missaoUm.md)

Atualizado em 2026-11-14. A spec `missaoUm.md` está implementada e testada em Studio. **Nada foi commitado.**

## Feito
- **Fase 15:** `build/phase15_friendship7.luau`, que instala os scripts de `build/mission/`. Já está no `run_in_studio.luau`.
- **Fase 8:** o CrewAccess ignora os prompts de quem tem `MissionActive`.
- **Docs atualizados:**
  - `IMPLEMENTATION.md`: seção "Missão Friendship 7" com os resultados do playtest.
  - `CLAUDE.md`: Fase 15 na tabela e o playtest da missão.
  - `assets/LICENSES.md`: os 8 sons ProSoundEffects.
- **Playtest em Studio (1 jogador):**
  - Tarefa 1: olhar, combustível e estabilização.
  - Tarefa 2: código errado e certo, estática e papel.
  - Tarefa 3: jettison → falha → retry; retain + segurar e soltar.
  - Resumo final e abortar ao levantar.
  - Console sem erros.
- **Correções feitas durante o teste:**
  - Texto das plaquetas dos botões (orientação).
  - Câmera vira para o console ao iniciar.
  - Estática branca e estática congelada.
  - Faixa duplicada no resumo.

## Pendente
1. **Testes que faltam:**
   - Clique real com o mouse e toque no celular. O teste usou os remotes.
   - Dois jogadores ao mesmo tempo (CDR + PLT), em Test → Clients and Servers.
   - EJECT, e as falhas por tempo e por combustível em Play.
2. **Para o usuário:**
   - Salvar o place no Studio (Ctrl+S).
   - Commit, se quiser.
   - Arquivos novos: `build/phase15_friendship7.luau`, `build/mission/`, `assets/LICENSES.md` e este arquivo.
3. **Ajustes possíveis:** a tela DU 3 mostra "STANDBY" atrás do resumo final (cosmético).

## Como reconstruir
1. Servir a pasta: `cd build && python3 -I -m http.server 8765 --bind 127.0.0.1`.
2. Rodar o `run_in_studio.luau` no Edit. Se só a Fase 15 mudou, ela pode rodar sozinha, porque não move peças de outras fases.
