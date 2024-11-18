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

  def mentor_tags
    @mentor_tags ||= options[:mentor_tags]
  end

  def view_columns
    @view_columns ||= {
      id: { source: "Person.id", cond: :like },
      pronoun: { source: "Person.pronoun", cond: :like },
      name: { source: "Person.name", cond: :like, orderable: true },
      about: { source: "Person.about", cond: :like, nulls_last: true },
      email: { source: "Person.email", cond: :like },
      tags: { source: "Tag.name", cond: :like, orderable: false },
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
    persons = Person.includes(:tags)
      .where(role: Person.role_name_to_value(role))
      .where(state: Person.state_name_to_value(state))
      .references(:tags).distinct
    
    # Order by tag match count
    if mentor_tags.present? && params[:order]["0"][:column] == "5"
      mentor_tags_array = mentor_tags.split(',').map(&:strip)
      tag_ids = Tag.where(name: mentor_tags_array).pluck(:id)
  
      persons = persons.left_joins(:tags)
        .select("people.*, COUNT(CASE WHEN tags.id IN (#{tag_ids.join(',')}) THEN 1 ELSE NULL END) AS tag_match_count")
        .group('people.id')
      
      persons = Person.from(persons, :people).order("tag_match_count #{params[:order]["0"][:dir]}")
  
      if params[:search][:value].present?
        search_value = params[:search][:value]
        persons = persons.left_joins(:tags).where("CAST(people.id AS VARCHAR) ILIKE :search OR CAST(people.pronoun AS VARCHAR) ILIKE :search OR CAST(people.name AS VARCHAR) ILIKE :search OR CAST(people.about AS VARCHAR) ILIKE :search OR CAST(people.email AS VARCHAR) ILIKE :search OR CAST(tags.name AS VARCHAR) ILIKE :search", search: "%#{search_value}%").distinct
      end
    end

    persons
  end
end