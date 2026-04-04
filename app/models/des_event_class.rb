class DesEventClass < ActiveRecord::Base
  belongs_to :event, class_name: 'DesEvent', foreign_key: 'event_id'
  belongs_to :class_type, class_name: 'DesEventClassType', foreign_key: 'class_type_id', optional: true

  validates :event_id, presence: true
  validates :name, presence: true
  validates :capacity, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[active inactive sold_out] }

  scope :active, -> { where(status: 'active') }
  scope :sold_out, -> { where(status: 'sold_out') }

  def spaces_remaining
    capacity - confirmed_bookings_count
  end

  def confirmed_bookings_count
    # We'll fill this in when we build the bookings model
    0
  end

  def sold_out?
    spaces_remaining <= 0
  end

  def update_status!
    if sold_out?
      update!(status: 'sold_out')
    else
      update!(status: 'active')
    end
  end
end
