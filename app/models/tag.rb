class Tag < ApplicationRecord
  has_many :taggings
  has_many :people, through: :taggings

  scope :ml_generated, -> { where(ml_generated: true) }
  scope :not_ml_generated, -> { where(ml_generated: false) }

  validates :ml_generated, inclusion: { in: [true, false] }

  def ml_generated?
    ml_generated
  end
end