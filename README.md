# Mister Wiz Christmas Fair

Caixa e controle de estoque para a Christmas Fair de 5 de dezembro de 2026. A aplicação acompanha brownie, chocolate quente e ingressos da pescaria, com uma interface natalina bilíngue em português e inglês.

O estado atual contém:

- catálogo configurável, sem preços ou quantidades fixados no código;
- estoque em unidades e mililitros, com histórico de movimentações;
- capacidade da garrafa e tamanho do copo configuráveis;
- tela de caixa com carrinho local e animações de estoque projetado;
- pedidos persistidos com itens e valores históricos;
- recebimento em dinheiro, cálculo de troco e baixa transacional do estoque;
- proteção contra confirmação repetida e venda acima do saldo disponível;
- ingressos individuais da pescaria, com controle de retirada e bloqueio de resgate duplicado;
- painel financeiro com vendas confirmadas, despesas pagas ou pendentes e saldo de caixa;
- despesas categorizadas entre ingredientes, embalagens, brinquedos, decoração e outros;
- confirmação do pedido antes de liberar a etapa de pagamento;
- lotes de estoque com custo, consumo por ordem de entrada e margem apurada somente para itens com custo conhecido;
- pedido Pix pendente com reserva de estoque, QR dinâmico e confirmação idempotente por webhook;
- cancelamento seguro da cobrança Pix com liberação da reserva somente após confirmação do Mercado Pago;
- acesso protegido por senha para caixa, estoque e financeiro;
- taxa configurável do Mercado Pago, saldo Pix líquido e saldo em dinheiro separados;
- identidade Mister Wiz combinada com elementos de Natal;
- estrutura Rails preparada para pedidos e Mercado Pago em uma etapa posterior.

Ao confirmar um recebimento em dinheiro, a venda é registrada e o estoque persistido é reduzido. O Pix continua identificado como indisponível até a integração segura com o Mercado Pago.

## Tecnologias

- Ruby 3.4.1
- Rails 8.1
- PostgreSQL 16+
- Turbo, Stimulus, Solid Queue e Solid Cable

## Preparar o ambiente

```bash
bundle install
bin/rails db:prepare db:seed
bin/dev
```

Acesse:

- Caixa: <http://localhost:3000>
- Produtos e estoque: <http://localhost:3000/products>

A carga inicial cria os três produtos com preço e estoque zerados. Cadastre os valores reais na tela **Configurar estoque**. Para não misturar demonstração e operação, dados fictícios devem permanecer apenas no banco local de desenvolvimento.

## Verificação

```bash
bin/rails test
bin/rubocop
bin/brakeman --no-pager -q
```

## Credenciais

Arquivos `.env*`, chaves Rails e segredos do Kamal não entram no Git. As credenciais do Mercado Pago devem ser configuradas somente no servidor; nunca devem ser colocadas no JavaScript, nos commits ou em arquivos versionados.

O fluxo Pix usa a Orders API para QR presencial dinâmico. Configure no ambiente do servidor:

```text
MERCADO_PAGO_ACCESS_TOKEN=
MERCADO_PAGO_EXTERNAL_POS_ID=
MERCADO_PAGO_WEBHOOK_SECRET=
CHRISTMAS_FAIR_OPERATOR_PASSWORD=
```

O `external_pos_id` precisa corresponder a um caixa criado previamente na conta Mercado Pago. Configure o webhook de **Orders** para `https://SEU_DOMINIO/webhooks/mercado_pago`. Sem essas variáveis, a aplicação falha de forma explícita e não simula uma cobrança aprovada.

O escopo completo e o cronograma estão em [PLANO_DE_IMPLEMENTACAO.md](PLANO_DE_IMPLEMENTACAO.md).
