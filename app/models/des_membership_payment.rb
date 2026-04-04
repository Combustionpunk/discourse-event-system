class DesMembershipPayment < ActiveRecord::Base
  belongs_to :membership, class_name: 'DesOrganisationMembership', foreign_key: 'membership_id'
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  belongs_to :organisation, class_name: 'DesOrganisation', foreign_key: 'organisation_id'

  validates :membership_id, presence: true
  validates :user_id, presence: true
  validates :organisation_id, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending completed failed] }

  scope :completed, -> { where(status: 'completed') }
  scope :pending, -> { where(status: 'pending') }

  def complete!(paypal_capture_id)
    update!(
      status: 'completed',
      paypal_capture_id: paypal_capture_id
    )
    membership.update!(status: 'active')
  end

  def fail!
    update!(status: 'failed')
    membership.cancel!
  end
end
