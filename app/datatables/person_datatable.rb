class PersonDatatable < AjaxDatatablesRails::ActiveRecord
  delegate :check_box_tag, :link_to, to: :@view 

  def initialize(params, opts = {})
    @view = opts[:view_context]
    super
  end

  def role
    @role ||= options[:role]
  end

  def state
    @state ||= options[:state]
  end

  def view_columns
    @view_columns ||= {
      id: { source: "Person.id", cond: :like },
      pronoun: { source: "Person.pronoun", cond: :like },
      name: { source: "Person.name", cond: :like, orderable: true },
      about: { source: "Person.about", cond: :like, nulls_last: true },
      email: { source: "Person.email", cond: :like },
      tags: { source: "Tag.name", cond: :like, nulls_last: true },
    }
  end

  def data
    records.map do |record|
      {
        id: check_box_tag("group[mentee_ids][]", record.id, false),
        pronoun: record.pronoun,
        name: link_to(record.name, record),
        about: record.about,
        email: record.email,
        tags: record.tags.map(&:name).join(', ')
      }
    end
  end

  def get_raw_records
    Person.includes(:tags)
      .where(role: Person.role_name_to_value(role))
      .where(state: Person.state_name_to_value(state))
      .references(:tags).distinct
  end

end