class GroupsController < ApplicationController
  before_action :require_godmother
  before_action :set_group, only: [:show, :edit, :update, :destroy, :done]

  # GET /groups
  def index
    @groups = Group.all
  end

  # GET /groups/1
  def show
  end

  # GET /groups/new
  def new
    @group = Group.new
    @mentors = Person.where(role: Person.role_name_to_value('mentor')).where(state: Person.state_id(:waiting)).where(has_conference_ticket: true)
  end

  # GET /groups/1/edit
  def edit
    @mentees = @group.mentees + Person.where(role: Person.role_name_to_value('mentee')).where(state: Person.state_id(:waiting)).where(has_conference_ticket: true)
    @mentors = (@group.mentor ? [@group.mentor] : []) + Person.where(role: Person.role_name_to_value('mentor')).where(state: Person.state_id(:waiting)).where(has_conference_ticket: true)
  end

  # POST /groups
  def create
    @group = Group.new(label: params.dig(:group, :label))
    mentor_id = params.dig(:group, :mentor_id)

    if mentor_id.blank?
      flash[:alert] = "You must select a mentor."
      redirect_to new_group_path(@group) and return
    end

    # Validate that the mentor is assignable
    assignable_mentors = assignable_people([mentor_id])
    if assignable_mentors.empty?
      flash[:alert] = "Selected mentor is not available."
      redirect_to new_group_path(@group) and return
    end

    @group.mentor_id = mentor_id

    if @group.save
      PersonStateAligner.align_state
      redirect_to @group, notice: 'Group was successfully created.'
    else
      @mentors = Person.where(role: Person.role_name_to_value('mentor')).where(state: Person.state_id(:waiting)).where(has_conference_ticket: true)
      flash.now[:alert] = @group.errors.full_messages.join(', ')
      render :new
    end
  end

  # PATCH/PUT /groups/1
  def update
    mentee_ids = params.dig(:group, :mentee_ids) || []
    mentor_id = params.dig(:group, :mentor_id)

    filtered_mentees = assignable_people(mentee_ids, @group.id)

    if mentor_id.blank?
      flash[:alert] = "You must select a mentor."
      redirect_to edit_group_path(@group) and return
    end

    # Validate that the mentor is assignable
    filtered_mentors = assignable_people([mentor_id], @group.id)
    if filtered_mentors.empty?
      flash[:alert] = "Selected mentor is not available."
      redirect_to edit_group_path(@group) and return
    end

    people_ids = filtered_mentees

    if @group.update(label: params.dig(:group, :label), mentor_id: mentor_id, mentee_ids: people_ids)
      PersonStateAligner.align_state
      redirect_to edit_group_path(@group), notice: 'Group was successfully updated.'
    else
      @mentees = @group.mentees + Person.where(role: Person.role_name_to_value('mentee')).where(state: Person.state_id(:waiting)).where(has_conference_ticket: true)
      @mentors = (@group.mentor ? [@group.mentor] : []) + Person.where(role: Person.role_name_to_value('mentor')).where(state: Person.state_id(:waiting)).where(has_conference_ticket: true)
      flash.now[:alert] = @group.errors.full_messages.join(', ')
      render :edit
    end
  end

  # DELETE /groups/1
  def destroy
    @group.destroy
    redirect_to groups_url, notice: 'Group was successfully destroyed.'
  end

  def done
    if @group.mentees.empty?
      flash[:alert] = 'Group must have at least one mentee.'
      redirect_to @group and return
    end

    people = (@group.mentor ? [@group.mentor] : []) + @group.mentees

    people.each do |p|
      p.state_name = :done
      p.save
    end

    if @group.mentor
      PersonMailer.with(mentor: @group.mentor).your_mentees.deliver_now
    end

    redirect_to @group, notice: 'Group was successfully updated to done and an email was sent to the group mentor.'
  end

  def batch_create_groups
    mentors_without_groups = Person.where(role: Person.role_name_to_value('mentor')).where(group_id: nil).where(has_conference_ticket: true)
    count = mentors_without_groups.size

    if count == 0
      redirect_to groups_path, notice: "No mentors without groups found." and return
    end

    mentors_without_groups.each do |mentor|
      Group.create(mentor: mentor)
    end

    redirect_to groups_path, notice: "#{count} groups were successfully created. Now back to work!"
  end

  def csv_batch_create_groups
    # Show the upload form
  end

  def csv_batch_create_groups_process
    require 'csv'

    unless params[:csv_file].present?
      flash[:alert] = "Please select a CSV file to upload."
      redirect_to csv_batch_create_groups_path and return
    end

    begin
      csv_text = params[:csv_file].read
      csv = CSV.parse(csv_text, headers: true, col_sep: ';')

      # Group rows by "Group ID" column
      groups_data = {}
      errors = []

      csv.each_with_index do |row, index|
        random_id = row['Random ID']
        group_label = row['Group Label']

        unless random_id.present? && group_label.present?
          errors << "Row #{index + 2}: Missing required fields (Random ID or Group Label)"
          next
        end

        # Find the person in the database by random_id
        person = Person.find_by(random_id: random_id)
        unless person
          errors << "Row #{index + 2}: Person with Random ID '#{random_id}' not found in database"
          next
        end

        # Initialize group data if not exists
        groups_data[group_label] ||= { mentors: [], mentees: [] }

        # Add person to appropriate role list based on their database role
        if person.role_name == 'mentor'
          groups_data[group_label][:mentors] << person
        elsif person.role_name == 'mentee'
          groups_data[group_label][:mentees] << person
        else
          errors << "Row #{index + 2}: Person '#{random_id}' has invalid role '#{person.role_name}' (must be mentor or mentee)"
        end
      end

      # Validate groups structure
      groups_data.each do |label, data|
        if data[:mentors].empty?
          errors << "Group '#{label}': Must have at least one mentor"
        elsif data[:mentors].size > 1
          errors << "Group '#{label}': Must have exactly one mentor (found #{data[:mentors].size})"
        end

        if data[:mentees].empty?
          errors << "Group '#{label}': Must have at least one mentee"
        end
      end

      if errors.any?
        flash[:alert] = "CSV validation failed:\n" + errors.join("\n")
        redirect_to csv_batch_create_groups_path and return
      end

      # Delete all existing groups
      Group.destroy_all

      # Create new groups
      created_count = 0
      groups_data.each do |label, data|
        group = Group.new(label: label)
        group.mentor_id = data[:mentors].first&.id
        group.mentee_ids = data[:mentees].map(&:id)

        if group.save
          created_count += 1
        else
          errors << "Failed to create group '#{label}': #{group.errors.full_messages.join(', ')}"
        end
      end

      # Align person states
      PersonStateAligner.align_state

      if errors.any?
        flash[:alert] = "Some groups could not be created:\n" + errors.join("\n")
      else
        flash[:notice] = "Successfully created #{created_count} groups from CSV file."
      end

      redirect_to groups_path

    rescue CSV::MalformedCSVError => e
      flash[:alert] = "Invalid CSV file format: #{e.message}"
      redirect_to csv_batch_create_groups_path
    rescue => e
      flash[:alert] = "Error processing CSV file: #{e.message}"
      redirect_to csv_batch_create_groups_path
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group
      @group = Group.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def group_params
      params.require(:group).permit(:label, :mentor_ids, :entee_ids)
    end

    def assignable_people(people_ids, group_id = nil)
      assignable_people = []

      if people_ids.nil?
        return assignable_people
      end

      people_ids.each do |person_id|
        person = Person.find(person_id)
        if person.has_conference_ticket && (person.group_id.nil? || (group_id.present? && person.group_id == group_id))
          assignable_people << person_id
        end
      end
      assignable_people
    end
end
