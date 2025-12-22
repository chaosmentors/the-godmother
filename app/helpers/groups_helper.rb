module GroupsHelper
  def group_state_badge(group)
    if group.handed_off?
      content_tag(:span, 'Handed Off', class: 'badge badge-success')
    elsif group.done?
      content_tag(:span, 'Matched', class: 'badge badge-warning')
    else
      content_tag(:span, 'In Progress', class: 'badge badge-secondary')
    end
  end
end
