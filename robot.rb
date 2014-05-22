require 'artoo'
require 'sphero'
require 'redis'
require 'dotenv'
require 'logger'

Dotenv.load

class SpheroRobot
  FORWARD = 0
  BACKWARD = 180
  LEFT = 270
  RIGHT = 90

  ON = 1
  OFF = 0

  PERMANENT = true
  TEMPORARY = false

  attr_accessor :robot, :time, :logger

  def initialize(logger)
    @logger = logger
    logger.info "Initializing sphero robot listener for #{ENV['DEVICE_PATH']}..."
    retries = 0
    @robot = Sphero.new ENV['DEVICE_PATH']
    @time = 3
    logger.info 'Robot initialized'
  rescue Errno::EBUSY
    sleep 5
    retries += 1
    retry if retries <= 5
  end

  def boot_up
    logger.info 'Booting up...'
    robot.color 'red'
    robot.roll 0, 0
  end

  def proc
    Proc.new {}
  end

  def move(direction, speed=30)
    logger.info "Moving at #{speed} towards #{direction}"
    robot.roll speed, direction
    robot.keep_going @time
  end

  def time(value)
    @time = value
  end

  def color(value, persistant=TEMPORARY)
    robot.color value, persistant
  end

  def spin
    # Turn 360 degrees, 30 degrees at a time
    0.step(360, 30) do |h|
      h = 0 if h == 360
      # Set the heading to h degrees
      robot.heading = h
      robot.keep_going 1
    end
  end

  def rotation(rate)
    robot.rotation_rate = rate
  end

  def calibration(status)
    if status == ON
      robot.back_led_output = 0xFF
      robot.stabilization = false
    else
      robot.heading = FORWARD
      robot.back_led_output = 0x00
      robot.stabilization = true
    end
  end

  def calibrate(seconds=10)
    calibration ON
    sleep seconds
    calibration OFF
  end

  def listen_to_commands
    redis = Redis.connect
    logger.info 'Redis queue initialized'
    logger.info 'Waiting for commands'
    redis.psubscribe('message', 'message.*') do |on|
      on.pmessage do |match, channel, message|
        begin
          raise "System calls are not allowed" if message =~ /exec|system|`|\%x/
          eval message, proc.binding
        rescue => e
          logger.error e
        end
      end
    end
  end
end

logger = Logger.new(STDOUT, 1)

robot = SpheroRobot.new(logger)
robot.boot_up
robot.listen_to_commands

