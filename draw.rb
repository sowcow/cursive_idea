# warning: no arbitrary decomposition ahead
#
class DrawContext
  def initialize dx: 100, dy: 100
    l = 0 # left
    c = dx # center
    r = dx * 2

    tt = 0 # top 2x
    t = dy
    m = dy*2 # middle
    b = dy*3
    bb = dy*4 # bottom 2x

    @W = dx * 2
    @H = dy * 4

    @R = 100
    @R2 = 200
    @PEN = 20

    @POINTS = {
      lt: Point[l,t],
      lm: Point[l,m],
      lb: Point[l,b],

      ctt: Point[c,tt],
      ct: Point[c,t],
      cm: Point[c,m],
      cb: Point[c,b],
      cbb: Point[c,bb],

      rt: Point[r,t],
      rm: Point[r,m],
      rb: Point[r,b],
    }

    letter = -> config {
      Letter[config, self]
    }

    # for each shape/style variations by line position/direction are:
    # big, high, low, low-to-high, high-to-low
    sharp = [
      letter['lm-rm'],
      letter['lt-rt'],
      letter['lb-rb'],
      letter['lb-rt'],
      letter['lt-rb'],
    ]
    curve_up = [
      letter['lb_ct_rb'], # big
      letter['lt-ctt-rt'],
      letter['lb-cm-rb'],
      letter['lb_ct_rt'],
      letter['lt_ct_rb'],
    ]
    curve_down = [
      letter['lt_cb_rt'], # big
      letter['lt-cm-rt'],
      letter['lb-cbb-rb'],
      letter['lb_cb_rt'],
      letter['lt_cb_rb'],
    ]
    loop_above = [
      letter['lb=ct=rb'], # big
      letter['lt~ctt~rt'],
      letter['lb~cm~rb'],
      letter['lb~lt~rt'],
      letter['lt~rt~rb'],
    ]
    loop_below = [
      letter['lt=cb=rt'], # big
      letter['lt~cm~rt'],
      letter['lb~cbb~rb'],
      letter['lb~rb~rt'],
      letter['lt~lb~rb'],
    ]
    odd_letter = [
      letter['*cm'],
      letter[' '],
    ]

    @SIGNATURES = sharp + curve_up + curve_down + loop_above + loop_below + odd_letter
    @LETTER_MAPPING = {
      ' ' => 'SPACE'
    }
    @REVERSE_LETTER_MAPPING = @LETTER_MAPPING.invert
    ([*?a..?z] + ['SPACE']).zip(@SIGNATURES).each { |letter, signature|
      signature.assign letter
    }
  end

  attr_reader :W, :H, :R, :R2, :PEN, :POINTS, :SIGNATURES, :LETTER_MAPPING, :REVERSE_LETTER_MAPPING
  # uh, oh

  def letter_to_file letter
    letter = LETTER_MAPPING[letter] || letter
    "alphabet/#{letter}.png"
  end

  def say text, latin_too=false
    width = @W * text.chars.count
    signatures = text.chars.map { |x|
      x = @LETTER_MAPPING[x] || x
      @SIGNATURES.find { |y| y.letter == x } or raise "no signature for: #{x.inspect}"
    }
    broken_line = true

    paths = signatures.map.with_index { |x, i|
      shape = x.shape
      shape.set_shift i * @W
      path = shape.path broken_line ? ?M : ?L
      broken_line = x.letter == @LETTER_MAPPING[' ']
      path
    }

    pointsize = 100
    draw_latin = %'-font Courier -pointsize #{pointsize} -strokewidth 0 -fill navy'
    latin_too and signatures.map.with_index { |o, i|
      shape = o.shape
      shape.set_shift i * @W

      x = o.shape.dx + @W/2.0 - pointsize * 0.25
      y = o.shape.dy + @H
      letter = @REVERSE_LETTER_MAPPING[o.letter] || o.letter
      draw_latin << %| -draw "text #{x},#{y} '#{letter}'"|
    }

    file = "#{text}.png"

    draw = <<-END.strip.lines.map(&:strip).join(' ')
      -draw "path '
        #{ paths * ' ' }
      '"
    END
    draw = '' if paths.empty?

    h = @H
    h += pointsize/2.0 if latin_too

    system <<-END.strip.lines.map(&:strip).join(' ')
      convert
      -size #{width}:#{h} xc:white
      -fill none
      -stroke gray
      -strokewidth 3
      -draw "polyline #{context.POINTS.fetch(:lt)} #{context.POINTS.fetch(:rt).with(x: width)}"
      -draw "polyline #{context.POINTS.fetch(:lb)} #{context.POINTS.fetch(:rb).with(x: width)}"
      -stroke navy
      -strokewidth #{@PEN}
      #{draw}
      #{draw_latin}
      #{file.inspect}
    END
  end

  def context
    self
  end

  def simple_say text
    system <<-END.strip.lines.map(&:strip).join(' ')
      convert +append
      #{ text.chars.map { |x| letter_to_file x } * ' ' }
      #{ "#{text}.png".inspect }
    END
  end

  Point = Struct.new :x, :y do
    def to_s
      [x,y] * ?,
    end

    def + other
      Point[x + other.x, y + other.y]
    end

    def - other
      Point[x - other.x, y - other.y]
    end

    def / number
      Point[x / number, y / number]
    end

    def with x: nil, y: nil
      if x && y
        raise ArgumentError
      elsif x
        Point[x, self.y]
      elsif y
        Point[self.x, y]
      else
        raise ArgumentError
      end
    end
  end

  class Shape
    def self.match? config
      self::REGEX =~ config
    end

    def initialize config, context
      @config = config
      @context = context
      @p = get_points
    end
    attr_reader :context

    # uh, oh
    def draw file, sign, latin_too=false
      pointsize = 300
      draw_latin = %'-font Courier -pointsize #{pointsize} -strokewidth 0 -stroke orange -fill orange'
      latin_too and [self].map.with_index { |shape, i|
        x = context.W/2.0 - pointsize * 0.30
        y = context.H/2.0 + pointsize * 0.25
        letter = context.REVERSE_LETTER_MAPPING[sign.letter] || sign.letter
        draw_latin << %| -draw "text #{x},#{y} '#{letter}'"|
      }

      system <<-END.strip.lines.map(&:strip).join(' ')
        convert
        -size #{context.W}:#{context.H} xc:white
        -fill none
        -stroke gray
        -strokewidth 3
        -draw "polyline #{context.POINTS.fetch(:lt)} #{context.POINTS.fetch(:rt)}"
        -draw "polyline #{context.POINTS.fetch(:lb)} #{context.POINTS.fetch(:rb)}"
        -stroke navy
        -strokewidth #{context.PEN}
        #{ [*features].map { |x| %'-draw "#{x}"' } * ' ' }
        #{ draw_latin }
        #{file.inspect}
      END
    end

    def set_shift dx, dy = 0
      @dx = dx
      @dy = dy
    end
    attr_reader :dx, :dy

    def features start=?M
      x = path(start)
      "path '#{x}'"
    end

    private
    def get_points
      self.class::REGEX.match(@config).to_a.drop(1).map { |x| context.POINTS.fetch x.to_sym }
    end

    def shift point
      x = point.x
      y = point.y
      x += @dx if @dx
      y += @dy if @dy
      Point[x, y]
    end
  end

  class Space < Shape
    REGEX = /^ $/

    def path _start=nil
      []
    end
  end

  class Circle < Shape
    REGEX = /^\*(\w+)$/

    def path start=?M
      center = @p[0]
      left = @p[0] - Point[context.R, 0]
      right = @p[0] + Point[context.R, 0]

      "#{start} #{shift left} A 1,1, 0 0,0 #{shift right} A 1,1 0 1,0 #{shift left}"
    end
  end

  class Line2 < Shape
    REGEX = /^(\w+)-(\w+)$/

    def path start=?M
      "#{start} #{shift @p[0]} L #{shift @p[1]}"
    end
  end

  class Line3 < Shape
    REGEX = /^(\w+)-(\w+)-(\w+)$/

    def path start=?M
      "#{start} #{shift @p[0]} L #{shift @p[1]} L #{shift @p[2]}"
    end
  end

  class Curve < Shape
    REGEX = /^(\w+)_(\w+)_(\w+)$/

    def path start=?M
      a = @p[0]
      d = @p[1]
      delta = @p[2] - @p[0]

      divizor = 5.0
      edge_delta = Point[Point[context.R / divizor, 0].x, 0]

      b = a + edge_delta
      c = d - delta / divizor

      dd = @p[2]
      cc = dd - edge_delta

      "#{start} #{shift a} C #{shift b} #{shift c} #{shift d} S #{shift cc} #{shift dd}"
    end
  end

  class Loop < Shape
    REGEX = /^(\w+)~(\w+)~(\w+)$/

    def path start=?M
      a = @p[0]
      d = @p[1]
      delta = @p[2] - @p[0]

      divizor1 = 2.0 #0.5
      divizor2 = 7.0
      edge_delta = delta / divizor1

      b = a + edge_delta
      c = d + delta / divizor2

      dd = @p[2]
      cc = dd - edge_delta

      "#{start} #{shift a} C #{shift b} #{shift c} #{shift d} S #{shift cc} #{shift dd}"
    end
  end

  class LoopBig < Shape
    REGEX = /^(\w+)=(\w+)=(\w+)$/

    def path start=?M
      a = @p[0]
      d = @p[1]
      delta = @p[2] - @p[0]

      divizor1 = 0.25
      divizor2 = 4.0
      edge_delta = Point[Point[context.R / divizor1, 0].x, 0]

      b = a + edge_delta
      c = d + delta / divizor2

      dd = @p[2]
      cc = dd - edge_delta

      "#{start} #{shift a} C #{shift b} #{shift c} #{shift d} S #{shift cc} #{shift dd}"
    end
  end

  Letter = Struct.new :config, :context, :shape do
    def initialize config, *rest
      super
      klass = [Space, Circle, Line2, Line3, Curve, Loop, LoopBig].find { |x| x.match? config }
      throw :unexpected_config unless klass
      self.shape = klass.new config, context
    end

    def assign letter
      @letter = letter
    end
    attr_reader :letter

    def draw dir, latin_too=false
      file = File.join dir, "#{@letter}.png"
      shape.draw file, self, latin_too
    end
  end
end
