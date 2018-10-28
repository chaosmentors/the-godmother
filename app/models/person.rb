class Person < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :about, presence: true
end
