class DesOrganisationMember < ActiveRecord::Base
  belongs_to :organisation, class_name: 'DesOrganisation', foreign_key: 'organisation_id'
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  belongs_to :position, class_name: 'DesPosition', foreign_key: 'position_id'

  validates :organisation_id, presence: true
  validates :user_id, presence: true
  validates :position_id, presence: true
  validates :user_id, uniqueness: { scope: [:organisation_id, :position_id], 
            message: 'already holds this position at this organisation' }
  validates :status, inclusion: { in: %w[active inactive] }

  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }

  def deactivate!
    update!(status: 'inactive')
  end

  def activate!
    update!(status: 'active')
  end
end
