# An Event waiting to be sent to Kafka, written in the same transaction as the change it announces.
class OutboxEvent < ApplicationRecord
  scope :pending, -> { where(published_at: nil).order(:id) }
end
