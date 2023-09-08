# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'
require 'watir'
require 'webdrivers'

class CrawlingService
  attr_reader :results

  def initialize(attributes = {})
    @search_topic = attributes[:search_topic] || URI.encode_www_form_component('コロナ')
    @from = attributes[:from] || 1
    @to = attributes[:to] || 2
    @total_pages = 36
    @results = []
  end

  def crawl
    browser = Watir::Browser.new :chrome, options: { args: %w[--remote-debugging-port=9222] }
    url = 'http://j.people.com.cn/'
    browser.goto(url)
    sleep 2
    search_bar = browser.text_field(name: 'keyword')
    search_button = browser.button(name: 'button')
    search_bar.set(@search_topic)
    search_button.click
    sleep 2
    switch_tab(browser)
    puts 'Starting results crawl'
    index = 1
    # total_pages = @to - @from
    while index <= @total_pages
      puts "Currently reading page #{index}/#{@total_pages} (#{format('%.2f', 100 * index / @total_pages.to_f)}%)"
      sleep 1
      html = browser.html
      doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
      doc.css('dt').each do |element|
        url = element.at_xpath('.//a')['href']
        title = element.at_xpath('.//a').text
        @results << { title: title, url: url }
      end
      if index < @total_pages
        next_link = browser.a(text: '次ページ')
        next_link.click
      end
      index += 1
    end
    browser.quit
    @results
  end

  private

  def switch_tab(browser)
    # Find the new tab by comparing URLs
    new_tab = nil
    windows = browser.windows
    windows.each do |window|
      if window.url != browser.url
        new_tab = window
        break
      end
    end
    # Switch focus to the new tab
    new_tab&.use
  end
end
