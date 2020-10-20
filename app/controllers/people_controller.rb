class PeopleController < ApplicationController
  QUESTIONS = [
		["What is two plus two? (in digits)", "4"],
		["What is the number before twelve? (in digits)", "11"],
		["Five times two is what? (in digits)", "10"],
		["Insert the next number in this sequence: 10, 11, 12, 13, 14, … (in digits)", "15"],
		["What is five times five? (in digits)", "25"],
		["Ten divided by two is what? (in digits)", "5"],
		["What day comes after Monday?", "tuesday"],
		["What is the last month of the year?", "december"],
		["How many minutes are in an hour? (in digits)", "60"],
		["What is the opposite of down?", "up"],
		["What is the opposite of north?", "south"],
		["What is the opposite of bad?", "good"],
		["What is 4 times four? (in digits)", "16"],
		["What number comes after 20? (in digits)", "21"],
		["What month comes before July?", "june"],
		["What is fifteen divided by three? (in digits)", "5"],
		["What is 14 minus 4? (in digits)", "10"],
		["What comes next? 'Monday Tuesday Wednesday …'", "thursday"]
  ]

  before_action :set_person, only: [:show, :edit, :update, :destroy, :change_password, :change_state]
  before_action :require_godmother
  skip_before_action :require_godmother, only: [:new, :create, :verify_email]
  before_action :registration_open, only: [:new, :create]

  # GET /people
  def index
    @people = Person.all

    if params[:r]
      @people = @people.where(role: params[:r])
    end

    if params[:s]
      @people = @people.where(state: params[:s])
    end

    if params[:g]
      @people = @people.where(isGodmother: params[:g])
    end
  end

# GET /people/1
  def show
  end

  # GET /people/new
  def new
    @person = Person.new
		@captcha = new_captcha

    if ['mentee', 'mentor'].include?(params[:r])
      @person.role_name = params[:r]
    else
      @person.role_name = :mentee
    end
  end

  # GET /people/1/edit
  def edit
  end

	def change_password
		@person = current_person
	end

  # POST /people
  def create
    @person = Person.new(person_params)
    @captcha = new_captcha

    unless [1, 2].include?(@person.role)
      @person.role = 1
    end

    if params[:address].downcase != QUESTIONS[params[:number].to_i].last
      flash[:alert] = "Are you sure you are human?"
      render :new
    elsif @person.save
      PersonMailer.with(person: @person).verification_email.deliver_now
      redirect_to home_path, notice: "You are successfully registered. We sent you a verification mail to your address <#{@person.email}>. You may have to take a look in your junk folder."
    else
      render :new
    end
  end

  # PATCH/PUT /people/1
  def update
    if person_params[:password]
      if current_person.authenticate(params[:old_password]) && current_person.id == @person.id
        if @person.update(person_params)
          redirect_to @person, notice: 'Password was successfully updated.'
        else
          render :change_password
        end
      else
        flash[:alert] = 'Wrong old password?'
        render :change_password
      end
    elsif @person.update(person_params)
      redirect_to @person, notice: 'Person was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /people/1
  def destroy
    @person.destroy
    redirect_to people_url, notice: 'Person was successfully destroyed.'
  end

  def verify_email
    @person = Person.find_by(verification_token: params[:verification_token])

    if @person
      if (Person::STATES.values - [:unverified]).include?(@person.state_name)
        msg = { notice: "Your e-mail address is already verified." }
      elsif @person.state_name == :unverified
        @person.state_name = :verified
        @person.tags.each do |t|
          t.active = true
          t.save
        end

        if @person.save
          PersonMailer.with(person: @person).new_person_email.deliver_now

          msg = { notice: "Your e-mail address was successfuly verified.\nYour request will now be forwarded to us (the Chaospatinnen orga team) and we will send you an answer as soon as possible… which can be a while, sorry for that. ^__^" }
        else
          msg = { alert: "Something went wrong. You may want to contact us." }
        end
      else
        msg = { alert: "What are you trying here?!" }
      end
    else
      msg = { alert: "Seems like your verification link is broken. Try copy and paste it by hand." }
    end

    redirect_to home_path, msg
  end

  def change_state
    if !Person::STATES.keys.include?(params[:state])
      @person.state = params[:state]

      if @person.save
        redirect_to @person, notice: "State was successfully updated to: #{@person.state_name.to_s.humanize}"
      else
        redirect_to @person, alert: 'Something went wrong.'
      end
    else
      redirect_to @person, alert: 'Invalid state.'
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_person
    @person = Person.find_by(random_id: params[:random_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def person_params
    params.require(:person).permit(:tag_list, :role_id, :random_id, :verification_token, :name, :pronoun, :email, :about, :password, :password_confirmation, :is_godmother)
  end

  def new_captcha
    flash = {}
    captcha = [rand(QUESTIONS.size)]
    captcha << QUESTIONS[captcha.first].first
    return captcha
  end
end
