# frozen_string_literal: true

class DesChassisType < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
end
