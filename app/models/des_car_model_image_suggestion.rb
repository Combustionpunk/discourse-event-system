# frozen_string_literal: true

class DesCarModelImageSuggestion < ActiveRecord::Base
  STATUSES = %w[pending approved rejected].freeze

  belongs_to :car_model, class_name: "DesCarModel"
  belongs_to :upload
  belongs_to :user
  has_many :upload_references, as: :target, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
  validates :user_id,
            uniqueness: {
              scope: :car_model_id,
              conditions: -> { where(status: "pending") }
            },
            if: :pending?
  validate :upload_is_image

  # Only a pending suggestion holds a reference; once approved the car model's own
  # reference keeps the image, and once rejected cleanup is free to remove it.
  after_save :sync_upload_reference

  scope :pending, -> { where(status: "pending") }

  def pending?
    status == "pending"
  end

  def approve!
    transaction do
      car_model.update!(box_art_upload_id: upload_id)
      update!(status: "approved")
    end
  end

  def reject!
    update!(status: "rejected")
  end

  private

  def sync_upload_reference
    UploadReference.ensure_exist!(
      upload_ids: pending? ? [upload_id] : [],
      target: self
    )
  end

  def upload_is_image
    if upload.blank? ||
         !FileHelper.is_supported_image?(upload.original_filename)
      errors.add(:upload_id, "must be an image upload")
    end
  end
end
