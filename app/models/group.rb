class Group < ApplicationRecord
  belongs_to :mentor, class_name: 'Person', optional: true
  has_many :mentees, class_name: 'Person'

  validates :mentor, presence: true
  validates :label, presence: true, uniqueness: true

  before_destroy :remove_group_id_from_persons
  after_save :update_mentor_group_id

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

    if mentor.present?
      mentor.update_column(:group_id, nil)
    end

    PersonStateAligner.align_state
  end

  def update_mentor_group_id
    if saved_change_to_mentor_id?
      old_mentor_id, new_mentor_id = saved_change_to_mentor_id

      if old_mentor_id.present?
        old_mentor = Person.find_by(id: old_mentor_id)
        old_mentor&.update_column(:group_id, nil)
      end

      if new_mentor_id.present?
        mentor&.update_column(:group_id, self.id)
      end
    end
  end
end