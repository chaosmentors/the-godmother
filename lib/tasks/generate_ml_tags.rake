namespace :tags do
  desc "Generate tags for people with an about text"
  task generate_ml_tags: :environment do
    require 'openai'

    client = OpenAI::Client.new(
      access_token: Rails.application.config.x.openai_api_key,
      log_errors: Rails.env.development?
    )

    people = Person.where.not(about: [nil, ''])

    people.each do |person|
      next if person.tags.where(ml_generated: true).exists?

      response = client.chat(
        parameters: {
          model: "gpt-4o",
          messages: [
            { role: "system", content: "You will be provided with a block of text from a persons own description, and your task is to extract a list of keywords about this person. Do not extract names or numbers as keywords. Skip 'Congress' as a keyword. Use singular form for keywords only." },
            { role: "user", content: person.about }
          ],
          temperature: 0.7,
        }
      )

      tags_text = response.dig("choices", 0, "message", "content")
      if tags_text.present?
        tags = tags_text.split(',').map(&:strip)

        tags.each do |tag_name|
          tag = Tag.find_or_create_by(name: tag_name.downcase, ml_generated: true)
          person.tags << tag unless person.tags.include?(tag)
        end
      else
        puts "No tags generated for #{person.name} due to unexpected response format."
      end
    end

    puts "ML tags generated and saved successfully."
  end

  desc "Cleanup all ml_generated tags"
  task cleanup_ml_tags: :environment do
    ml_tags = Tag.where(ml_generated: true)
    ml_tags.each do |tag|
      tag.taggings.destroy_all
      tag.destroy
    end
  
    puts "All ml_generated tags have been cleaned up."
  end
end