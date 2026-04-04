# frozen_string_literal: true

class DesUserTransponder < ActiveRecord::Base
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  belongs_to :class_type, class_name: 'DesEventClassType', foreign_key: 'class_type_id'

  validates :user_id, presence: true
  validates :class_type_id, presence: true
  validates :transponder_number, presence: true
  validates :class_type_id, uniqueness: { scope: :user_id, message: 'already has a transponder for this class' }
end
