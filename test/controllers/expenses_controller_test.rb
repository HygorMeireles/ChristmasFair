require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  test "creates a paid expense" do
    assert_difference "Expense.count", 1 do
      post expenses_url, params: {
        expense: {
          description: "Brownie ingredients",
          category: "ingredients",
          amount_brl: "80,50",
          incurred_on: Date.current,
          status: "paid",
          notes: "First batch"
        }
      }
    end

    expense = Expense.last
    assert_equal 8_050, expense.amount_cents
    assert_equal Date.current, expense.paid_on
    assert_redirected_to financial_url(locale: "pt-BR")
  end

  test "creates a pending expense without a payment date" do
    post expenses_url, params: {
      expense: {
        description: "Decoration",
        category: "decoration",
        amount_brl: "25.00",
        incurred_on: Date.current,
        status: "pending"
      }
    }

    assert_nil Expense.last.paid_on
  end

  test "marks a pending expense as paid" do
    expense = Expense.create!(
      description: "Toys",
      category: "toys",
      amount_cents: 5_000,
      incurred_on: Date.current,
      status: "pending"
    )

    patch mark_paid_expense_url(expense)

    assert_predicate expense.reload, :paid?
    assert_equal Date.current, expense.paid_on
    assert_redirected_to financial_url(locale: "pt-BR")
  end
end
