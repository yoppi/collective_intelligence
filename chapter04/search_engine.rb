require 'set'
require 'open-uri'
require 'rubygems'
require 'hpricot'
require 'sqlite3'

class Crawler
  def initialize(db)
    @con = SQLite3::Database.new(db)
  end

  def dbcommit
    @con.commit
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
    @con.execute("create table urllist(url)")
    @con.execute("create table wordlist(word)")
    @con.execute("create table wordlocation(urlid, wordid, location)")
    @con.execute("create table link(fromid integer, toid integer)")
    @con.execute("create table linkwords(wordid, linkid)")
    @con.execute("create index urlidx on urllist(url)")
    @con.execute("create index wordidx on wordlist(word)")
    @con.execute("create index wordurlidx on wordlocation(wordid)")
    @con.execute("create index urltoidx on link(toid)")
    @con.execute("create index urlfromidx on link(fromid)")
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
  #page_list = ["http://kiwitobes.com/wiki/Perl.html"]
  #crawler = Crawler.new
  #crawler.crawl(page_list)

  crawler = Crawler.new("searchindex.db")
  crawler.create_indextables
end
