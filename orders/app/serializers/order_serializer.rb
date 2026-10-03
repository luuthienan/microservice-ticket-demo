class OrderSerializer < ActiveModel::Serializer
  attributes :id, :status, :user_id, :expires_at, :version

  belongs_to :ticket

  def version = object.lock_version
end
