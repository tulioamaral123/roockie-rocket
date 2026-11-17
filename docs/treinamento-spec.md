# Astronaut Training — expansão opcional

O visitante pode praticar antes ou depois das missões. Pavilhão independente, acabamento em concreto claro, azul NASA, detalhes vermelhos, colunas arredondadas, painéis Montserrat e iluminação embutida. Textos do jogo em inglês. Nenhum asset externo.

## Experiências

- **Gravity Lab:** três pistas equivalentes Earth/Moon/Mars (gravidade relativa 1 / 0,166 / 0,38), com três checkpoints em ordem. É preciso subir nas plataformas para confirmar. Impulso de salto igual; a gravidade atua só no personagem dentro da pista. Ao sair, sentar, morrer ou entrar numa missão, remove a força e restaura o salto. Não altera `Workspace.Gravity`.
- **Systems Repair:** isolar energia → substituir filtro → restaurar energia. Estado individual; ordem incorreta recebe orientação. Acionar isolamento reinicia. Mostra o aprendizado ao concluir.
- **Crew Operations:** iniciar modo solo ou equipe, confirmar Power → Cooling → Communications em 30 s. Solo reservado a quem iniciou. Equipe admite até quatro participantes e exige pelo menos dois operadores diferentes. Quem iniciou também precisa operar se quiser contar como segundo operador. Sair da área/morrer/cancelar pela saída de uma pessoa reinicia; timeout libera nova tentativa. A ordem das estações permite distribuir funções antes da rodada.

Conclusões expostas nos atributos `TrainingGravityComplete`, `TrainingRepairComplete`, `TrainingCrewComplete`; duram somente a sessão. Não desbloqueiam ou bloqueiam Mercury/ISS. Sem DataStore novo.

## Construção e integração

- Fase 25: `NASAComplex.AstronautTraining`, pavilhão X 460..580, Z 90..203, altura 25. Gramado de apoio até X 596 (além da Baseplate).
- Passeio a leste a partir da calçada da praça: X 5..524, Z −99..−91; depois X 516..524, Z −91..90. Corrimãos no trecho externo ao terreno. Fora do museu (X máximo 277,5), da região de árvores (centros X máximo 430), do crawler e da área de observação. Conferir copas, arbustos e navegação no Studio antes de integrar.
- `BuildPhase = 25`, reconstrução idempotente. Scripts em `build/systems/`, automaticamente incluídos nas pastas já mapeadas pelo Rojo depois da integração.
- Sem Rojo, a própria fase instala os dois scripts por HTTP. Porta padrão **8766**, separada do checkout principal. As fontes são arquivos; não há scripts embutidos no gerador.
- `build/run_in_studio.luau` e `default.project.json` não foram alterados: reservados por outras tarefas. Esta fase é executada separadamente após o runner. A inclusão definitiva no runner fica para a integração com o responsável pelo arquivo.

## Executar no Studio (Claude/Mac)

Servir `build/` deste worktree: `python3 -m http.server 8766 --bind 127.0.0.1`. No Edit, depois das fases 1–24:

```lua
local H = game:GetService("HttpService")
local base = "http://127.0.0.1:8766/"
local function get(path) return H:GetAsync(base .. path .. "?t=" .. os.clock(), true) end
local lib = assert(loadstring(get("lib.luau")))()
print(assert(loadstring(get("phase25_training.luau")))(lib, base))
print(assert(loadstring(get("tests/verificar_treinamento.luau")))())
```

Reexecutar a fase e o verificador, comparar contagem de peças. Parar o servidor HTTP ao terminar. Não salvar `Place1.rbxl` sem revisar o resultado. Se Rojo estiver conectado ao checkout principal, integrar os dois scripts primeiro ou desconectar Rojo antes de instalar pelo HTTP.

## Playtest obrigatório

1. Percorrer praça → pavilhão → três atividades → retorno, sem cair para fora do terreno. Conferir estética e placas; PC, celular horizontal e controle.
2. Completar as três pistas; comparar saltos. Repetir com `UseJumpPower` ligado e desligado. Verificar ausência de força fora da pista, após reset e durante Mercury/ISS. Nenhuma gravidade extra para quem está fora do laboratório.
3. Tentar reparo fora de ordem; concluir; reiniciar no isolamento. Dois jogadores devem ter estados independentes.
4. Solo completo; outra pessoa não pode operar a rodada solo. Equipe com dois jogadores; uma pessoa sozinha não conclui no modo equipe. Testar timeout, saída, morte, limite de quatro e retorno.
5. Repetir reconstrução em Edit; sem duplicação de prompts, forças ou conexões. Revalidar percurso original e console sem erros.

Validação local: verificação de sintaxe por parser parcial de Luau e simulação geométrica, quando registradas na entrega. Isso não substitui o motor Roblox, a avaliação visual ou o playtest.
