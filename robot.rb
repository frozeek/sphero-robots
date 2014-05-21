require 'artoo'
require 'sphero'
require 'redis'
require 'dotenv'

Dotenv.load

class SpheroRobot
  FORWARD = 0
  BACKWARD = 180
  LEFT = 270
  RIGHT = 90

  attr_accessor :robot, :time

  def initialize
    puts "Initializing sphero robot listener for #{ENV['DEVICE_PATH']}..."
    retries = 0
    @robot = Sphero.new ENV['DEVICE_PATH']
    @time = 3
    puts 'Robot initialized'
  rescue Errno::EBUSY
    sleep 5
    retries += 1
    retry if retries <= 5
  end

  def boot_up
    puts 'Booting up...'
    robot.back_led_output = 0xFF
    robot.color 'white'
    robot.roll 0, 0
  end

  def proc
    Proc.new {}
  end

  def move(direction, speed=30)
    puts "Moving at #{speed} towards #{direction}"
    robot.roll speed, direction
    robot.keep_going @time
  end

  def set_time(value)
    @time = value
  end

  def spin
    # Turn 360 degrees, 30 degrees at a time
    0.step(360, 30) do |h|
      h = 0 if h == 360
      # Set the heading to h degrees
      robot.heading = h
      keep_going 1
    end
  end

  def listen_to_commands
    redis = Redis.connect
    puts 'Redis queue initialized'
    puts 'Waiting for commands'
    redis.psubscribe('message', 'message.*') do |on|
      on.pmessage do |match, channel, message|
        eval message, proc.binding
      end
    end
  end
end

robot = SpheroRobot.new
robot.boot_up
robot.listen_to_commands

