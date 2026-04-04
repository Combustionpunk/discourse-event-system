# frozen_string_literal: true

class DesManufacturer < ActiveRecord::Base
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by', optional: true
  has_many :car_models, class_name: 'DesCarModel', foreign_key: 'manufacturer_id'

  validates :name, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending approved rejected] }

  scope :approved, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }

  def approve!
    update!(status: 'approved')
  end

  def reject!
    update!(status: 'rejected')
  end
end
