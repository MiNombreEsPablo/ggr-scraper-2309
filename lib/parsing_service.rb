# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'
require 'date'

# USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36'
USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'

class ParsingService
  def parse(url, title)
    content = []
    begin
      html = URI.open(url, 'User-Agent' => USER_AGENT).read
      doc = Nokogiri::HTML.parse(html, nil, 'utf-8')

      datetime_selectors = ['.txt_1 .left', '#p_publishtime', '.textTime', '.origin', '.wb_c1']
      datetime = find_datetime(doc, datetime_selectors)

      if datetime.nil?
        date = ''
        time = ''
      else
        date = datetime.gsub('人民網日本語版', '').gsub('　', '').slice(0, 11)
        time = datetime.gsub('人民網日本語版', '').gsub('　', '').slice(11, 15)
      end

      source = if doc.at_css('.txt_1 .left').nil?
                 doc.at_css('.wb_c1 a')&.[]('href') || ''
               else
                 doc.at_css('.txt_1 .left').css('a').text
               end
      source = source.instance_of?(Array) ? source.first : source
      source = '人民網日本語版' if source.empty?

      article_selectors = ['.txt_2 p', '#p_content p', '.txt_con3 p', '#wb_21 p', '.wb_31 p', '.wb_21 p',
                           '.textContent p', '.p1_left p']
      article_text, parsed = get_article_text(doc, article_selectors)

      author = get_author(article_text)

      content << { title: title, date: date, time: time, source: source, article_text: article_text, parsed: parsed,
                   url: url, author: author }
    rescue OpenURI::HTTPError => e
      content << { url: url, title: title, article_text: "HTTPError: #{e.message}" }
    end

    content.first
  end

  private

  def find_datetime(doc, datetime_selectors)
    datetime = nil

    datetime_selectors.each do |selector|
      datetime_node = doc.at_css(selector)
      next if datetime_node.nil?

      datetime = datetime_node.text.strip
      break
    end

    datetime
  end

  def get_article_text(doc, selectors)
    article_text = nil
    parsed = false

    selectors.each do |selector|
      ps = doc.search(selector)
      last_p = ps.children.last
      last_p&.remove
      article_text = ps.text.strip
      parsed = article_text.length.positive?
      break if parsed
    end

    article_text = nil unless parsed
    [article_text, parsed]
  end

  def get_author(article_text)
    pattern = /（編集(.*?)）/m
    match = pattern.match(article_text)
    match&.captures&.first
  end
end
