require 'enumerator'
require 'yaml'
require 'pp'

class Array
  def sum
    self.inject(0) {|total, i| total + i}
  end
end



## 映画データから評価辞書を作成する
def load_movielens(path='./data')
  # 映画のid, titleを作成
  movies = {}
  File.open("#{path}/u.item") {|f|
    while line = f.gets
      id, title = line.split('|')[0..1]
      movies[id] = title
    end
  }
  
  # ユーザの評価を読み込む
  prefs = {}
  File.open("#{path}/u.data") {|f| 
    while line = f.gets
      user, movie_id, rating, ts = line.split("\t")
      prefs[user] = {} unless prefs.key? user
      prefs[user][movies[movie_id]] = rating.to_f
    end
  }
  prefs 
end


## 与えられたuserに対してアイテムベースによる推薦をおこなう
def get_recommend_item(prefs, item_prefs, user)
  user_ratings = prefs[user] 
  scores = {}
  total_sim = {}

  user_ratings.each do |item, rating|
    item_prefs[item].each do |sim, other_item|
      next if user_ratings.key? other_item
      
      scores[other_item] = 0 unless scores.key? other_item
      scores[other_item] += sim * rating
      
      total_sim[other_item] = 0 unless total_sim.key? other_item
      total_sim[other_item] += sim
    end
  end
  
  rankings = scores.map {|item, score| [score/total_sim[item], item] }
  rankings.sort.reverse
end

def calc_sim_items(prefs, n=10)
  result = {}
  cnt = 0

  itemprefs = transform_prefs(prefs)
  itemprefs.each_key {|item|
    # debug messeage 
    cnt += 1
    puts "#{cnt}/#{itemprefs.size}" if cnt%100 == 0
    
    # calculate item similality
    scores = top_matches(itemprefs, item, n, method(:sim_distance))
    result[item] = scores
  }
  result
end

def transform_prefs(prefs)
  result = {}
  prefs.each_key do |person|
    prefs[person].each_key do |item|
      result[item] = {} if !(result.key? item)
      result[item][person] = prefs[person][item]
    end
  end
  result
end

def get_recommend2(prefs, user_sim, person)
  totals = {}
  total_sim = {}

  user_sim[person].each do |sim, other|
    prefs[other].each_key do |item|  
      if !(prefs[person].key? item) or prefs[person][item] == 0
        totals[item] = 0 unless totals.key? item
        totals[item] += prefs[other][item] * sim
        total_sim[item] = 0 unless total_sim.key? item
        total_sim[item] += sim
      end
    end
  end
  
  ranking = totals.map {|item, total| [total/total_sim[item], item] }
  ranking.sort.reverse
end

## 与えられたkeyに対してuserbaseで推薦を行う
def get_recommend(prefs, person, similality=method(:sim_pearson))
  totals = {}
  total_sim = {}
  prefs.each_key do |other|
    next if other == person 
    
    sim = similality.call(prefs, person, other)
    next if sim <= 0
    
    prefs[other].each_key do |item| 
      if !(prefs[person].key? item) or prefs[person][item] == 0
        totals[item] = 0 if !(totals.key? item)
        totals[item] += prefs[other][item]*sim 
        total_sim[item] = 0 if !(total_sim.key? item)
        total_sim[item] += sim
      end
    end
  end
  
  ranking = totals.map {|item, total| [total/total_sim[item], item] }
  ranking.sort.reverse
end


## 与えられたkeyに類似しているother_keyを辞書からトップnを返す
def top_matches(prefs, person, n=5, similality=method(:sim_pearson))
  scores = prefs.map {|other, val|
    [similality.call(prefs, person, other), other] if person != other
  }
  scores.delete(nil)
  scores.sort.reverse[0...n]
end


## ピアソン係数を用いたスコア
def sim_pearson(prefs, person1, person2)
  both = {}
  prefs[person1].each_key do |key|
    both[key] = 1 if prefs[person2].key? key
  end
  n = both.size 
  return 0 if n == 0
  
  sum1 = both.map {|key, value| prefs[person1][key] }.sum
  sum2 = both.map {|key, value| prefs[person2][key] }.sum 

  sum1Sq = both.map {|key, value| prefs[person1][key] ** 2}.sum
  sum2Sq = both.map {|key, value| prefs[person2][key] ** 2}.sum

  pSum = both.map {|key, value| prefs[person1][key] * prefs[person2][key] }.sum

  # pearson formula 
  numerator = pSum - (sum1 * sum2)/n
  denominator = Math.sqrt( (sum1Sq - (sum1**2/n)) * (sum2Sq - (sum2**2/n)) )
  return 0 if denominator == 0
  
  numerator/denominator
end


## ユークリッド距離によるスコア
def sim_distance(prefs, person1, person2)
  both = {}  
  prefs[person1].each_key do |key|
    both[key] = 1 if prefs[person2].key? key      
  end
  return 0 if both.size == 0 
  
  sum_of_squares = both.map {|key, value|
    (prefs[person1][key] - prefs[person2][key]) ** 2
  }.sum
  
  #1/(1 + sum_of_squares)
  1/(1 + sum_of_squares ** 0.5)
end

# 各ユーザの類似度が高いユーザデータ辞書を作る
def make_usersim(prefs)
  user_sim = {}
  prefs.each_key {|person| 
    sims = top_matches prefs, person
    user_sim[person] = sims
  }
  File.open("user_sim.yaml", "w") {|f| f.puts user_sim.to_yaml }
end

if __FILE__ == $0
  #data = File.open("critics.yaml") {|f| f.read }
  #critics = YAML.load(data)
  #p sim_distance(critics, "Lisa Rose", "Gene Seymour")
  #p top_matches(critics, "Toby", 2)
  #pp get_recommend(critics, "Toby")
  #movies = transform_prefs(critics)
  #pp top_matches(movies, "Superman Returns")
  #item_prefs = calc_sim_items(critics)
  #pp get_recommend_item(critics, item_prefs, "Toby") 

  
  #yml_data = load_movielens.to_yaml
  #File.open("prefs.yaml", "w") {|f| f.puts yml_data }
  
  # user based recommendation
  data = File.open("prefs.yaml") {|f| f.read }
  prefs = YAML.load(data)
  
  data = File.open("user_sim.yaml") {|f| f.read }
  user_sim = YAML.load(data)
  pp get_recommend2(prefs, user_sim, "100")[0...30]
   
  
  #pp get_recommend(prefs, "100")[0...30]
  
  # item based recommendation
  #item_sim = calc_sim_items(prefs, 50).to_yaml
  #File.open("item_sim.yaml", "w") {|f| f.puts item_sim }
  #pp get_recommend_item(prefs, item_sim, '87')[0...30]
end
