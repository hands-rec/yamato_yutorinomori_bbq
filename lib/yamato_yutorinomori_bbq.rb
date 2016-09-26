require "yamato_yutorinomori_bbq/version"

require 'nokogiri'
require 'date'
require 'open-uri'
require 'openssl'
require 'holiday_jp'

module YamatoYutorinomoriBbq

  class Client
    CRAWLER_UA = 'Mozilla/5.0 (Windows NT 6.3; Win64; x64; Trident/7.0; rv:11.0) like Gecko'
    def initialize()
      @site_url = "https://175.184.45.152:24135/yamato/rv/index.php"
    end

    def find_bookable_list(within: [])
      source = open(@site_url, 'User-Agent' => CRAWLER_UA, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE)
      scraper = YamatoYutorinomoriBbq::Scraper.new(source)
      scraper.find_bookable_list(within: within)
    end
  end

  class Scraper
    attr_reader :base
    def initialize(source)
      @base = Nokogiri::HTML(source).css('#undercolumn_entry table')
      @date_time_list = []
    end

    def execute
      @base.css('tr').each do |tr|
        date = scrape_date(tr)
        next if date.empty?

        values = scrape_values(tr)

        values.each do |time_id, value|
          @date_time_list << BookableDateTime.new(date, time_id, value) 
        end
      end
      @date_time_list
    end

    def find_bookable_list(within: [])
      execute if @date_time_list.length == 0
      list = []
      @date_time_list.each do |datetime|
        list << datetime if datetime.available?
      end
      within.empty? ? list : within(list, within)
    end

    def within(list, within) 
      list.select do |datetime|
        result = false
        within.each do |w|
          result = result || w.within?(datetime.date)
        end
        result
      end
    end

    def scrape_date(tr)
      tr.css('td:first-child').text.strip
    end

    def scrape_values(tr)
      first_half = tr.css('td:nth-child(2)').text.strip
      second_half = tr.css('td:nth-child(9)').text.strip
      {1 => first_half, 2 => second_half}
    end
  end

  module Within
    module Holiday
      def within?(date)
        HolidayJp.holiday?(date)
      end
      module_function :within?
    end
    module Sunday
      def within?(date)
        date.sunday?
      end
      module_function :within?
    end
    module Saturday
      def within?(date)
        date.saturday?
      end
      module_function :within?
    end
  end

  class BookableDateTime
    attr_reader :date
    def initialize(date, time_id, value)
      @date = parse_date(date)
      @time_id = time_id
      @value = value
    end

    def parse_date(date)
      month_day = date.slice(0, date.index("("))
      year = Date.today.year.to_s
      Date.parse("#{year}/#{month_day}")
    end

    def available?
      @value != "×"
    end

    def to_s
      d = @date.strftime("%m-%d(%A)")
      "#{d} #{time} #{@value}"
    end

    def time
      if @time_id == 1
        "10時 ～"
      elsif @time_id == 2
        "13時30分 ～"
      end
    end
  end
end
