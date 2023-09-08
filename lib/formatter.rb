# frozen_string_literal: true

require 'csv'

input = './results/articles.csv'
output = './results/formatted.csv'

def split_article_text(text)
  return [] if text.nil?

  text.split("\n")
end

# def write_row(output_file, row, headers)
#   new_row = {}
#   headers.each_with_index do |header, i|
#     new_row[header] = row[i]
#   end
#   output_file << new_row.values
# end

# Open the input CSV file and create a new output CSV file
CSV.open(input, 'r', encoding: 'UTF-8') do |input_file|
  CSV.open(output, 'w', encoding: 'UTF-8') do |output_file|
    # Read the headers from the input CSV file and write them to the output CSV file
    headers = input_file.first
    output_file << headers

    # Loop through each row in the input CSV file
    input_file.each do |row|
      # Split the article_text into paragraphs
      paragraphs = split_article_text(row[4])

      # Loop through each paragraph and write it to the output CSV file
      paragraphs.each do |paragraph|
        next if paragraph.strip.empty?

        new_row = row
        new_row[4] = paragraph.strip
        output_file << new_row
      end
    end
  end
end
