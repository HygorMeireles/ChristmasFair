class FishingTicketsController < ApplicationController
  def index
    @tickets = FishingTicket.includes(order_item: :order).recent_first
    @pending_count = @tickets.count(&:pending?)
    @redeemed_count = @tickets.count(&:redeemed?)
  end

  def redeem
    ticket = FishingTicket.find(params[:id])

    ticket.with_lock do
      if ticket.redeemed?
        redirect_to fishing_tickets_path, alert: t("fishing_tickets.already_redeemed")
        return
      end

      ticket.update!(status: "redeemed", redeemed_at: Time.current)
    end

    redirect_to fishing_tickets_path, notice: t("fishing_tickets.redeemed", code: ticket.code)
  end
end
