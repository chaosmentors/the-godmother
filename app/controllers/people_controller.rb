class PeopleController < ApplicationController
  QUESTIONS = -> { I18n.t('captcha_questions').map { |q| [q[:question], q[:answer]] } }
  
  layout :determine_layout, only: [:new, :verify_email, :create]
  before_action :set_person, only: [:show, :edit, :update, :destroy, :change_password, :change_state]
  before_action :require_godmother
  skip_before_action :require_godmother, only: [:new, :create, :verify_email]
  before_action :registration_open, only: [:new, :create]

  # GET /people
  def index
    @people = Person.all

    if params[:r]
      if params[:r] == 'godmother'
        @people = @people.where(isgodmother: true)
      else
        role = Person.role_name_to_value(params[:r])
        @people = @people.where(role: role) if role
      end
    end

    if params[:s]
      state = Person.state_name_to_value(params[:s])
      @people = @people.where(state: state) if state
    end

    if params[:sort_by]
      sort_column = params[:sort_by]
      sort_direction = params[:direction] || 'asc'
      @people = @people.order("#{sort_column} #{sort_direction}")
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

    unless [1, 2, 3].include?(@person.role)
      @person.role = 1
    end

    if !current_person&.isgodmother? && params[:address].downcase != QUESTIONS.call[params[:number].to_i].last
      flash[:alert] = t('people.human_verification_failed')
      render :new
    elsif Person.exists?(email: params[:person][:email])
      flash[:alert] = t('people.email_registered')
      render :new
    elsif @person.is_godmother && (current_person.nil? || !current_person.isgodmother?)
      flash[:alert] = "Nice try ;)"
      render :new
    elsif current_person&.isgodmother? && @person.role_name == 'mentee' && params[:person][:is_godmother] == "1"
      flash[:alert] = t('people.mentee_godmother_error')
      render :new
    else
      if @person.save
        if current_person&.isgodmother?
          if @person.role_name == 'godmother' || @person.is_godmother
            @person.generate_reset_password_token!
            PersonMailer.set_password_email(@person).deliver_now
            redirect_to people_url, notice: t('people.person_created_password_email')
          else
            PersonMailer.with(person: @person).verification_email.deliver_now
            redirect_to people_url, notice: t('people.person_created_verification_email')
          end
        else
          PersonMailer.with(person: @person).verification_email.deliver_now
          redirect_to root_path, notice: t('people.registration_successful', email: @person.email)
        end
      else
        flash[:alert] = @person.errors.full_messages.map { |msg| t("errors.attributes.#{msg.split(' ').first.downcase}.blank") }.to_sentence(locale: I18n.locale, last_word_connector: t('errors.messages.last_word_connector'))
        render :new
      end      
    end
  end

  # PATCH/PUT /people/1
  def update
    
    if @person.role_name == 'mentee'
      @person.isgodmother = false
    end

    if person_params[:password]
      if current_person.authenticate(params[:old_password]) && current_person.id == @person.id
        if @person.update(person_params)
          redirect_to @person, notice: 'Password was successfully updated.'
        else
          render :change_password
        end
      else
        flash[:alert] = t('people.wrong_old_password')
        render :change_password
      end
    elsif @person.update(person_params)
      if (@person.role_name == 'godmother' || @person.is_godmother) && @person.reset_password_token.nil? && @person.password_digest.nil?
        @person.generate_reset_password_token!
        PersonMailer.set_password_email(@person).deliver_now
        redirect_to @person, notice: t('people.person_updated_password_email')
      else
        redirect_to @person, notice: t('people.person_updated')
      end
    else
      render :edit
    end
  end

  # DELETE /people/1
  def destroy
    @person.destroy
    redirect_to people_url, notice: t('people.person_destroyed')
  end

  def verify_email
    @person = Person.find_by(verification_token: params[:verification_token])

    if @person
      if @person.validated_at.present?
        msg = { notice: t('people.email_already_verified') }
      else @person.state_name == :unverified
        @person.state_name = :waiting
        @person.validated_at = Time.current
        @person.tags.each do |t|
          t.active = true
          t.save
        end

        if @person.save
          PersonMailer.with(person: @person).new_person_email.deliver_now

          msg = { notice: t('people.email_verified') }
        else
          msg = { alert: t('people.email_verification_failed') }
        end
      end
    else
      msg = { alert: t('people.verification_link_invalid') }
    end

    redirect_to root_path, msg
  end

  def change_state
    if !Person::STATES.keys.include?(params[:state])
      @person.state = params[:state]

      if @person.save
        redirect_to @person, notice: t('people.state_updated', state: @person.state_name.to_s.humanize)
      else
        redirect_to @person, alert: t('people.state_update_failed')
      end
    else
      redirect_to @person, alert: t('people.invalid_state')
    end
  end

  def send_password_reset
    @person = Person.find_by(random_id: params[:id])
    puts params
    if @person
      if (@person.role_name == 'godmother' || @person.is_godmother)
        @person.generate_reset_password_token!
        PersonMailer.set_password_email(@person).deliver_now
        redirect_to @person, notice: t('people.password_reset_email_sent')
      end
    else
      redirect_to @person, alert: t('people.password_reset_email_failed')
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
    captcha = [rand(QUESTIONS.call.size)]
    captcha << QUESTIONS.call[captcha.first].first
    return captcha
  end

  def determine_layout
    if current_person&.isgodmother? && (params[:internal].present? || params[:person]&.dig(:internal).present?) 
      'application'
    else
      'public'
    end
  end
end

