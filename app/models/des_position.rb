class DesPosition < ActiveRecord::Base
  has_many :des_organisation_members

  validates :name, presence: true, uniqueness: true

  scope :admin_positions, -> { where(is_admin: true) }
  scope :non_admin_positions, -> { where(is_admin: false) }
end
