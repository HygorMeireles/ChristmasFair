require "test_helper"

class FishingTicketsControllerTest < ActionDispatch::IntegrationTest
  setup do
    order = Checkout::CompleteCashSale.call(
      quantities: { fishing: 1 },
      amount_received_brl: "10.00",
      checkout_token: SecureRandom.uuid
    )
    @ticket = order.order_items.first.fishing_tickets.first
  end

  test "lists tickets awaiting prize pickup" do
    get fishing_tickets_url

    assert_response :success
    assert_select ".fishing-ticket.pending", 1
    assert_select ".ticket-identity strong", text: @ticket.code
    assert_select ".ticket-stats .pending strong", text: "1"
  end

  test "redeems a ticket only once" do
    patch redeem_fishing_ticket_url(@ticket)

    assert_redirected_to fishing_tickets_url(locale: "pt-BR")
    assert_predicate @ticket.reload, :redeemed?
    assert_not_nil @ticket.redeemed_at

    redeemed_at = @ticket.redeemed_at
    patch redeem_fishing_ticket_url(@ticket)

    assert_equal redeemed_at, @ticket.reload.redeemed_at
    follow_redirect!
    assert_select ".flash.alert", text: "Este ingresso já foi utilizado."
  end
end
