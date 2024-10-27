namespace :godmother do
  desc "Create a new godmother user"
  task create: :environment do
    require 'io/console'

    puts "Enter name:"
    name = STDIN.gets.chomp

    puts "Enter email:"
    email = STDIN.gets.chomp

    puts "Enter password:"
    password = STDIN.noecho(&:gets).chomp
    puts "\n"

    # Create a new Person
    person = Person.new(
      name: name,
      email: email,
      about: "The godmother",
      password: password,
      password_confirmation: password
    )

    person.role_name = :godmother

    if person.save(validate: false)
      puts "Godmother created successfully."
    else
      puts "Failed to create godmother:"
      person.errors.full_messages.each do |message|
        puts "  - #{message}"
      end
    end
  end
end