require 'set'
require 'open-uri'
require 'rubygems'
require 'active_record'
require 'hpricot'

class Crawler
  def initialize
    
  end

  def dbcommit
  end

  def get_entryid
  end

  def get_text(hpricot)
  end

  def indexed?(url)
    false
  end

  def add_linkref(url_from, url_to, link_text)
    
  end

  def add_toindex(url, hpricot)
    puts "Indexing #{url}"
  end

  def separate_words
  end

  def create_indextables
  end

  def crawl(pages, depth=2)
    depth.times do 
      new_pages = Set.new
      pages.each do |page|
        begin
          doc = open(page)
        rescue
          puts "could no open '#{page}'"
          next
        end
        h = Hpricot(doc)
        add_toindex(page, h)

        links = h/:a
        links.each do |link|
          url = link[:href]
          next unless url
          
          url = URI.join(page, url).to_s
          if url[0...4] == 'http' and !indexed?(url)
            new_pages << url
          end
          link_text = get_text(url)
          add_linkref(page, url, link_text) 
        end
        dbcommit
      end
      pages = new_pages
    end
  end
end

if __FILE__ == $0
  page_list = ["http://kiwitobes.com/wiki/Perl.html"]
  crawler = Crawler.new
  crawler.crawl(page_list)
end
