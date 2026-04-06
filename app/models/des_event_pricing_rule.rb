# frozen_string_literal: true
class DesEventPricingRule < ActiveRecord::Base
  belongs_to :event, class_name: 'DesEvent', foreign_key: 'event_id'

  validates :event_id, presence: true
  validates :rule_type, inclusion: { in: %w[flat tiered] }

  def calculate_price(num_classes)
    return 0 if num_classes == 0
    case rule_type
    when 'flat'
      flat_price.to_f * num_classes
    when 'tiered'
      return first_class_price.to_f if num_classes == 1
      first_class_price.to_f + (subsequent_class_price.to_f * (num_classes - 1))
    end
  end

  def calculate_discounted_price(num_classes, is_member, is_junior)
    return 0 if num_classes == 0

    first_discount = 0
    subsequent_discount = 0

    if is_member
      first_discount += member_first_class_discount.to_f
      subsequent_discount += member_subsequent_discount.to_f
    end

    if is_junior
      first_discount += junior_first_class_discount.to_f
      subsequent_discount += junior_subsequent_discount.to_f
    end

    case rule_type
    when 'flat'
      base = flat_price.to_f
      first = [base - first_discount, 0].max
      subsequent = [base - subsequent_discount, 0].max
      return first if num_classes == 1
      first + (subsequent * (num_classes - 1))
    when 'tiered'
      first = [first_class_price.to_f - first_discount, 0].max
      subsequent = [subsequent_class_price.to_f - subsequent_discount, 0].max
      return first if num_classes == 1
      first + (subsequent * (num_classes - 1))
    end
  end
end
