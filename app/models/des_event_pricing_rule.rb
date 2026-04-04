class DesEventPricingRule < ActiveRecord::Base
  belongs_to :event, class_name: 'DesEvent', foreign_key: 'event_id'

  validates :event_id, presence: true
  validates :rule_type, inclusion: { in: %w[flat tiered] }
  validates :flat_price, presence: true, if: -> { rule_type == 'flat' }
  validates :first_class_price, presence: true, if: -> { rule_type == 'tiered' }
  validates :subsequent_class_price, presence: true, if: -> { rule_type == 'tiered' }

  def calculate_price(number_of_classes)
    case rule_type
    when 'flat'
      flat_price * number_of_classes
    when 'tiered'
      return 0 if number_of_classes == 0
      first_class_price + (subsequent_class_price * (number_of_classes - 1))
    end
  end

  def price_breakdown(number_of_classes)
    case rule_type
    when 'flat'
      {
        classes: number_of_classes,
        price_per_class: flat_price,
        total: flat_price * number_of_classes
      }
    when 'tiered'
      subsequent = number_of_classes - 1
      {
        classes: number_of_classes,
        first_class_price: first_class_price,
        subsequent_classes: subsequent,
        subsequent_class_price: subsequent_class_price,
        total: first_class_price + (subsequent_class_price * subsequent)
      }
    end
  end
end
