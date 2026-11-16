class ReconcileOpenPixOrdersJob < ApplicationJob
  queue_as :default

  def perform
    PaymentAttempt.open.find_each do |attempt|
      if attempt.external_order_id.present?
        ProcessMercadoPagoOrderJob.perform_later(attempt.external_order_id)
      elsif attempt.status == "unknown"
        RetryMercadoPagoCreationJob.perform_later(attempt.id)
      end
    end
  end
end
