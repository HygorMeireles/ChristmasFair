require "test_helper"

class FinancialControllerTest < ActionDispatch::IntegrationTest
  setup do
    brownie = products(:brownie)
    brownie.update!(stock_quantity: 0)
    Inventory::CreateStockBatch.call(
      product: brownie,
      description: "Costed tray",
      quantity: 10,
      total_cost_brl: "4.00",
      received_on: Date.current.to_s,
      register_expense: false
    )
    Checkout::CompleteCashSale.call(
      quantities: { brownie: 2 },
      amount_received_brl: "10.00",
      checkout_token: SecureRandom.uuid
    )
    Expense.create!(
      description: "Ingredients",
      category: "ingredients",
      amount_cents: 400,
      incurred_on: Date.current,
      status: "paid",
      paid_on: Date.current
    )
    Expense.create!(
      description: "Decoration",
      category: "decoration",
      amount_cents: 200,
      incurred_on: Date.current,
      status: "pending"
    )
  end

  test "shows sales expenses and the resulting cash balance" do
    get financial_url

    assert_response :success
    assert_select ".financial-overview article", 4
    assert_select ".financial-metrics article", 5
    assert_select ".financial-metrics strong", text: "R$10,00"
    assert_select ".financial-overview strong", text: "R$4,00"
    assert_select ".financial-overview strong", text: "R$6,00"
    assert_select ".financial-metrics strong", text: "R$2,00"
    assert_select ".financial-metrics strong", text: "R$9,20"
    assert_select ".performance-list", /2 itens vendidos/
    assert_select ".finance-table tbody tr", 1
    assert_select ".expense-list article", 2
    assert_select "details.expense-management", 1
  end
end
