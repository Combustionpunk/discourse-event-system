class DesOrganisationMembership < ActiveRecord::Base
  belongs_to :organisation, class_name: 'DesOrganisation', foreign_key: 'organisation_id'
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  belongs_to :membership_type, class_name: 'DesOrganisationMembershipType', foreign_key: 'membership_type_id'
  has_many :payments, class_name: 'DesMembershipPayment', foreign_key: 'membership_id'

  validates :organisation_id, presence: true
  validates :user_id, presence: true
  validates :membership_type_id, presence: true
  validates :starts_at, presence: true
  validates :expires_at, presence: true
  validates :status, inclusion: { in: %w[active expired cancelled] }

  scope :active, -> { where(status: 'active').where('expires_at > ?', Time.now) }
  scope :expired, -> { where(status: 'expired') }
  scope :expiring_soon, -> { where(status: 'active').where('expires_at < ?', 30.days.from_now) }

  def active?
    status == 'active' && expires_at > Time.now
  end

  def expired?
    expires_at < Time.now
  end

  def days_until_expiry
    ((expires_at - Time.now) / 1.day).to_i
  end

  def discount_percentage
    membership_type.discount_percentage
  end

  def expire!
    update!(status: 'expired')
  end

  def cancel!
    update!(status: 'cancelled')
  end

  def renew!
    update!(
      starts_at: expires_at,
      expires_at: membership_type.expiry_date_from(expires_at),
      status: 'active'
    )
  end
end
