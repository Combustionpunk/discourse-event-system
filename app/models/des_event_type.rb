class DesEventType < ActiveRecord::Base
  has_many :des_events

  validates :name, presence: true, uniqueness: true
end
