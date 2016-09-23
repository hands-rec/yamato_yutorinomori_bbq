require 'spec_helper'
require 'pp'

describe YamatoYutorinomoriBbq do
  it 'has a version number' do
    expect(YamatoYutorinomoriBbq::VERSION).not_to be nil
  end


  describe "#find_bookable_list" do
#    pp YamatoYutorinomoriBbq::Client.new().find_bookable_list
  end
end

describe YamatoYutorinomoriBbq::Scraper do
  before :each do
    doc = open('./spec/data/scraping/bbq.html')
    @scraper = YamatoYutorinomoriBbq::Scraper.new(doc)
  end

  describe "#scrape_date" do
    it 'empty' do
      tr = @scraper.base.css('tr:first-child')
      expect(@scraper.scrape_date(tr)).to be_empty
    end

    it 'first' do
      tr = @scraper.base.css('tr:nth-child(2)')
      expect(@scraper.scrape_date(tr)).to eq "09/22(木)" 
    end
  end

  describe "#scrape_values" do
    it '◎' do
      tr = @scraper.base.css('tr:nth-child(3)')
      values = @scraper.scrape_values(tr)
      expect(values[1]).to eq "◎"
      expect(values[2]).to eq "◎"
    end

    it '◯' do
      tr = @scraper.base.css('tr:nth-child(20)')
      values = @scraper.scrape_values(tr)
      expect(values[1]).to eq "◯"
      expect(values[2]).to eq "◯"
    end

    it '△' do
      tr = @scraper.base.css('tr:nth-child(4)')
      values = @scraper.scrape_values(tr)
      expect(values[1]).to eq "△"
      expect(values[2]).to eq "△"
    end
    
    it '×' do
      tr = @scraper.base.css('tr:nth-child(2)')
      values = @scraper.scrape_values(tr)
      expect(values[1]).to eq "×"
      expect(values[2]).to eq "×"
    end
  end

  describe '#execute' do
    it 'list count 60' do
      expect(@scraper.execute.length).to eq 60
    end
  end

  describe '#find_bookable_list' do
    it 'list count 41' do
      expect(@scraper.find_bookable_list.length).to eq 41 
    end

    it 'first' do
      expect(@scraper.find_bookable_list.first.to_s).to eq "09-23(Friday) 10時 ～ ◎"
    end
  end
end
