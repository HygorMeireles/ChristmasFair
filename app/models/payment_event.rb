class PaymentEvent < ApplicationRecord
  validates :event_key, presence: true, uniqueness: true
  validates :resource_id, presence: true
end
