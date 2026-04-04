class DesEventDiscount < ActiveRecord::Base
  belongs_to :event, class_name: 'DesEvent', foreign_key: 'event_id'
  has_many :conditions, class_name: 'DesEventDiscountCondition', foreign_key: 'discount_id'

  validates :event_id, presence: true
  validates :name, presence: true
  validates :discount_type, inclusion: { in: %w[percentage fixed] }
  validates :value, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }

  def apply_discount(amount)
    case discount_type
    when 'percentage'
      amount - (amount * (value / 100))
    when 'fixed'
      [amount - value, 0].max
    end
  end

  def eligible?(user, number_of_classes, event)
    return false unless active?
    conditions.all? { |condition| condition.met_by?(user, number_of_classes, event) }
  end

  def description
    case discount_type
    when 'percentage'
      "#{value}% off"
    when 'fixed'
      "£#{value} off"
    end
  end
end
