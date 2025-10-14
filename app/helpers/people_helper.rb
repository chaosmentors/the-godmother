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

  def render_title_by_role(role)
    if Person::ROLES.value?(role.to_s.to_sym)
      role.to_s.humanize.pluralize(2)
    else
      'All People'
    end
  end

  def next_direction(column)
    if params[:sort_by] == column && params[:direction] == 'asc'
      'desc'
    else
      'asc'
    end
  end

  def sort_indicator(column)
    if params[:sort_by] == column
      if params[:direction] == 'asc'
        '↑'
      else
        '↓'
      end
    end
  end

  def render_conference_ticket_badge(person)
    if person.has_conference_ticket.nil?
      content_tag(:span, 'Not confirmed', class: 'badge badge-warning')
    elsif person.has_conference_ticket
      content_tag(:span, 'Yes', class: 'badge badge-success')
    else
      content_tag(:span, 'No', class: 'badge badge-secondary')
    end
  end
end
