# frozen_string_literal: true

require_relative 'lib/article_repository'

puts 'Welcome to the People\'s Daily scraper!'
puts 'What topic would you like to search for?'
search_topic = gets.chomp
puts 'How many result pages would you like to scrape? (leave blank for all)'
to = gets.chomp.to_i

repo = ArticleRepository.new(search_topic: search_topic, to: to)
repo.start

puts 'Reviewing possibly non scraped articles...'
repo.update if repo.non_parsed.any?
puts 'Scraping process finished!'
puts "#{repo.all.size} articles scraped."
# todo: auto formatter when relevant
puts 'Done!'
