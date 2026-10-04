# frozen_string_literal: true

# Proposes consistent capitalisation for car model names. Nothing is changed until
# apply! is called with the ids an admin ticked.
#
# Per word:
# - a word starting with a known model prefix and containing a digit is upper-cased
#   ("Xb4" -> "XB4", "Rc10b6.2" -> "RC10B6.2")
# - all-caps words are kept ("PTG-2")
# - anything else gets an upper-case first letter, leaving the rest alone so names
#   like "McRae" survive
class DesCarModelNameTidier
  def self.prefixes
    SiteSetting
      .des_car_model_name_prefixes
      .split("|")
      .map { |p| p.strip.upcase }
      .compact_blank
  end

  def self.tidy(name)
    prefixes = self.prefixes
    name
      .to_s
      .split(/(\s+)/)
      .map do |word|
        next word if word.blank?
        upper = word.upcase
        if word.match?(/\d/) &&
             prefixes.any? { |prefix| upper.start_with?(prefix) }
          upper
        elsif word == upper
          word
        else
          word[0].upcase + word[1..]
        end
      end
      .join
  end

  def preview
    models =
      DesCarModel
        .where.not(status: "rejected")
        .includes(:manufacturer)
        .order(:manufacturer_id, :name)
    names_by_manufacturer = models.group_by(&:manufacturer_id)

    models.filter_map do |model|
      proposed = self.class.tidy(model.name)
      next if proposed == model.name
      clash =
        names_by_manufacturer[model.manufacturer_id].find do |other|
          other.id != model.id && other.name.casecmp?(proposed)
        end
      {
        id: model.id,
        manufacturer_name: model.manufacturer&.name,
        current: model.name,
        proposed: proposed,
        duplicate_of:
          clash && { id: clash.id, name: clash.name, status: clash.status }
      }
    end
  end

  def apply!(ids, acting_user)
    changes = preview.select { |row| ids.map(&:to_i).include?(row[:id]) }
    ActiveRecord::Base.transaction do
      changes.each do |row|
        DesCarModel.find(row[:id]).update!(name: row[:proposed])
      end
    end
    if changes.any?
      StaffActionLogger.new(acting_user).log_custom(
        "des_tidy_car_model_names",
        changes:
          changes
            .map { |row| "#{row[:current]} → #{row[:proposed]}" }
            .join(", ")
      )
    end
    changes
  end
end
