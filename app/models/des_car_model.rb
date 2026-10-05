# frozen_string_literal: true

class DesCarModel < ActiveRecord::Base
  belongs_to :manufacturer,
             class_name: "DesManufacturer",
             foreign_key: "manufacturer_id"
  belongs_to :creator,
             class_name: "User",
             foreign_key: "created_by",
             optional: true
  has_many :user_cars, class_name: "DesUserCar", foreign_key: "car_model_id"
  belongs_to :box_art,
             class_name: "Upload",
             foreign_key: "box_art_upload_id",
             optional: true
  has_many :upload_references, as: :target, dependent: :destroy
  has_many :image_suggestions,
           class_name: "DesCarModelImageSuggestion",
           foreign_key: "car_model_id",
           dependent: :destroy

  DRIVELINES = ["2WD", "4WD", "FWD", "Rear Motor"].freeze
  SCALES = %w[1/8 1/10 1/12 1/28].freeze
  POWER_TYPES = %w[electric nitro petrol both].freeze
  BOX_ART_THUMBNAIL_WIDTH = 480

  CHASSIS_TYPES = [
    "Buggy",
    "Truck",
    "Stadium",
    "Short Course",
    "Touring Car",
    "Rally",
    "Pan Car",
    "Drift"
  ].freeze

  validates :manufacturer_id, presence: true
  validates :name, presence: true
  validates :status, inclusion: { in: %w[pending approved rejected] }
  validates :driveline, inclusion: { in: DRIVELINES }, allow_nil: true
  validates :scale, inclusion: { in: SCALES }, allow_nil: true
  validate :box_art_is_image

  after_save :update_box_art_upload_reference,
             if: :saved_change_to_box_art_upload_id?

  scope :approved, -> { where(status: "approved") }
  scope :pending, -> { where(status: "pending") }

  # Approved models plus the viewer's own pending suggestions; car model editors see everything.
  scope :visible_to,
        ->(guardian) do
          next all if guardian.can_edit_car_models?
          next approved unless guardian.authenticated?
          where(status: "approved").or(where(status: "pending", created_by: guardian.user.id))
        end

  # Unlike the list, a suggester can still open their own rejected model.
  def visible_to?(guardian)
    status == "approved" || guardian.can_edit_car_models? ||
      (guardian.authenticated? && created_by == guardian.user.id)
  end

  # Admins may attach any upload; suggesters only uploads they made themselves.
  def self.box_art_upload_id_for(upload_id, user)
    return if upload_id.blank?
    upload = Upload.find_by(id: upload_id)
    # Identical files are deduplicated to one upload, so check UserUpload for later uploaders.
    owned =
      upload &&
        (
          upload.user_id == user.id ||
            UserUpload.exists?(user_id: user.id, upload_id: upload.id)
        )
    if upload.nil? || (!user.admin? && !owned)
      raise Discourse::InvalidParameters.new(:box_art_upload_id)
    end
    upload.id
  end

  def box_art_thumbnail_url
    return if box_art.blank?
    thumbnail =
      box_art.optimized_images.find do |image|
        image.width == BOX_ART_THUMBNAIL_WIDTH
      end
    (thumbnail || box_art).url
  end

  private

  # Without an UploadReference, Jobs::CleanUpUploads treats the box art as orphaned and deletes it.
  def update_box_art_upload_reference
    UploadReference.ensure_exist!(
      upload_ids: [box_art_upload_id].compact,
      target: self
    )
    ensure_box_art_thumbnail
  end

  def ensure_box_art_thumbnail
    if box_art.blank? || box_art.width.to_i <= BOX_ART_THUMBNAIL_WIDTH ||
         box_art.height.to_i <= 0
      return
    end
    height =
      (box_art.height * BOX_ART_THUMBNAIL_WIDTH / box_art.width.to_f).round
    OptimizedImage.create_for(box_art, BOX_ART_THUMBNAIL_WIDTH, height)
  end

  def box_art_is_image
    if box_art_upload_id.blank? || !will_save_change_to_box_art_upload_id?
      return
    end
    if box_art.blank? ||
         !FileHelper.is_supported_image?(box_art.original_filename)
      errors.add(:box_art_upload_id, "must be an image upload")
    end
  end
end
