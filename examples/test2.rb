require 'sphero'
require 'dotenv'

Dotenv.load

def set_up
  sphero = Sphero.new ENV['DEVICE_PATH']
  sphero.back_led_output = 0xFF
  sphero.color 'white'
  sphero.roll 0, 0
end

set_up
