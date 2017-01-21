require "net/https"

# This file is responsible for controlling when the `water.py` script is invoked.

# zone 1 settings
# in litres per minute
zone_one_flow_rate = 20

# zone 2 settings
zone_two_flow_rate = 0

# Extract watering duration from command
duration_parameter = ARGV.first
puts "Run water system for "+duration_parameter+" seconds"

# Find current time.
session_start_time = Time.now
# Localise the current time.
current_time_local = session_start_time.localtime.hour

# Print the current time into logs or terminal in both UTC and local time.
puts "Current UTC time is "+session_start_time.to_s
puts "Current time hour is "+current_time_local.to_s
#Specify a local start time in 24 hour time (eg. 2pm is the 14th hour of the day)
# Output the start time to logs or terminal

# I stumbled across an issue whereby the GrovePi would need resetting (RST light woudl activate). This line resets the GrovePi before trying to run any commands with it. Important to do it before each watering session to increase the chances it doesn't fail during the watering session (and keep watering...watering...watering)
puts Time.now.to_s+" Reset grove to clear warnings"
system("avrdude -c gpio -p m328p")
puts Time.now.to_s+" Grove Reset"

# Turn on the watering system using the Python controller code for the Grove Relay.
# Note: this code only works for one watering zone at present.
puts Time.now.to_s+" Turning on watering system"

# Run Watering.py script for duration specified.
system("python /home/pi/Projects/garden/water.py #{duration_parameter}")
# system("python water.py #{duration_parameter}")
puts Time.now.to_s+" Turning off watering system"
session_finish_time = Time.now

# Report about watering session

# Report on Zone One
session_duration = session_finish_time - session_start_time
session_water_used = session_duration / 60 * zone_one_flow_rate

print "Watering session lasted "+session_duration.round(2).to_s+" seconds and used "+session_water_used.round(2).to_s+ " litres of water"

url = URI.parse("https://api.pushover.net/1/messages.json")
req = Net::HTTP::Post.new(url.path)
req.set_form_data({
  :token => "PUSHOVER_APP_TOKEN",
  :user => "PUSHOVER_USER_KEY",
  :message => "session_duration",
})
res = Net::HTTP.new(url.host, url.port)
res.use_ssl = true
res.verify_mode = OpenSSL::SSL::VERIFY_PEER
res.start {|http| http.request(req) }
