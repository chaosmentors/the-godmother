module PeopleHelper
  def tags
    Tag.where(active: true).map { |t| html_escape(t.name) }
  end

  def state_batches
    {
      unverified: 'secondary',
      verified: 'primary',
      okay: 'primary',
      waiting: 'warning',
      in_group: 'primary',
      declined: 'danger',
      done: 'success'
    }
  end

  def render_person_role(person)
    role = person.role_name.to_s.humanize
    role += ' + Godmother' if person.is_godmother && person.role_id != 3
    role
  end
end
