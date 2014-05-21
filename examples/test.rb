require 'artoo'
require 'sphero'

def set_up
  sphero = Sphero.new "/dev/tty.Sphero-PYO-AMP-SPP"
  sphero.back_led_output = 0xFF
  sphero.color 'white'
  sphero.roll 0, 0
end

connection :sphero, :adaptor => :sphero, :port => '127.0.0.1:4567'
device :sphero, :driver => :sphero

def handle_collision_detected(data)
  puts "Handled collision: #{data}"
end

def collision_notification(*data)
  puts "Collision: #{data}"
end

def sensor_notification(*data)
  puts "sensor: #{data}"
end

def direction_test
  work do
    test_route = [
      { speed: 25, direction: 0 },
      { speed: 25, direction: 180 }
    ]

    every(4.seconds) do
      unless test_route.empty?
        coords = test_route.shift
        sphero.roll(coords[:speed], coords[:direction])
      end
    end
  end
end

def run
  work do
    on sphero, :collision => :collision_notification
    on sphero, :sensor => :sensor_notification

    position = [ 0, 0 ]

    route = [
      { speed: 30, direction: 0 },
      { speed: 30, direction: 270 },
      { speed: 30, direction: 180 },
      { speed: 30, direction: 90 }
    ]
    every(2.seconds) do
      unless route.empty?
        coords = route.shift
        sphero.roll(coords[:speed], coords[:direction])
        puts "Position: #{position[0]}, #{position[1]}"
        position = recalculate_position(position, coords[:direction], coords[:speed])
      end
    end
  end
end

def set_direction(*data)
  x, y = data[1].split(",")

  @heading = direction(x.to_i, y.to_i)
end

def direction(x, y)
  (180.0 - (Math.atan2(y,x) * (180.0 / Math::PI)))
end

def recalculate_position(position, direction, distance)
  x = distance * Math.cos(direction/180)
  y = distance * Math.sin(direction/180)
  position = [ position[0] + x, position[1] + y]
end

def heading
  @heading || 0
end

set_up
# direction_test
