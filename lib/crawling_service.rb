# frozen_string_literal: true

gem 'selenium-webdriver', '4.10.0'
gem 'webdrivers', '5.3.1'

require 'nokogiri'
require 'watir'
require 'webdrivers'

class CrawlingService
  attr_reader :results

  def initialize(attributes = {})
    @search_topic = attributes[:search_topic] || '西洋'
    @total_pages = attributes[:to]
    @results = []
  end

  def crawl
    browser = Watir::Browser.new :chrome, options: { args: %w[--remote-debugging-port=9222] }
    browser.driver.manage.window.maximize
    url = "https://search.people.cn/jp/?keyword=#{@search_topic}"
    browser.goto(url)
    sleep 10

    if @total_pages.zero?
      articles = browser.element(css: '.foreign_search').text.split[1].to_i
      result_pages = (articles / 10.to_f).round
      @total_pages = result_pages < 1001 ? result_pages : 1000
      puts "Found articles: #{articles}"
      puts "Total pages: #{@total_pages}"
    end

    index = 1

    while index <= @total_pages
      puts "Currently reading page #{index}/#{@total_pages} (#{format('%.2f', 100 * index / @total_pages.to_f)}%)"
      sleep 3
      html = browser.html
      doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
      doc.css('ul li b a').each do |element|
        url = element['href']
        title = element.children.text
        @results << { title: title, url: url }
      end

      if index < @total_pages
        begin
          next_btn = browser.span(class: 'page-next')
          next_btn.wait_until(timeout: 120, &:present?)
          browser.execute_script('arguments[0].click();', next_btn)
        rescue Watir::Exception::StaleElementReferenceError
          next_btn = browser.span(class: 'page-next')
          puts 'StaleElementReferenceError'
          restore_progress(index)
          retry
        end
      end

      index += 1
    end

    browser.quit
    puts @results.size
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

  def restore_progress(index)
    # broswer refresh
    browser.refresh
    sleep 3
    # get back to index value
    (index - 1).times do
      next_btn = browser.span(class: 'page-next')
      next_btn.wait_until(timeout: 120, &:present?)
      browser.execute_script('arguments[0].click();', next_btn)
    rescue Watir::Wait::TimeoutError
      restore_progress(index)
    end
    # continue from there
    puts 'progress restored'
  end
end
