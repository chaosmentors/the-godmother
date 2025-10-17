class Group < ApplicationRecord
  belongs_to :mentor, class_name: 'Person', optional: true
  has_many :mentees, class_name: 'Person'

  validates :mentor, presence: true
  validates :label, presence: true, uniqueness: true

  before_destroy :remove_group_id_from_persons

  def mentees
    Person.where(group_id: self.id).where(role: Person.role_name_to_value('mentee'))
  end

  def mentee_ids
    self.mentees.map { |m| m.id }
  end

  def mentor_tags
    mentor&.tag_list || ''
  end

  def done?
    self.mentees.all? { |m| m.state == Person.state_id(:done) } &&
    (mentor.nil? || mentor.state == Person.state_id(:done))
  end

  private

  def remove_group_id_from_persons
    mentees.update_all(group_id: nil)

    PersonStateAligner.align_state
  end
end