# frozen_string_literal: true

class DesManufacturer < ActiveRecord::Base
  belongs_to :creator,
             class_name: "User",
             foreign_key: "created_by",
             optional: true
  belongs_to :logo,
             class_name: "Upload",
             foreign_key: "logo_upload_id",
             optional: true
  has_many :car_models,
           class_name: "DesCarModel",
           foreign_key: "manufacturer_id"
  has_many :upload_references, as: :target, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending approved rejected] }

  after_save :update_logo_upload_reference, if: :saved_change_to_logo_upload_id?

  scope :approved, -> { where(status: "approved") }
  scope :pending, -> { where(status: "pending") }

  def approve!
    update!(status: "approved")
  end

  def reject!
    update!(status: "rejected")
  end

  private

  # Without an UploadReference, Jobs::CleanUpUploads treats the logo as orphaned and deletes it.
  def update_logo_upload_reference
    UploadReference.ensure_exist!(
      upload_ids: [logo_upload_id].compact,
      target: self
    )
  end
end
