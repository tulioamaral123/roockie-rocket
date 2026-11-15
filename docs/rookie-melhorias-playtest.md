# Rookie Rocket — melhorias após playtest

## Objetivo e modo de trabalho

Investigar e corrigir os problemas de interface, navegação, tutorial, progressão, conteúdo científico e desempenho anotados no playtest. As anotações são resumidas: reproduza os problemas antes de alterá-los e não apresente hipóteses como fatos confirmados.

Leia `CLAUDE.md`, `AGENTS.md`, `TASKS.md` e os contratos relevantes; respeite reservas de arquivos, worktrees e o gerador por fases. Confira o estado atual do Studio e do repositório. A última reconstrução relatou falha na fase 16 por um pedestal que obstrui a circulação do planetário; verifique se ainda ocorre. Textos visíveis no jogo devem ser em inglês.

## 1. Imagens e design

O playtest relata imagens “bugando um pouco”. Identifique quais telas e imagens apresentam o problema e verifique asset IDs, carregamento, permissões e moderação. Corrija o defeito observado, como imagem ausente, distorção, recorte, tremulação ou sobreposição. Use estado de carregamento ou substituto legível se necessário. Teste diferentes resoluções, inclusive celular.

As palavras “feedback” e “fundo” aparecem sem explicação na anotação. Examine contraste, legibilidade, hierarquia e resposta visual das interfaces e registre os problemas encontrados. Não presuma um redesenho específico.

## 2. Setas e sequência dos objetivos

As setas no chão foram relatadas como defeituosas e com direção incorreta. Reproduza em curvas, portas, escadas e próximo a paredes; corrija orientação, rotação, atualização de destino e waypoints conforme a causa observada. A seta deve orientar pelo caminho acessível, sem apontar através de paredes.

Durante as missões, aponte para a estação da tarefa **atual**, na ordem correta; atualize o destino ao avançar e limpe indicadores obsoletos em falha, reinício, saída ou troca de missão. A navegação deve ser individual para cada jogador.

No museu, preserve a regra solicitada: é necessário interagir com pelo menos um item para continuar. Ao entrar na sala correta, substitua a seta vermelha por uma **circunferência branca que destaque o item**. Depois da interação, indique o próximo destino. Teste visibilidade e posicionamento em diferentes distâncias e dispositivos.

## 3. Tutorial mais intuitivo

Mostre um objetivo curto por vez e dê feedback quando ele for concluído. A sequência desejada é: encontrar Marcos Pontes; segui-lo ao museu; selecionar uma exposição; seguir ao foguete e encontrar Ana; escolher missão, traje e equipamentos; embarcar e cumprir as tarefas em ordem.

Explique os controles no momento em que forem necessários. Garanta legibilidade em teclado, toque e controle; não dependa apenas de cores. Evite prompts conflitantes e diálogos que impeçam o jogador de agir. Ao renascer, voltar ou reiniciar, restaure um objetivo coerente com o progresso.

## 4. Seleção de missões e feedback

A imagem diz “deixar tela da seleção de missões”, mas não especifica a mudança desejada. Não invente uma exigência visual: revise a tela e corrija os problemas concretos encontrados.

Deixe claros missão selecionada, disponibilidade, traje, equipamentos, peso e limite de 60 kg, conforme o sistema atual. Informe por que uma ação está bloqueada e como avançar. Valide traje, permissões e peso no servidor; teste abertura, fechamento, retorno e reinício.

## 5. Ciência e card da missão real

Adicionar contexto científico e histórico ligado a cada missão e tarefa. Incluir ou corrigir o **card sobre a missão real**, preferencialmente após o resultado; se já existir, revisar seu funcionamento antes de criar outro.

Cada card deve apresentar título, missão e data verificados, uma explicação breve do acontecimento real, a relação com o desafio jogado e fonte oficial diretamente relacionada. Explicar trade-offs entre massa, recursos e benefícios. Identificar tempos, pesos e efeitos simplificados como valores de jogo, sem apresentá-los como dados históricos.

Pesquisar e conferir dados em fontes primárias, incluindo NASA e agências responsáveis. Verificar fonte, autorização e condições de uso para cada imagem. As falas de Marcos Pontes são ficcionais e não devem parecer citações ou endosso real.

## 6. Remover o Mission Board

A anotação pede “tirar o Mission Board”. Primeiro identifique o objeto exato e suas dependências. Remova o elemento indicado e seus prompts ou referências órfãs, preservando a seleção com Ana e o card histórico. Confirme que a progressão não depende do painel antes de retirá-lo.

## 7. Corrigir confusão na progressão

Reproduza o percurso completo e identifique onde o objetivo mostrado diverge da ação necessária. Revise recepção, museu, foguete, seleção, embarque, tarefas, resultado e retorno. Cada transição deve ter condição clara, feedback visível e indicador adequado.

Teste bloqueios e desbloqueios previstos no projeto, falha, reinício, saída, renascimento, reconexão e progresso individual no cooperativo. Não mude regras de desbloqueio sem verificar as especificações atuais; documente qualquer mudança necessária.

## 8. Otimização

Meça antes e depois em condições comparáveis e priorize gargalos observados: conexões ou loops duplicados, buscas repetidas, atualizações de interface desnecessárias, excesso de objetos e assets pesados. Registre método, ambiente e limitações; FPS do Studio em segundo plano não é medida confiável. Preserve qualidade e funcionamento.

## 9. Critérios de aceite e entrega

- As imagens e a seleção funcionam nos tamanhos de tela testados; problemas não reproduzidos são relatados.
- As setas indicam a próxima ação válida; no museu, a circunferência branca aparece e a interação com um item libera a etapa seguinte.
- O tutorial e a progressão acompanham corretamente o estado do jogador em falha, reinício e retorno.
- Há ciência contextualizada e card da missão real com fontes verificáveis.
- O Mission Board identificado foi removido sem quebrar os sistemas que permanecem.
- Relatar resultados e limitações de desempenho, verificações executadas, fases a reconstruir e roteiro de playtest; separar o que passou, falhou e não pôde ser testado.
- Atualizar os registros e o PR conforme as instruções do projeto.
