class Group < ApplicationRecord
  has_many :mentors, class_name: 'Person'
  has_many :mentees, class_name: 'Person'

  validates :mentors, presence: true

  before_destroy :remove_group_id_from_persons

  def mentors
    Person.where(group_id: self.id).where(role: Person.role_name_to_value('mentor'))
  end

  def mentor_ids
    self.mentors.map { |m| m.id }
  end

  def mentees
    Person.where(group_id: self.id).where(role: Person.role_name_to_value('mentee'))
  end

  def mentee_ids
    self.mentees.map { |m| m.id }
  end

  private

  def remove_group_id_from_persons
    mentors.update_all(group_id: nil)
    mentees.update_all(group_id: nil)

    PersonStateAligner.align_state
  end
end