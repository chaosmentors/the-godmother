require 'faker'

Person.destroy_all
Tag.destroy_all
Group.destroy_all
Tagging.destroy_all

languages = ['german', 'deutsch', 'english', 'englisch', 'spanish', 'español', 'french', 'français']

100.times do
  person = Person.create(
    pronoun: ['she/her', 'he/him', 'they/them'].sample,
    name: Faker::Name.name,
    email: Faker::Internet.email,
    role: Person.role_name_to_value(['mentee', 'mentor'].sample),
    state: Person.state_name_to_value('waiting'),
    about: Faker::Lorem.paragraph,
    validated_at: Time.now
  )

  tags = []
  10.times do
    if rand < 0.5
      tags << Tag.find_or_create_by(name: languages.sample)
    else
      tags << Tag.find_or_create_by(name: Faker::Lorem.word)
    end
  end
  person.tags << tags.sample(rand(1..3))

  person.save!
end

puts "Created #{Person.count} persons and #{Tag.count} tags"

# Add a godmother
godmother = Person.create(
  pronoun: 'she/her',
  name: 'Godmother',
  email: 'godmother@example.com',
  role_name: :godmother,
  state: Person.state_name_to_value('verified'),
  about: 'I am the godmother of this project.',
  validated_at: Time.now,
  password: 'password',
  password_confirmation: 'password'
)

godmother.save(validate: false)

puts "Created godmother with email #{godmother.email} and password 'password'"