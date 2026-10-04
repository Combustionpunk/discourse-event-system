# frozen_string_literal: true

# Merges one car model (the source) into another (the target): everything that
# references the source is repointed at the target, then the source is deleted.
#
# References to des_car_models:
# - des_user_cars.car_model_id (and through those, des_event_booking_classes.car_id)
# - des_event_class_types.model_id
# - des_class_compatibility_rules.rule_value where rule_type = 'model'
# - des_car_model_image_suggestions.car_model_id
# - box art (des_car_models.box_art_upload_id + its UploadReference)
# Result entries have no link to a car, so there is nothing to move there.
class DesCarModelMergeService
  attr_reader :source, :target

  def initialize(source, target)
    raise Discourse::InvalidParameters.new(:target_id) if source.id == target.id
    @source = source
    @target = target
  end

  def preview
    {
      source: summary(source),
      target: summary(target),
      garage_entries: source_cars.count,
      duplicate_garage_entries: duplicate_cars.count,
      bookings:
        DesEventBookingClass.where(car_id: source_cars.select(:id)).count,
      class_types: DesEventClassType.where(model_id: source.id).count,
      compatibility_rules: model_rules.count,
      image_suggestions: source.image_suggestions.count,
      box_art: box_art_outcome
    }
  end

  def merge!(acting_user)
    details = preview

    ActiveRecord::Base.transaction do
      merge_garage_cars
      DesEventClassType.where(model_id: source.id).update_all(
        model_id: target.id
      )
      model_rules.update_all(rule_value: target.id.to_s)
      merge_image_suggestions
      if box_art_outcome == "source"
        target.update!(box_art_upload_id: source.box_art_upload_id)
      end
      source.reload.destroy!
    end

    StaffActionLogger.new(acting_user).log_custom(
      "des_merge_car_models",
      details.except(:source, :target).merge(
        source_id: source.id,
        source_name: details[:source][:label],
        target_id: target.id,
        target_name: details[:target][:label]
      )
    )
    details
  end

  private

  def summary(model)
    {
      id: model.id,
      label: [model.manufacturer&.name, model.name].compact.join(" ")
    }
  end

  def box_art_outcome
    if target.box_art_upload_id.present?
      "target"
    elsif source.box_art_upload_id.present?
      "source"
    else
      "none"
    end
  end

  def source_cars
    DesUserCar.where(car_model_id: source.id)
  end

  def model_rules
    DesClassCompatibilityRule.where(
      rule_type: "model",
      rule_value: source.id.to_s
    )
  end

  # Active source cars whose owner already has an active car of the target model.
  def duplicate_cars
    source_cars.active.where(
      user_id: DesUserCar.active.where(car_model_id: target.id).select(:user_id)
    )
  end

  # A user who already has the target model keeps that car; bookings made with the
  # duplicate move onto it and the duplicate is retired rather than deleted.
  def merge_garage_cars
    duplicate_cars.find_each do |duplicate|
      kept =
        DesUserCar
          .active
          .where(user_id: duplicate.user_id, car_model_id: target.id)
          .order(:id)
          .first
      DesEventBookingClass.where(car_id: duplicate.id).update_all(
        car_id: kept.id
      )
      duplicate.update_columns(status: "inactive")
    end

    source_cars.update_all(
      car_model_id: target.id,
      manufacturer_id: target.manufacturer_id,
      updated_at: Time.zone.now
    )
  end

  # Only one pending suggestion per user per model is allowed, so a user's pending
  # suggestion on the source is rejected if they already have one on the target.
  def merge_image_suggestions
    target_pending_users = target.image_suggestions.pending.select(:user_id)
    source
      .image_suggestions
      .pending
      .where(user_id: target_pending_users)
      .find_each(&:reject!)
    source.image_suggestions.update_all(car_model_id: target.id)
  end
end
