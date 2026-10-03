# Partial update: only the attributes present in the request are validated.
class UpdateTicketValidator
  include ActiveModel::Model

  attr_accessor :title, :price

  validates :title, presence: true, if: -> { given?(:title) }
  validates :price, numericality: { greater_than: 0 }, if: -> { given?(:price) }

  def initialize(attributes = {})
    @given = attributes.keys.map(&:to_sym)
    super
  end

  private

  def given?(name) = @given.include?(name)
end
