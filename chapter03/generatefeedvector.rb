require 'MeCab'
require 'open-uri'
require 'kconv'
require 'rubygems'
require 'hpricot'
require 'pp'

def get_wordlist(str)
  mecab = MeCab::Tagger.new('-O wakati')
  mecab.parse(str).split(' ')
end

def get_wordcounts(url) 
puts url
  res = open(url).read
  # Hpricotを使う
  #desc = "" 
  #(doc/:item).each {|i| desc << (i/:description).inner_text }
  
  # 手動でhtmlタグを消す
  desc = res.toutf8.gsub(/<.*?>/m, '')
  
  doc = Hpricot(res) 
  title = (doc/:title)[0].inner_text
  words_list = get_wordlist(desc)
  
  wc = {} 
  words_list.each {|word|
    wc[word] ||= 0
    wc[word] += 1
  }
  return title, wc
end

if __FILE__ == $0
  
  gr = File.read('./google-reader-subscriptions.xml')  
  doc = Hpricot(gr)
  rss_list = (doc/:outline).collect {|o| $1 if /xmlurl=\"(.*?)\" title/ =~ o.to_html }
  
  wordcounts = {}
  blogcounts = {}

  #res = open('http://blog.livedoor.jp/dankogai/index.rdf')
  #puts res.read

  #title, wc = get_wordcounts(rss_list[0])
  #puts title
  #puts wc
  rss_list.each {|rss|
    begin 
      puts "#{rss}: start parsing... \n"
      title, wc = get_wordcounts(rss)
      wordcounts[title] = wc
      wc.each {|word, _|
        blogcounts[word] ||= 0
        blogcounts[word] += 1
      }
    rescue => err
      puts "Failed to parse rss #{rss}"
    end
  }
  #puts wordcounts.size

  # 頻度が極端に低かったり，一般的な単語はデータに入れない
  words = []
  blogcounts.each {|word, n| 
    freq = n.to_f / rss_list.size
    words << word if freq > 0.1  && freq < 0.6
  }
   
  File.open('blogdata.txt', 'w') {|f|
    f.write('Blog')
    words.each {|word| f.write("\t#{word}") }
    f.write("\n")

    wordcounts.each do |blog, wc|
      f.write(blog)
      words.each {|word|
        if wc.key? word 
          f.write("\t#{wc[word]}")
        else
          f.write("\t0")
        end
      }
      f.write("\n")
    end
  }
end

