module GroupsHelper
  def group_state_badge(group)
    if group.done?
      content_tag(:span, 'Done', class: 'badge badge-success')
    else
      content_tag(:span, 'In Progress', class: 'badge badge-warning')
    end
  end
end
