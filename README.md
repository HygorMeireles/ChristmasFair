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

Arquivos `.env*`, chaves Rails e segredos do Kamal não entram no Git. As credenciais do Mercado Pago serão configuradas no servidor quando a integração for implementada; nunca devem ser colocadas no JavaScript, nos commits ou em arquivos versionados.

O escopo completo e o cronograma estão em [PLANO_DE_IMPLEMENTACAO.md](PLANO_DE_IMPLEMENTACAO.md).
