require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  test "converts a Brazilian currency value to cents" do
    expense = Expense.new(
      description: "Chocolate ingredients",
      category: "ingredients",
      amount_brl: "123,45",
      incurred_on: Date.current,
      status: "paid",
      paid_on: Date.current
    )

    assert_predicate expense, :valid?
    assert_equal 12_345, expense.amount_cents
  end

  test "requires a payment date for a paid expense" do
    expense = Expense.new(
      description: "Cups",
      category: "packaging",
      amount_cents: 1_000,
      incurred_on: Date.current,
      status: "paid"
    )

    assert_not expense.valid?
    assert expense.errors.of_kind?(:paid_on, :blank)
  end

  test "calculates the total from quantity, unit amount and discount" do
    expense = Expense.new(
      description: "Nescau 330 g",
      category: "ingredients",
      quantity: 3,
      unit_amount_brl: "9,35",
      discount_brl: "1,38",
      incurred_on: Date.current,
      status: "paid",
      paid_on: Date.current
    )

    assert_predicate expense, :valid?
    assert_equal 2_667, expense.amount_cents
  end
end
