require 'artoo'
require 'sphero'
require 'redis'
require 'dotenv'
require 'logger'
require 'json'

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

  attr_accessor :robot, :default_time, :logger, :default_speed

  def initialize(logger=RobotLogger.new)
    @logger = logger
    logger.info "Starting initialization..."
    @default_time = 3
    @default_speed = 30
    initialize_sphero_robot
    logger.info "Finishing initialization..."
  end

  def initialize_sphero_robot
    logger.info "Initializing sphero robot listener for #{ENV['DEVICE_PATH']}..."
    retries = 0
    @robot = Sphero.new ENV['DEVICE_PATH']
    logger.info 'Robot initialized'
  rescue Errno::EBUSY
    sleep 5
    retries += 1
    retry if retries <= 5
  end

  def reset
    logger.info 'Reseting robot...'
    initialize_sphero_robot
    logger.info 'Robot ready'
  end

  def boot_up
    logger.info 'Booting up...'
    colors = %w(red green blue yellow black violet orange white)
    colors.each {|c| robot.color c }
    robot.roll 0, 0
  end

  def proc
    Proc.new {}
  end

  def move(direction, speed=default_speed)
    logger.info "Moving to #{direction} degrees at #{speed}"
    robot.roll speed, direction
    robot.keep_going default_time
  end

  def set_default_time(value)
    logger.info "Setting default time to #{value}"
    @default_time = value
  end

  def set_default_speed(value)
    logger.info "Setting default speed to #{value}"
    @default_speed = value
  end

  def set_color(value, persistant=TEMPORARY)
    logger.info "Setting color to #{value}"
    robot.color value, persistant
  end

  def set_rotation_rate(rate)
    logger.info "Setting rotation rate to #{rate}"
    robot.rotation_rate = rate
  end

  def stop
    logger.info "Stopping sphero..."
    robot.stop
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
    logger.info 'Starting calibration...'
    calibration ON
    sleep seconds
    calibration OFF
    logger.info 'Calibration finished'
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

class RobotLogger
  attr_accessor :redis, :stdout_logger, :redis_logger

  def initialize
    @redis = Redis.connect
    @std_logger = Logger.new(STDOUT, 1)
  end

  def info(message)
    @std_logger.info(message)
    @redis.publish('logging', { message: message, severity: :info }.to_json)
  end

  def warn(message)
    @std_logger.warn(message)
    @redis.publish('logging', { message: message, severity: :warn }.to_json)
  end

  def error(message)
    @std_logger.error(message)
    @redis.publish('logging', { message: message, severity: :error }.to_json)
  end
end

robot = SpheroRobot.new
robot.boot_up
robot.listen_to_commands

