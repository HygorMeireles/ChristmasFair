class ExpensesController < ApplicationController
  def create
    expense = Expense.new(expense_params)
    normalize_paid_on(expense)

    if expense.save
      redirect_to financial_path, notice: t("expenses.created")
    else
      redirect_to financial_path, alert: expense.errors.full_messages.to_sentence
    end
  end

  def mark_paid
    expense = Expense.find(params[:id])
    expense.with_lock do
      expense.update!(status: "paid", paid_on: expense.paid_on || Date.current) unless expense.paid?
    end

    redirect_to financial_path, notice: t("expenses.marked_paid")
  end

  private

  def expense_params
    params.require(:expense).permit(:description, :category, :amount_brl, :incurred_on, :status, :paid_on, :notes)
  end

  def normalize_paid_on(expense)
    expense.paid_on = nil unless expense.paid?
    expense.paid_on ||= Date.current if expense.paid?
  end
end
