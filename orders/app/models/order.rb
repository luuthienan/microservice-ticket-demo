class Order < ApplicationRecord
  enum :status, { created: "created", cancelled: "cancelled", complete: "complete" }

  belongs_to :ticket

  def as_json(*)
    { id:, status:, userId: user_id, expiresAt: expires_at, version: lock_version, ticket: }
  end
end
