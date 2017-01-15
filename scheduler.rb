# This file is responsible for controlling when the `water.py` script is invoked.

# Extract watering duration from command
duration_parameter = ARGV.first
puts "Run water system for "+duration_parameter+" seconds"

# Find current time.
current_time_utc = Time.now
# Localise the current time.
current_time_local = current_time_utc.localtime.hour
# Print the current time into logs or terminal in both UTC and local time.
puts "Current UTC time is "+current_time_utc.to_s
puts "Current time hour is "+current_time_local.to_s
#Specify a local start time in 24 hour time (eg. 2pm is the 14th hour of the day)
  # start_time_hour = 6
# Output the start time to logs or terminal
puts "Start time hour is "+start_time_hour.to_s

# If the local time matches the start time set, start the watering system.
# Note: I did this in Ruby rather than using a cron job to control the start time, as it allows me to keep the cron job relatively simple and eventually expand the logic in Ruby to accomodate things like Google Calendar look ups etc. At present this also acts as a failsafe if I get the cron job wrong and stops the garden from being watered excessively.

if start_time_hour == current_time_local

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
#
else
  # If it is not time to water, log the notice that it is not time to water yet.
  puts Time.now.to_s+" Not time to water yet"
end
