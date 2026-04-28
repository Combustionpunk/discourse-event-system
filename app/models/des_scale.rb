# frozen_string_literal: true

class DesScale < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
end
