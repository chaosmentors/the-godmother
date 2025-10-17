class PersonMailer < ApplicationMailer
  default from: Rails.configuration.x.default_from
  include Rails.application.routes.url_helpers

  def verification_email
    @person = params[:person]

    options = {
      to: @person.email,
      reply_to: Rails.configuration.x.list_address,
      subject: 'Welcome to Chaosmentors! Please Verify Your Email'
    }

    mail(options)
  end

  def new_person_email
    @person = params[:person]

    options = {
      to: Rails.configuration.x.list_address,
      reply_to: @person.email,
      subject: "New #{@person.role_name.to_s.humanize} #{@person.name} [#{@person.random_id}]"
    }

    mail(options)
  end

  def your_mentees
    @mentor = params[:mentor]

    options = {
      to: @mentor.email,
      reply_to: Rails.configuration.x.list_address,
      cc: Rails.configuration.x.list_address,
      subject: "Chaosmentors - Your Mentees [#{@mentor.random_id}]"
    }

    mail(options)
  end

  def set_password_email(person)
    @person = person
    @url = edit_password_reset_url(@person.reset_password_token)

    options = {
      to: @person.email,
      reply_to: Rails.configuration.x.list_address,
      subject: "Chaosmentors - Set Your Password"
    }

    mail(options)
  end

  def confirmation_success_email
    @person = params[:person]

    options = {
      to: @person.email,
      reply_to: Rails.configuration.x.list_address,
      subject: 'Your registration with the Chaosmentors'
    }

    mail(options)
  end

  def ticket_confirmation_reminder_email
    @person = params[:person]

    options = {
      to: @person.email,
      reply_to: Rails.configuration.x.list_address,
      subject: 'Your registration with the Chaosmentors: Please confirm your ticket status'
    }

    mail(options)
  end
end
