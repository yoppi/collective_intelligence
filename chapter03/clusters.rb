require 'enumerator'
require 'pp'
require 'RMagick'
require 'dendrogram'
require 'calc_similarity'
include Magick

#module Enumerable
#  def sum
#    self.inject(0) {|total, i| total + i }
#  end
#end

class Array
  def sum
    self.inject(0) {|total, i| total + i }
  end
end

class Bicluster
  attr_reader :id, :vec, :left, :right, :distance

  def initialize(id, vec, opt=nil)
    if opt
      raise ArgumentError, "Bicluster initialize: opt must be Hash\n" unless opt.is_a? Hash
      @left = opt[:left]
      @right = opt[:right]
      @distance = opt[:distance]
    end
    @id = id
    @vec = vec
  end
end

class Cluster
  include Similality
  include Dendrogram 

  def initialize(cluster)
    @cluster = cluster 
  end
  
  def kcluster(k=4, distance=method(:pearson))
       
  end

  def hcluster()
    
  end

  def print_cluster()
  end

  def setup_cluster
  end

  def print_cluster(labels, n=0)
    print ' ' * n
    if cluster.id < 0
      puts '-'
    else
      unless labels != nil
        puts cluster.id
      else
        puts labels[cluster.id]
      end
    end

    print_cluster(cluster.left, labels, n+1) if cluster.left
    print_cluster(cluster.right, labels, n+1) if cluster.right
  end
end

def print_cluster(cluster, labels=nil, n=0)
end


# k-means method for clustring
def kcluster(data, k=4, distance=method(:pearson))
  memo = {} # for memolization
  ranges = []
  data.transpose.each do |row|
    ranges << [row.min, row.max]
  end
  
  # 初期の重心をランダムに生成
  column_size = data[0].size
  clusters = []
  (0...k).each do |_| 
    cluster = [] 
    (0...column_size).each {|ai| 
      cluster << rand * (ranges[ai][1]-ranges[ai][0]) + ranges[ai][0] 
    } 
    clusters << cluster
  end
  
  last_matches = nil

  (0...100).each do |iterater|
    puts "iteration %d" % iterater 
   
    best_matches = (0...k).map {|_| [] }
    
    data.each_with_index do |row, id|
      best_match = 0 
      (0...k).each {|ai| 
        d = distance.call(clusters[ai], row)
        if d < distance.call(clusters[best_match], row)
          best_match = ai
        end
      }
      best_matches[best_match] << id
    end
    
    break if best_matches == last_matches
    last_matches = best_matches 
    
    # 重心をメンバの平均に移す
    (0...k).each do |ai|
      avgs = [0.0]*column_size
      if best_matches[ai].size > 0
        best_matches[ai].each do |match|
          data[match].each_with_index {|val, mai| avgs[mai] += val }
        end
        avgs = avgs.map {|val| val / best_matches[ai].size }
        clusters[ai] = avgs
      end
    end
  end
  last_matches
end


def hcluster(rows, distance=method(:pearson))
  distances = {}
  current_id = -1
  clusters = []
  rows.each_with_index {|row, i|
    clusters << Bicluster.new(i, row)
  }

  while clusters.size > 1
    lowestpair = [0, 1]
    closest = distance.call(clusters[0].vec, clusters[1].vec)
    
    0.upto(clusters.size-1) do |i|
      (i+1).upto(clusters.size-1) do |j|
        pair = [clusters[i].id, clusters[j].id]
        unless distances.key? pair
          distances[pair] = distance.call(clusters[i].vec, clusters[j].vec)
        end
        d = distances[pair]
        if d < closest
          closest = d
          lowestpair = [i, j]
        end
      end
    end

puts "lowestpair = [#{lowestpair[0]} #{lowestpair[1]}]"
    mergevec = []
    low1_clust = clusters[lowestpair[0]]
    low2_clust = clusters[lowestpair[1]]
    vec_size = low1_clust.vec.size
   
 puts "low1_clust.id = #{low1_clust.id}"
 puts "low2_clust.id = #{low2_clust.id}"
    
    (0...vec_size).each {|i|
      mergevec << (low1_clust.vec[i] + low2_clust.vec[i])/2.0
    }

    newcluster = Bicluster.new(current_id, mergevec, {:left => low1_clust, :right => low2_clust, :distance => closest})
   
    current_id -= 1
    clusters.delete low1_clust
    clusters.delete low2_clust
    clusters << newcluster
  end
  clusters[0] 
end

def pearson(x, y)
  n = x.size
  sum1 = x.sum.to_f
  sum2 = y.sum.to_f

  sum1sq = x.map {|v| v ** 2 }.sum.to_f
  sum2sq = y.map {|v| v ** 2 }.sum.to_f

  psum = (0...n).map {|i| x[i] * y[i] }.sum.to_f
 
  numerator = psum - (sum1*sum2)/n
  denominator = Math.sqrt( (sum1sq - (sum1**2/n)) * (sum2sq - (sum2**2/n)) )

  1.0 - numerator/denominator
end

# shuolde use instead of Array#transpose
def rotate_matrix(data)
  new_data = []
  row_size = data.size
  column_size = data[0].size
  
  (0...column_size).each do |i|
    tmp = []
    (0...row_size).each do |j|
      tmp << data[j][i]
    end
    new_data << tmp
  end
  new_data
end

def readfile(file)
  lines = []
  File.open(file) {|f| 
    while line = f.gets
      lines << line
    end
  }
  
  colnames = lines[0].strip.split("\t")[1..-1] # 単語
  rownames = [] # blog名
  data = [] 
  lines[1..-1].each do |line| 
    o = line.strip.split("\t")
    rownames << o[0]
    data << o[1..-1].collect {|x| x.to_f }
  end
  return rownames, colnames, data
end

if __FILE__ == $0
  blogs, words, data = readfile('blogdata.txt')
puts "Number of blog = #{blogs.size}"
puts "Number of Words = #{words.size}"
puts "Number of data = #{data.size}"
  cluster = hcluster data
  draw_dendrogram cluster, blognames
  #print_cluster cluster, blognames
  #cluster = kcluster data, 10
  #cluster.each_with_index do |c, i|
  #  puts "#{i}:"
  #  c.each {|item| puts "#{blogs[item]}" }
  #end
end
