# Rookie Rocket — Visualização interativa do foguete central do museu

## Objetivo

Ao selecionar o foguete central do museu, apresentar uma visão lateral afastada que enquadre o foguete inteiro e permita selecionar seus componentes. Para cada componente, mostrar um painel com informações claras e fotografias reais verificadas.

## Antes de implementar

Leia `CLAUDE.md`, `AGENTS.md`, `TASKS.md`, as especificações e os contratos do museu. Inspecione o mapa e os scripts atuais para identificar o foguete central, seu modelo, escala, orientação, peças e interação existente. Não presuma se é Saturn V, SLS ou outro foguete: confirme antes de pesquisar ou criar conteúdo. Preserve os sistemas existentes e respeite as reservas de arquivos, o fluxo por fases e o Rojo. Textos visíveis no jogo devem ser em inglês.

## Experiência do jogador

1. O jogador chega ao foguete central e ativa a interação existente, ou um prompt claro como `Explore Rocket` se ainda não existir.
2. A câmera faz uma transição suave para trás e para o lado do foguete, mostrando sua extensão completa, do topo à base.
3. O jogador vê indicações discretas nas partes disponíveis e pode selecionar um componente com clique, toque ou controle.
4. Ao selecionar uma parte, um painel mostra seu nome, função, breve contexto e fotografia real correspondente.
5. O jogador pode escolher outra parte, fechar o painel ou sair da visualização.
6. Ao sair, a câmera e os controles retornam ao estado anterior; o progresso do jogador é preservado.

## Câmera

- Calcule o enquadramento a partir dos limites reais do modelo, orientação, campo de visão e proporção da tela. Deixe margem no topo e na base e mantenha o foguete inteiro visível também em telas estreitas.
- Escolha um ponto lateral com boa visibilidade. Verifique obstáculos com raycast ou outra estratégia apropriada; ajuste o ponto para não atravessar paredes ou mostrar uma parede em primeiro plano.
- Faça a transição de maneira suave e curta. Evite deslocamentos bruscos, tremulação e mudanças repetidas de câmera.
- Durante o modo de exploração, mantenha o personagem seguro e evite conflitos com outras câmeras, diálogos e controles. O comportamento deve ser individual para cada jogador.
- Salve e restaure as configurações originais de câmera e controles ao fechar, ao renascer, ao sair da experiência ou se a interface for destruída. Evite prender o jogador em modo de câmera controlada.
- Uma opção para encerrar deve permanecer visível e acessível; `Close`/`Back` deve funcionar em teclado, toque e controle.

## Seleção dos componentes

- Inspecione o foguete real gerado no projeto e defina regiões clicáveis correspondentes às partes que o modelo de fato representa. Exemplos possíveis, somente quando aplicáveis ao foguete identificado: cápsula ou espaçonave, torre de escape, estágios, tanques, motores, propulsores e aletas.
- Use áreas de seleção suficientemente grandes e discretas para toque, sem modificar o aspecto do foguete nem bloquear a navegação normal. Evite sobreposição ambígua entre regiões.
- Exiba um destaque sutil e um nome ao apontar ou selecionar. Inclua uma lista de componentes selecionáveis como alternativa acessível quando o clique direto for difícil, especialmente no celular ou com controle.
- Trocar de componente atualiza o mesmo painel, sem duplicar interfaces, conexões ou efeitos. A seleção deve corresponder ao componente realmente escolhido.
- Não crie nomes, divisões ou funções fictícias para preencher lacunas do modelo; se um componente não puder ser identificado, documente a limitação.

## Painel informativo e fotos

Para cada componente confirmado, apresentar:

- Nome em inglês e sua função principal em linguagem acessível.
- Um ou dois fatos reais breves e verificados, relacionados ao foguete correto.
- Foto real pertinente do componente ou uma imagem identificada como vista geral quando não houver fotografia específica adequada.
- Crédito e referência da fonte; indicação explícita quando a imagem for uma ilustração ou reconstrução, em vez de fotografia.
- Estado de carregamento e alternativa legível quando o asset não carregar, sem impedir o fechamento ou a escolha de outras partes.

Pesquise dados e imagens em fontes oficiais e primárias, priorizando NASA e as organizações responsáveis pela missão. Verifique a identificação, contexto, direitos e condições de uso de cada imagem; registre URL da página de origem, crédito, licença ou condições pertinentes e ID Roblox efetivamente utilizado. Não invente links, licenças, IDs ou dados históricos. URLs externas não substituem um asset de imagem acessível pelo cliente Roblox; só apresente um asset como funcional após verificá-lo. Não use imagens genéricas de outro foguete como se fossem do componente real.

## Integração e segurança

- Reutilize o sistema de exposições e as interfaces existentes sempre que adequado; mantenha dados dos componentes separados da apresentação.
- A interação com a exposição deve continuar contando para a regra do tutorial que exige conhecer pelo menos um item. Sair da visualização não deve apagar progresso.
- Interface e câmera são locais ao jogador. Valide no servidor qualquer evento que altere progresso, sem confiar apenas em dados enviados pelo cliente.
- Evite colisões com sistemas de seta, diálogo, missões e câmera já existentes. Não mude a câmera dos demais jogadores.
- Use assets permitidos pelas regras do projeto. Se algum conteúdo ou permissão não estiver disponível, informe a limitação e mantenha o painel funcional com um substituto.

## Critérios de aceite

- Ao ativar o foguete central correto, a câmera faz zoom out lateral e enquadra o modelo inteiro sem atravessar paredes nas resoluções testadas.
- Componentes identificados são selecionáveis por mouse, toque e controle; cada seleção mostra o conteúdo correspondente.
- Os painéis têm texto legível, fotos reais verificadas, créditos e fontes; ausência de imagem não quebra o fluxo.
- Ao fechar, a câmera e os controles voltam ao normal; também funcionam renascimento, saída e repetição da interação.
- A visita conta para o progresso do museu e outros jogadores mantêm sua própria câmera e progresso.
- Testar em PC, celular e com dois jogadores quando o ambiente permitir; registrar erros e testes não realizados.
- Documentar arquivos alterados, fontes e assets, verificações executadas, fases a rodar no Studio e roteiro de playtest. Atualizar os registros do projeto conforme suas instruções.

---

## Implementação (15/11/2026)

**Foguete central:** Saturn V (`NASAComplex.SpaceMuseumExhibits.SaturnV`, `ExhibitId = saturn_v`, Fase 17), deitado e suspenso no eixo Z do salão (motores em Z ≈ 125, torre de escape em Z ≈ 283, X 205, Y 22). Interação existente: prompt "Examine" → painel do museu → botão **Explore rocket** (substitui o antigo "View components" no Saturn V).

**Arquivos**
- `build/museum/client/RocketExplorer.luau` (novo): enquadramento, regiões, seleção, saída/restauração.
- `build/museum/client/PanelController.luau`: botão, painel de exploração (lista + detalhe + foto), layout à direita, Backspace = voltar, prompt da mesma exposição não fecha o painel durante a exploração; carregamento de foto por verificação periódica.
- `build/museum/shared/Content/Exhibits/SaturnV.luau`: `Explore` (11 partes com `Region`, `Function`, `Facts`, `Photo`, `Overview`), `ExploreBack`, fontes novas.
- `build/museum/shared/Content/Photos.luau`: 9903033 marcada como ilustração (corte); legenda de 9903401 corrigida (Apollo 6 indo para a plataforma 39A).
- `build/museum/shared/Text.luau`: textos `explore.*`.
- `build/rookie/client/Modais.luau`: mesma correção do aviso "Photo loading…" (IsLoaded).

**Câmera:** candidatos laterais (ângulos de 32° a 130° em relação ao lado dos motores, elevação 6–24°, os dois lados, FOV atual/80/90) com distância mínima que cabe na área livre à esquerda do painel (margem de 6%); o primeiro com linha de visão livre (nenhuma peça sólida ou vidro entre a câmera e cinco pontos do eixo, e nada a 2 studs da câmera). Se nenhum couber, reduz a margem do painel (60% e 0). Transição de 0,9 s (0,4 s ao reenquadrar), no passo de render. Movimento travado (ContextActionService), prompts e controles de toque desligados só para o jogador; tudo restaurado ao voltar, fechar, renascer, morrer ou trocar de câmera. Se outra câmera controlada estiver ativa (show do museu), não entra.

**Partes (11):** F-1 engines, S-IC, J-2 (S-II), S-II, S-IVB, J-2 (S-IVB), Instrument unit, Lunar module adapter, Service module, Command module, Launch escape system. Divisões vêm das peças reais do modelo (sub-Models `F1_*`, `J2_*`, `J2`, `Stage_IU`; prefixos `SpacecraftLMAdapter`, `ServiceModule`/`SMRadiator`, `CommandModule`/`DockingCover`, `Escape`/`Abort`). O módulo lunar fica dentro do adaptador e não é modelado à parte.

**Fotos (todas conferidas no Studio e no cliente em Play; NASA, images.nasa.gov, uso livre conforme as diretrizes de mídia da NASA, sem endosso):**

| Parte | NASA ID | Tipo | Asset Roblox |
|---|---|---|---|
| F-1 engines | 6862832 | foto | rbxassetid://104882711537786 |
| S-IC | 9903033 | ilustração (corte) | rbxassetid://116647837362210 |
| J-2 (S-II) e S-II | 9903176 (S-II chegando ao MSFC, 5 J-2 visíveis) | foto | rbxassetid://135981874714718 |
| S-IVB | 0100983 | ilustração (corte) | rbxassetid://115359478469854 |
| J-2 (S-IVB) | 6520309 | foto | rbxassetid://100257590637995 |
| Instrument unit | 0100984 | ilustração | rbxassetid://94397447288064 |
| Lunar module adapter | 0100985 (nave Apollo em corte, LM dentro do adaptador) | ilustração | rbxassetid://109197135716456 |
| Service module | 7010516 (SM danificado da Apollo 13) | foto | rbxassetid://109612002889429 |
| Command module | 372772main_GPN-2000-001212_full | foto | rbxassetid://77017815760691 |
| Launch escape system | 6900547 (torre da Apollo 11) | foto | rbxassetid://104974056535973 |

As 7 novas foram enviadas em 15/11/2026 (baixadas de images-assets.nasa.gov, servidas em localhost e enviadas pelo `upload_image` do Studio; dono: conta do jogo). A as13-59-8500 foi trocada pela 7010516 (mesma descrição oficial, módulo de perto). O aviso "Overview photo" continua no código, sem uso hoje.

**Fatos:** metadados oficiais de images.nasa.gov (6862832, 9903033, 0100979, 9801770, 9801810, 0600309, 6757813, 0100983, 0100984, 0100985, 6974206, as13-59-8500) e press kit da Apollo 8 (ntrs.nasa.gov, torre de escape).

**Verificado em Play (PC, 1507 × 786):** abrir o painel pelo prompt; Explore rocket; câmera enquadra o foguete inteiro na área livre (X 45–910 px, Y 284–522 px), sem parede entre câmera e foguete; passar o mouse destaca e mostra o nome; clique nos F-1 seleciona e mostra foto carregada, fatos e fontes; escolha pela lista (S-II) atualiza destaque e painel; Back to exhibit restaura câmera (Custom, Humanoid, FOV 70), prompts e marcadores; reentrar; renascer durante a exploração restaura tudo. Enquadramento calculado (sem renderizar) para 16:9, 4:3, celular deitado 844 × 390 e tablet 4:3: cabe em todos.

**Não testado:** toque e controle em aparelho real (B e a lista com o direcional), dois jogadores, captura de tela (o `screen_capture` do Studio expira). Nenhuma fase precisa ser reconstruída (só scripts).

**Roteiro de playtest:** museu → Saturn V → E (Examine) → Explore rocket → clicar/tocar em 3 partes → escolher 2 pela lista → Back to exhibit → Explore de novo → fechar com X; no celular, conferir que o foguete aparece inteiro à esquerda do painel; com controle, navegar a lista e sair com B.
