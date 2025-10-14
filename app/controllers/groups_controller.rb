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
    @mentors = Person.where(role: Person.role_name_to_value('mentor')).where(state: Person.state_id(:waiting))
  end

  # GET /groups/1/edit
  def edit
    @mentees = @group.mentees + Person.where(role: Person.role_name_to_value('mentee')).where(state: Person.state_id(:waiting))
    @mentors = @group.mentors + Person.where(role: Person.role_name_to_value('mentor')).where(state: Person.state_id(:waiting))
  end

  # POST /groups
  def create
    @group = Group.new
    mentor_ids = params.dig(:group, :mentor_ids) || []
    mentors = assignable_people(mentor_ids)

    if mentors.empty?
      flash[:alert] = "You must select at least one mentor."
      redirect_to new_group_path(@group) and return
    end

    @group.mentor_ids = mentors

    if @group.save
      PersonStateAligner.align_state
      redirect_to @group, notice: 'Group was successfully created.'
    else
      @mentors = Person.where(role: 2).where(state: 3)
      flash[:alert] = "You have to select a mentor."
      render :new
    end
  end

  # PATCH/PUT /groups/1
  def update
    mentee_ids = params.dig(:group, :mentee_ids) || []
    mentor_ids = params.dig(:group, :mentor_ids) || []
    
    filtered_mentees = assignable_people(mentee_ids, @group.id)
    filtered_mentors = assignable_people(mentor_ids, @group.id)

    if filtered_mentors.empty?
      flash[:alert] = "You must select at least one mentor."
      redirect_to edit_group_path(@group) and return
    end

    people_ids = filtered_mentees + filtered_mentors

    if @group.update(mentee_ids: people_ids)
      PersonStateAligner.align_state
      redirect_to edit_group_path(@group), notice: 'Group was successfully updated.'
    else
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

    people = @group.mentors + @group.mentees

    people.each do |p|
      p.state_name = :done
      p.save
    end

    @group.mentors.each do |mentor|
      PersonMailer.with(mentor: mentor).your_mentees.deliver_now
    end

    redirect_to @group, notice: 'Group was successfully updated to done and an email was sent to groups mentor(s).'
  end

  def batch_create_groups
    mentors_without_groups = Person.where(role: Person.role_name_to_value('mentor')).where(group_id: nil)
    count = mentors_without_groups.size

    if count == 0
      redirect_to groups_path, notice: "No mentors without groups found." and return
    end
  
    mentors_without_groups.each do |mentor|
      Group.create(mentors: [mentor])
    end
  
    redirect_to groups_path, notice: "#{count} groups were successfully created. Now back to work!"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group
      @group = Group.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def group_params
      params.require(:group).permit(:mentor_ids, :entee_ids)
    end

    def assignable_people(people_ids, group_id = nil)
      assignable_people = []

      if people_ids.nil?
        return assignable_people
      end

      people_ids.each do |person_id|
        person = Person.find(person_id)
        if person.group_id.nil? || (group_id.present? && person.group_id == group_id)
          assignable_people << person_id
        end
      end
      assignable_people
    end
end
