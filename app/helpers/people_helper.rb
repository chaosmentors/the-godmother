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
end
