class DesEventClassType < ActiveRecord::Base
  has_many :des_event_classes

  validates :name, presence: true, uniqueness: true
end
