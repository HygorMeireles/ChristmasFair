# Christmas Fair — plano de implementação

Plano v3, de 16/11/2026. Feira e apresentação: **05/12/2026**.

Este documento define a implementação; não representa código implementado nem alterações realizadas no servidor.

## 1. Objetivo e decisões confirmadas

Construir um caixa para a barraca do Mister Wiz, com estoque visual animado, cobrança Pix pelo Mercado Pago e recebimento em dinheiro, controle de despesas e resultados. A demonstração será a própria operação na feira.

- Produtos iniciais: brownie, chocolate quente e ingresso de pescaria.
- Preços, estoque inicial, custos, capacidade da garrafa e volume dos copos editáveis pela interface e persistidos no banco. Nenhum desses valores será fixado no código. Números neste documento são apenas exemplos e cenários de teste.
- Cada ingresso garante um brinquedo; controlar a quantidade total de prêmios. Retirada posterior confirmada: ingresso pago e resgate são etapas distintas.
- Operador monta a compra; cliente escaneia o QR Code no desenho de um smartphone na tela.
- Uma compra pode conter vários produtos e quantidades.
- Dinheiro exige confirmação manual do operador.
- Provedor definido: somente Mercado Pago. Não criar contas em outros serviços. Cartão fica fora da primeira versão enquanto não houver equipamento e fluxo compatíveis confirmados.
- Alternância entre português e inglês, mantendo moeda BRL.
- Desenvolvimento local e colaborativo pelo GitHub; operação hospedada no servidor do Fish Record.
- Desativação do KoupZelo autorizada pelo usuário, prevista para a etapa de infraestrutura, com dados preservados.
- Sem publicação de credenciais, dados de clientes ou cópias de bancos no repositório público.

Premissas iniciais: um caixa principal no notebook; tela operada pela equipe; acesso administrativo autenticado; preços sem descontos e sem pagamento dividido na primeira versão. A barraca não tem nome próprio: usar a identificação do evento e da escola. Logos recebidas. O domínio e os valores finais não impedem iniciar o desenvolvimento. Por orientação do usuário, a escolha da integração Mercado Pago será retomada depois; não bloqueia modelagem, parametrização e telas.

## 2. Arquitetura proposta

| Parte | Escolha | Finalidade |
| --- | --- | --- |
| Aplicação | Ruby on Rails em versão mantida, fixada no projeto | Regras, páginas, autenticação e integração |
| Interface | Templates Rails, Turbo e Stimulus/JavaScript | Caixa, formulários e animações |
| Atualizações | Turbo Streams com Action Cable e adaptador compartilhado | Propagar confirmação e estoque entre processos e telas |
| Banco | PostgreSQL | Pedidos, pagamentos, estoque, despesas e auditoria |
| Tarefas | Active Job com Solid Queue | Webhooks, novas tentativas e reconciliação |
| Distribuição de eventos | Solid Cable, sujeito à compatibilidade da versão escolhida | Comunicação entre worker e aplicação sem Redis adicional |
| Visual | SVG e CSS com sombras, gradientes e perspectiva | Aparência em alto relevo e animações leves |
| Idiomas | Rails I18n: pt-BR e en | Traduções de interface, validações e mensagens |
| Produção | Container próprio, Nginx/HTTPS e PostgreSQL isolado logicamente | Hospedar no servidor existente |

Usar um monólito Rails. React Native e Vue não são necessários para este escopo. As versões exatas serão escolhidas na preparação do ambiente, mantendo arquivos de versão e dependências travadas para os dois desenvolvedores.

Dinheiro armazenado em centavos inteiros; chocolate em mililitros inteiros; brownies e prêmios em unidades. Não usar números de ponto flutuante para saldo ou estoque. Preços, porção e custos aplicáveis ficam registrados nos itens vendidos, preservando o histórico após alterações de configuração.

## 3. Caixa e experiência visual

Layout para notebook: identidade Christmas Fair/Mr. Wiz, seletor PT/EN, três áreas de produtos, resumo do pedido e smartphone à direita. Financeiro e configurações ficam em páginas administrativas.

### Identidade visual recebida

Originais preservados, sem edição, em `assets/branding/originals/`:

- `christmas-fair.jpeg`: arte do evento, com fundo creme, vinho, roxo, dourado e elementos natalinos.
- `mister-wiz-symbol.jpeg`: símbolo branco sobre fundo roxo.
- `mister-wiz-logo.png`: assinatura roxa da escola sobre fundo branco.
- `mister-wiz-banner.jpeg`: assinatura branca horizontal sobre fundo roxo.

Usar a grafia **Mister Wiz** das logos. Proposta de direção visual: fundo creme, roxo para identidade e controles, vinho e dourado em detalhes natalinos. Preservar proporções e legibilidade das marcas; o tamanho de textos, preços e QR Code tem prioridade no uso do caixa.

### Parametrização pela interface

Página de configuração para preço de cada produto, capacidade da garrafa em litros, volume do copo em ml e métodos de pagamento habilitados. Cadastro de lotes para estoque inicial, reposições e custos; categorias de despesas editáveis. Validar valores antes de habilitar vendas. Produção começa sem estoque e sem valores comerciais fictícios; dados de demonstração ficam em ambiente separado. Alterações posteriores preservam o histórico das vendas, com movimentação auditável para ajustes de saldo.

### Produtos

- **Chocolate:** garrafa com aparência de volume, líquido proporcional ao estoque atual e transição suave após confirmação. Exibir litros restantes e copos completos disponíveis. Exemplo: 5.000 ml e copo de 250 ml permitem 20 vendas; uma venda deixa 4.750 ml e 95% do nível.
- **Brownies:** bandeja com um quadrado por unidade cadastrada, textura, sombra e relevo. Uma venda retira a quantidade correspondente. Layout acomoda quantidades maiores por bandejas/páginas, preservando o contador exato.
- **Pescaria:** ilustração de lago/peixes ou prêmios, animação ao vender e contador dos ingressos ainda disponíveis. Quantidade visual vinculada ao total de prêmios vendáveis.
- Botões claros para adicionar e remover itens, ajustar quantidades e identificar produtos esgotados.
- Reservas pendentes ficam identificadas separadamente: a animação de venda acontece somente após recebimento confirmado.

### Smartphone e pedido

1. Carrinho vazio: smartphone bloqueado, sem QR Code.
2. Ao selecionar produtos: smartphone desbloqueia e mostra resumo/valor atualizado.
3. Ao concluir a seleção e escolher Pix: confirmar o pedido e gerar uma cobrança para aquele total. Essa confirmação evita criar cobranças intermediárias a cada clique.
4. Durante a geração: indicador de carregamento; após geração: QR Code real, total, identificação do pedido e validade.
5. Pedido aguardando pagamento fica congelado. Para editar, cancelar a cobrança anterior no provedor antes de gerar outra; se o cancelamento não for confirmado, manter a situação pendente e oferecer recuperação.
6. Confirmação verificada no servidor: smartphone mostra sucesso; estoque e painel são atualizados; operador inicia a próxima compra.
7. Cancelamento, expiração ou erro têm estados próprios; nunca mostrar sucesso por simples interação no navegador.

Na opção dinheiro, apresentar total, valor recebido e troco. Confirmar recebimento uma única vez; troco não conta como despesa nem como receita. Registrar operador e horário.

Trocar o idioma não perde o carrinho nem altera uma cobrança existente. O QR Code permanece plano, nítido, com margem e contraste, mesmo dentro da ilustração com relevo. Oferecer redução de movimento.

## 4. Estoque e pescaria

- Cadastrar saldo inicial e novos lotes; registrar reposição, perda, cortesia e ajuste com motivo.
- Capacidade da garrafa e conteúdo atual são campos diferentes; impedir conteúdo acima da capacidade.
- Quantidade de copos vendáveis = parte inteira do volume disponível dividido pela porção.
- Controlar reservas durante pagamentos pendentes para impedir duas vendas da última unidade.
- Reserva reduz a disponibilidade, sem contabilizar receita ou consumo confirmado.
- Confirmar pagamento e movimentação de estoque na mesma transação local, com bloqueio de registros e proteção contra duplicidade.
- Liberar reservas somente após resolução da cobrança; expiração visual no navegador não comprova cancelamento no Mercado Pago.
- Se chegar pagamento tardio após liberação, registrar o recebimento e abrir exceção para atendimento/reembolso, sem deixar saldo negativo ou perder o evento.
- Alterar preço ou volume do copo afeta novas compras; pedidos existentes preservam os valores usados na criação.

Para a pescaria, cada ingresso pago compromete um prêmio e reduz a disponibilidade imediatamente. A retirada posterior faz parte do escopo: emitir identificação única por ingresso, consultável pela equipe, e permitir marcar como utilizado na entrega do prêmio. Compras com vários ingressos permitem resgates individuais. A retirada reduz a quantidade física de prêmios e o total pendente de entrega, sem uma segunda baixa do disponível. Essa separação evita vender prêmios já prometidos e evita resgate duplicado. Mostrar contadores de disponíveis para venda, pagos aguardando retirada e entregues.

Reembolso financeiro e devolução física são decisões separadas: chocolate consumido ou brownie entregue não retorna automaticamente ao estoque.

## 5. Mercado Pago: validação inicial e implementação

### Referência examinada

A pasta AABB contém a integração A3L: serviço de geração Pix via Payments API, controller com validação de assinatura e job que consulta o pagamento. Reaproveitar o padrão arquitetural, adaptando autenticação, idempotência, persistência e regras ao caixa; não copiar regras de mensalidades, código de testes fictícios ou credenciais.

### Validação adiada pelo usuário, necessária antes da operação real

O fluxo da AABB usa compradores cadastrados. A documentação consultada do Pix online via Orders exige `payer.email`. A documentação de QR presencial descreve pagamento com o aplicativo Mercado Pago. Portanto, não assumir que o fluxo presencial elimina coleta de dados e continua funcionando no aplicativo bancário de qualquer cliente.

A prova técnica da etapa de pagamentos deve definir a modalidade que atende ao requisito: **QR Pix de valor exato, pago pelo aplicativo bancário do cliente, com confirmação por webhook**. Confirmar na conta do usuário quais APIs estão habilitadas, dados obrigatórios, expiração e cancelamento. Caso a modalidade disponível exija dados do comprador, apresentar essa limitação e decidir o fluxo antes de concluir a integração. Não usar e-mail inventado ou do vendedor como se fosse do comprador. Até essa etapa, desenvolver com um adaptador de demonstração explícito, sem cobrança real.

Criar configuração específica para Christmas Fair na mesma conta Mercado Pago, evitando alterar os webhooks de AABB/Fish Record. A criação e o teste real ficam para a implementação, com credenciais fornecidas por mecanismo seguro.

### Regras técnicas

- Total calculado no backend, a partir dos itens e quantidades validados.
- Persistir pedido, tentativa e chave de idempotência antes da chamada externa. Reutilizar a mesma chave em repetição da mesma tentativa.
- Timeout de criação não significa ausência de cobrança: reconciliar antes de emitir outra.
- Vincular cobrança ao pedido por referência externa e identificador do provedor.
- Validar assinatura conforme a modalidade/API selecionada e persistir a notificação antes de responder com sucesso.
- Processar em job com novas tentativas; consultar o estado oficial na API.
- Conferir conta recebedora, referência, valor, moeda e estado pago antes da confirmação.
- Restrições únicas e transação impedem que webhook repetido, consulta periódica ou duplo clique confirmem duas vezes.
- Notificações fora de ordem não podem regredir um pagamento confirmado para pendente.
- Reconciliação periódica recupera notificações perdidas, falhas temporárias e pendências após reinício.
- Ao trocar de Pix para dinheiro, resolver a cobrança aberta; pagamento Pix tardio após recebimento em dinheiro é exceção de duplicidade a tratar, sem nova baixa de estoque.
- Estornos e reembolsos geram lançamentos próprios, mantendo o histórico. Na primeira versão, podem ser iniciados no painel Mercado Pago e reconciliados na aplicação.
- Modo demonstração explicitamente separado e identificado; produção falha com mensagem clara se faltar configuração, sem simular pagamento aprovado.

### Decisão sobre provedor e cartões

O usuário decidiu manter somente o Mercado Pago e não abrir contas para a feira. Embora tenha Nubank, PicPay e Itaú, essas contas não fazem parte da integração prevista.

A primeira versão terá **Pix pelo Mercado Pago e dinheiro físico**. O aparelho disponível é iPhone XR e não há Android com NFC disponível na equipe. O recebimento de cartão por aproximação no aparelho ainda não foi validado; o MacBook será o caixa, não um leitor de cartão. Portanto, crédito/débito ficam fora da entrega inicial e não devem aparecer como meios habilitados no caixa.

Se futuramente o usuário disponibilizar equipamento compatível e quiser retomar cartões, avaliar a solução do próprio Mercado Pago. Não incluir compra de maquininha, cadastro em outro provedor ou integração de cartões como tarefa pendente para concluir a primeira versão.

## 6. Financeiro

### Despesas e lotes

Lançar descrição, categoria, data, valor e situação de pagamento. Categorias iniciais: ingredientes, embalagens/copos, brinquedos, decoração e outros. Permitir associação a produto/lote e rateio quando uma compra atender mais de um produto.

Cada lote registra quantidade produzida/adquirida e custo atribuído. Exemplo: custo de R$ 80 para 40 brownies resulta em custo de R$ 2 por unidade. Chocolate tem custo por ml e custo adicional de embalagem por porção. Pescaria usa custo unitário médio do lote de prêmios. Consumo de lotes por ordem de entrada, preservando o custo histórico.

Despesas não alocadas aparecem como pendências de custo; margens incompletas ficam indicadas como estimativas. O escopo não inclui estoque detalhado de cada ingrediente ou receitas industriais.

### Indicadores separados

| Indicador | Cálculo/uso |
| --- | --- |
| Vendas brutas recebidas | Apenas pagamentos confirmados |
| Receita líquida | Vendas recebidas menos reembolsos e taxas |
| Resultado de caixa do evento | Entradas liquidadas líquidas de taxas/reembolsos menos despesas pagas |
| Margem por produto | Receita líquida atribuída menos custo dos itens vendidos |
| Resultado gerencial | Receita líquida menos custos vendidos, perdas e despesas operacionais |
| Estoque restante a custo | Custo dos lotes ainda disponíveis |
| Caixa físico esperado | Fundo inicial + recebimentos em dinheiro - troco - saídas físicas registradas |

Não descontar a compra dos ingredientes e novamente o custo dos produtos vendidos no mesmo indicador. Compras de estoque afetam o caixa; custos das unidades vendidas afetam a margem. Fundo de troco e aportes não são receita de venda. Saída física para pagar uma despesa deve referenciar o mesmo lançamento, evitando duplicar a despesa.

Taxas reais vêm do Mercado Pago quando disponíveis. Enquanto não houver confirmação, sinalizar estimativa/pendência. Separar Pix e dinheiro e distinguir aprovação de liquidação quando aplicável. O resultado de caixa usa entradas liquidadas. Oferecer histórico de vendas, filtros por produto/método e exportação CSV de vendas e despesas.

## 7. Modelo de dados proposto

| Entidade | Responsabilidade |
| --- | --- |
| Event/Settings | Evento, moeda, capacidade, porções e configurações |
| Operator | Login e identificação das ações da equipe |
| Product | Tipo, nomes traduzidos, preço atual e disponibilidade |
| StockBatch | Lote, quantidade inicial/restante e custo |
| StockMovement | Entradas, vendas, perdas, devoluções e ajustes |
| Order / OrderItem | Pedido e itens com preço/porção registrados |
| StockReservation | Estoque reservado por item e tentativa pendente |
| PaymentAttempt | Pix/dinheiro, valor, estado, origem manual/API, chave de idempotência, IDs externos, taxas e liquidação |
| PaymentEvent | Notificações persistidas e processamento |
| FishingTicket | Direito ao prêmio e utilização/entrega |
| Expense / CostAllocation | Despesa e atribuição de custo aos lotes |
| Refund | Reembolso vinculado ao pagamento original |
| CashMovement | Fundo, recebimentos e retiradas físicas |

Transições críticas ficam em serviços de aplicação: criar cobrança, confirmar venda, cancelar pedido, registrar reposição e utilizar ingresso. Os mesmos serviços atendem webhook, reconciliação e dinheiro, respeitando as diferenças de confirmação de cada método.

## 8. Hospedagem e proteção de dados

Inspeção feita somente em arquivos locais. A configuração do Fish Record indica Nginx no host, containers gerenciados por Kamal e PostgreSQL acessado por socket. O KoupZelo possui Compose com API, worker de eventos, Traccar e PostgreSQL próprios. Isso ainda não confirma o estado atual nem a capacidade livre da máquina.

Na implantação:

1. Conferir serviços, consumo, disco, portas, certificados e dependências efetivamente ativos.
2. Gerar backup e registrar como retomar o KoupZelo.
3. Pausar os serviços exclusivos do KoupZelo e os mecanismos que possam reiniciá-los automaticamente. Preservar volumes e bancos; manter os serviços compartilhados necessários ao Fish Record.
4. Criar banco/usuário exclusivos, container web e worker do Christmas Fair, com limites adequados ao servidor.
5. Escolher porta interna livre e subdomínio, configurar Nginx/HTTPS e encaminhamento WebSocket. Reutilizar o gerenciador de deploy existente se a auditoria confirmar compatibilidade, sem instalar proxy concorrente.
6. Configurar webhook e segredos exclusivos; validar healthchecks, worker, reconciliação e atualização da tela.
7. Testar Fish Record após a mudança; documentar reversão do deploy e retomada do KoupZelo.

Segredos ficam em variáveis protegidas/credentials e na máquina de implantação. `.env`, master keys, segredos de deploy, logs e dumps ficam fora do Git. Versionar somente exemplos sem valores reais, filtrar logs e verificar mudanças por exposição acidental antes do envio.

Autenticação obrigatória para caixa e administração. Canal em tempo real autorizado e sem dados pessoais desnecessários. Webhook público com validação específica. Não exigir cadastro do cliente salvo necessidade da modalidade de pagamento escolhida.

Backup automático do banco para destino protegido fora do servidor e restauração ensaiada antes da feira. GitHub guarda código, não as vendas.

**Consequência da hospedagem:** sem internet no notebook, o sistema hospedado fica inacessível, inclusive para registrar dinheiro. Para a primeira versão, prever internet móvel de reserva e registro manual de contingência com conciliação posterior. Sincronização offline completa fica fora do escopo; não operar dois bancos independentes como se fossem um único caixa.

## 9. Etapas e cronograma proposto

As datas são metas de entrega, ajustáveis ao início efetivo e à disponibilidade da dupla. Começar por configuração, estoque e interface; retomar Mercado Pago na etapa de pagamentos, conforme solicitado pelo usuário. Cartões não fazem parte da entrega inicial.

| Período de 2026 | Etapa | Critério de conclusão |
| --- | --- | --- |
| 16–18/11 | Preparar projeto, identidade e parametrização | Ambiente reproduzível, logos organizadas e configurações comerciais sem valores fixos |
| 19–22/11 | Estoque, pedidos e dinheiro | Compra mista correta, última unidade protegida, lotes e confirmação manual auditável |
| 23–25/11 | Validar/integrar Pix e atualizar em tempo real | Definir dados exigidos, QR bancário e webhook; confirmação verificada e recuperação de falhas |
| 26–28/11 | Caixa visual, logos e PT/EN | Garrafa proporcional, brownies/prêmios coerentes e smartphone completo |
| 29–30/11 | Financeiro e pescaria | Custos/rateio, margens, caixa, exportações e resgate de ingresso |
| 01–02/12 | Implantação e ensaio integral | HTTPS, backup/restauração, teste real acompanhado e Fish Record saudável |
| 03–04/12 | Estabilização e preparação | Estoque/preços reais, treino da dupla e plano de contingência; sem novas funcionalidades |
| 05/12 | Feira e apresentação | Operação, acompanhamento de pendências e fechamento financeiro |

Divisão sugerida da dupla: uma pessoa cuida de domínio, pagamentos e infraestrutura; a outra de interface, animações e traduções. Financeiro e testes de aceitação são revisados pelos dois. Usar branches curtas e PRs; definir contrato dos estados do pedido antes de dividir a implementação. Essa é uma sugestão de organização, sem agentes ou tarefas criados automaticamente.

## 10. Verificação e critérios de aceite

- Garrafa de 5 L permite exatamente 20 copos de 250 ml; venda seguinte é bloqueada.
- Compra de duas unidades reduz duas unidades, com atualização após confirmação.
- Carrinho vazio nunca exibe cobrança; QR corresponde exatamente ao pedido congelado.
- QR testado no notebook com aplicativos bancários, no tamanho e iluminação de uso.
- Webhook repetido, fora de ordem, com assinatura inválida e valor divergente não gera venda incorreta.
- Timeout e nova tentativa não criam cobranças ou baixas duplicadas.
- Duas sessões disputando o último item não deixam estoque negativo.
- Cancelamento, expiração, pagamento tardio, troca para dinheiro e reembolso preservam histórico e saldo.
- Ingresso não pode ser usado duas vezes e seu resgate não baixa o disponível novamente.
- Compras com vários ingressos permitem retirada posterior parcial e mostram quantos ainda faltam retirar.
- Alterar preços, estoque, capacidade, porção e custos pela interface funciona sem editar código; saldos são ajustados com histórico.
- Apenas Pix e dinheiro aparecem como meios de pagamento; confirmação manual duplicada de dinheiro não repete a venda.
- Financeiro fecha com um conjunto conhecido de compras, lotes vendidos, sobras, perdas, taxas e reembolsos.
- Troca de idioma preserva pedido, valores e QR; textos essenciais existem em ambos os idiomas.
- Reconexão da tela recupera estado oficial; reinício do worker não perde notificações persistidas.
- Modo demonstração não contamina estoque/financeiro real e não cobra clientes.
- Backup restaurado com sucesso; ausência de segredos no diff; serviços do Fish Record verificados após deploy.

## 11. Pendências que não bloqueiam este plano

- Definir subdomínio antes de configurar DNS/HTTPS. Não haverá nome próprio de barraca nesta versão.
- Cadastrar pela interface preços, estoque inicial, capacidade, porção e custos antes do ensaio final; não solicitar esses valores para escrever o código.
- Retomar posteriormente a modalidade Mercado Pago e exigências de dados, antes de fechar a implementação do pagamento; não tratar compatibilidade como já comprovada.

## 12. Referências técnicas

- [Turbo Streams](https://turbo.hotwired.dev/handbook/streams): atualização parcial da interface.
- [Rails Action Cable](https://guides.rubyonrails.org/action_cable_overview.html): atualizações via WebSocket.
- [Rails Active Job / Solid Queue](https://guides.rubyonrails.org/active_job_basics.html): tarefas persistentes.
- [Mercado Pago — Pix via Orders](https://www.mercadopago.com.br/developers/pt/docs/checkout-api-orders/payment-integration/websites/pix): dados obrigatórios, idempotência e QR Pix.
- [Mercado Pago — QR presencial](https://www.mercadopago.com.br/developers/pt/reference/in-person-payments/qr-code/overview): modalidade presencial e aplicativo do pagador.
- [Mercado Pago — notificações](https://www.mercadopago.com.br/developers/pt/docs/checkout-pro-preferences/payment-notifications): referência geral; implementar assinatura e eventos conforme a modalidade efetivamente selecionada.
- Referências locais examinadas: `AABB/app/services/mercado_pago/pix_service.rb`, `AABB/app/controllers/webhooks/mercado_pago_controller.rb`, `AABB/app/jobs/process_mercado_pago_payment_job.rb`, `fish-record/FishRecord-Api/config/deploy.yml`, `fish-record/FishRecord-Api/config/deploy.production.yml` e `KoupZelo/compose.production.yml`.
