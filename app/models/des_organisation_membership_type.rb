class DesOrganisationMembershipType < ActiveRecord::Base
  belongs_to :organisation, class_name: 'DesOrganisation', foreign_key: 'organisation_id'
  has_many :memberships, class_name: 'DesOrganisationMembership', foreign_key: 'membership_type_id'

  validates :organisation_id, presence: true
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :duration_months, presence: true, numericality: { greater_than: 0 }
  validates :discount_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :active, -> { where(active: true) }

  def annual?
    duration_months == 12
  end

  def expiry_date_from(start_date)
    start_date + duration_months.months
  end
end
