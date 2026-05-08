# frozen_string_literal: true

class DesManufacturer < ActiveRecord::Base
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by', optional: true
  belongs_to :logo, class_name: 'Upload', foreign_key: 'logo_upload_id', optional: true
  has_many :car_models, class_name: 'DesCarModel', foreign_key: 'manufacturer_id'

  validates :name, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending approved rejected] }

  after_save :retain_logo_upload
  before_update :unretain_old_logo_upload

  scope :approved, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }

  def approve!
    update!(status: 'approved')
  end

  def reject!
    update!(status: 'rejected')
  end

  private

  def retain_logo_upload
    return unless logo_upload_id.present?
    Upload.find_by(id: logo_upload_id)&.retain!
  end

  def unretain_old_logo_upload
    return unless logo_upload_id_changed? && logo_upload_id_was.present?
    Upload.find_by(id: logo_upload_id_was)&.unretain!
  end
end
