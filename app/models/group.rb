class Group < ApplicationRecord
  belongs_to :mentor, class_name: 'Person', optional: true
  has_many :mentees, -> { where(role: Person.role_name_to_value('mentee')) }, class_name: 'Person', foreign_key: 'group_id'

  validates :mentor, presence: true
  validates :label, presence: true, uniqueness: true

  before_destroy :remove_group_id_from_persons
  after_destroy :align_person_states
  after_save :update_mentor_group_id

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
  end

  def align_person_states
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