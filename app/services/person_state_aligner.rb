class PersonStateAligner
  def self.align_state
    states = [Person.state_id(:waiting), Person.state_id(:in_group), Person.state_id(:done)]
    Person.where(state: states).each do |person|
      person.save if person.align_group_state
    end
  end
end