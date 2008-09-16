require 'RMagick'
include Magick

class Dendrogram
  def initialize(cluster, labels, img="clusters.png")
    @cluster = cluster 
    @labels = labels
    @img = img
  end

  def draw
    w = 1200
    h = get_height(@cluster) * 20
    depth = get_depth(@cluster)
    scaling = (w-150.0)/depth
    
    canvas = ImageList.new
    canvas.new_image(w+50, h+50)
    
    pen = Draw.new
    draw_line(pen, 0, h/2, 10, h/2)

    # 再起的にノードを描写する
    draw_node(pen, @cluster, 10, h/2, scaling, @labels)

    pen.draw(canvas)
    canvas.write(img)
  end
  
  private
  def draw_node(draw, cluster, x, y, scaling, labels)
    if cluster.id < 0
      h_left = get_height(cluster.left)*20
      h_right = get_height(cluster.right)*20
      top = y - (h_left + h_right)/2
      bottom = y + (h_left + h_right)/2
      depth = cluster.distance*scaling

      # クラスタから子への垂直線
      draw_line(draw, x, top+h_left/2, x, bottom-h_right/2)
      # 左側へのノードへの水平線
      draw_line(draw, x, top+h_left/2, x+depth, top+h_left/2)
      # 右側へのノードへの水平線
      draw_line(draw, x, bottom-h_right/2, x+depth, bottom-h_right/2)
      
      draw_node(draw, cluster.left, x+depth, top+h_left/2, scaling, labels)
      draw_node(draw, cluster.right, x+depth, bottom-h_right/2, scaling, labels)
    else
      draw_text(draw, x+5, y-10, labels[cluster.id])
    end
  end

  def draw_line(draw, x1, y1, x2, y2, color='black', width=2)
    draw.stroke(color)
    draw.stroke_width(width)
    draw.line(x1, y1, x2, y2)
  end

  def draw_text(draw, x, y, text, size=14, color='black', font="/Library/Fonts/ヒラギノ丸ゴ\ Pro\ W4.otf")
    draw.font = font 
    draw.pointsize(size) 
    draw.stroke(color)
    draw.text(x, y, text)
  end

  def get_height(cluster)
    return 1 if clsuter.left == nil and cluster.right == nil
    
    return get_height(cluster.left) + get_height(cluster.right)
  end

  def get_depth(cluster)
    return 0 if cluster.left == nil and cluster.right == nil

    return [get_depth(cluster.left), get_depth(cluster.right)].max + cluster.distance
  end
end

if __FILE__ == $0
  
end
