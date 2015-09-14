#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  table = noko.xpath('//h3[span[@id="By_constituency"]]/following-sibling::table[.//th[contains(.,"Candidates")]]')
  raise "Can't find candidate table" unless table.count == 1

  parties = Hash[table.xpath('tr[2]//th/@style').map { |th| [ th.text[/background-color:#(\w+)/, 1], th.parent.text ] }]

  table.xpath('tr[td]').each do |tr|
    winner = tr.xpath('td[.//b]')
    data = { 
      name: winner.css('b').text,
      wikiname: winner.xpath('.//a[not(@class="new")]/@title').text,
      area: tr.xpath('.//td[1]//text()[1]').text,
      party: parties[ winner.attr('style').to_s[/background-color:#(\w+)/, 1] ],
      term: 2012,
      source: url,
    }
    puts data
    ScraperWiki.save_sqlite([:name, :area, :party, :term], data)
  end
end

scrape_list('https://en.wikipedia.org/wiki/Bahamian_general_election,_2012')
