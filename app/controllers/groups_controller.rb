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
    @mentors = Person.where("role = 2 OR role = 3").where(state: Person.state_id(:waiting))
  end

  # GET /groups/1/edit
  def edit
    @mentees = @group.mentees + Person.where(role: 1).where(state: Person.state_id(:waiting))
    @mentors = @group.mentors + Person.where("role = 2 OR role = 3").where(state: Person.state_id(:waiting))
  end

  # POST /groups
  def create
    @group = Group.new

    if params[:group].nil? || params[:group][:mentor_ids].blank?
      flash[:alert] = "You must select at least one mentor."
      redirect_to new_group_path(@group) and return
    end

    @group.mentor_ids = params[:group][:mentor_ids]

    if @group.save
      redirect_to @group, notice: 'Group was successfully created.'
    else
      @mentors = Person.where(role: 2).where(state: 3)
      flash[:alert] = "You have to select a mentor."
      render :new
    end
  end

  # PATCH/PUT /groups/1
  def update
    if params[:group].nil? || params[:group][:mentor_ids].blank? || params[:group][:mentee_ids].blank?
      flash[:alert] = "You must select at least one mentee / mentor."
      redirect_to edit_group_path(@group) and return
    end

    params[:group][:mentee_ids] ||= []
    params[:group][:mentor_ids] ||= []

    people_ids = params[:group][:mentee_ids] + params[:group][:mentor_ids]

    if @group.update(mentee_ids: people_ids)
      align_person_state
      redirect_to @group, notice: 'Group was successfully updated.'
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group
      @group = Group.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def group_params
      params.require(:group).permit(:mentor_ids, :entee_ids)
    end

    def align_person_state
      states = [Person.state_id(:waiting), Person.state_id(:in_group)]
      Person.where(state: states).each do |p|
        p.save if p.align_group_state
      end
    end
end
