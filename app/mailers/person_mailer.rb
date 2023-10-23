class PersonMailer < ApplicationMailer
  default from: "godmother@orca-central.de"

  def verification_email
    @person = params[:person]

    options = {
      to: @person.email,
      reply_to: Rails.configuration.x.basic.list_address,
      subject: 'Chaospatinnen - E-Mail Verification'
    }

    mail(options)
  end

  def new_person_email
    @person = params[:person]

    options = {
      to: Rails.configuration.x.basic.list_address,
      reply_to: @person.email,
      subject: "New #{@person.role_name.to_s.humanize} #{@person.name} [#{@person.random_id}]"
    }

    mail(options)
  end

  def your_mentees
    @mentor = params[:mentor]

    options = {
      to: @mentor.email,
      reply_to: Rails.configuration.x.basic.list_address,
      cc: Rails.configuration.x.basic.list_address,
      subject: "Chaospatinnen - Your Mentees [#{@mentor.random_id}]"
    }

    mail(options)
  end
end
