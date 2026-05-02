# frozen_string_literal: true

class DesEventPayout < ActiveRecord::Base
  belongs_to :des_event, foreign_key: :event_id
  belongs_to :organisation, class_name: 'DesOrganisation', foreign_key: :organisation_id

  STATUSES = %w[pending approved claimed paid failed].freeze

  validates :event_id, presence: true, uniqueness: true
  validates :organisation_id, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :net_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :net_cannot_exceed_gross

  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :claimed, -> { where(status: 'claimed') }
  scope :paid, -> { where(status: 'paid') }
  scope :unpaid, -> { where.not(status: 'paid') }

  private

  def net_cannot_exceed_gross
    if net_amount.present? && gross_amount.present?
      errors.add(:net_amount, 'cannot exceed gross amount') if net_amount >= gross_amount
    end
  end
end
