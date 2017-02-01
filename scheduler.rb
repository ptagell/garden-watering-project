# required to push notifications
require "net/https"
# required to access .env variables
require 'dotenv/load'

# This file is responsible for controlling when the `water.py` script is invoked.

# zone 1 settings
@zone_1_friendly_name = "Back Garden"
@zone_1_flow_rate = "20"
@zone_1_relay = 5
@zone_1_duration = ARGV[0]
# zone 2 settings
@zone_2_friendly_name = "Front Garden"
@zone_2_flow_rate = "1.25"
@zone_2_relay = 4
@zone_2_duration = ARGV[1]
# zone 3 settings
@zone_3_friendly_name = "Wicking Beds"
@zone_3_flow_rate = "20"
@zone_3_relay = 3
@zone_3_duration = ARGV[2]

@number_of_zones_to_water = ARGV.count
@session_start_time = Time.now.localtime

# duration of sleep (needed for resets)
@sleep_duration = 0

# I stumbled across an issue whereby the GrovePi would need resetting (RST light woudl activate). This line resets the GrovePi before trying to run any commands with it. Important to do it before each watering session to increase the chances it doesn't fail during the watering session (and keep watering...watering...watering)
def grove_reset
  puts Time.now.localtime.to_s+" Reset grove to clear warnings"
  system("avrdude -c gpio -p m328p")
  sleep(@sleep_duration) # wait for reboot to finish
  puts Time.now.localtime.to_s+" Grove Reset"
end

# Turn on the watering system using the Python controller code for the Grove Relay.
# Note: this code only works for one watering zone at present.
def water_garden(relay, duration)
  puts Time.now.localtime.to_s+" Turning on watering system"
  # Run Watering.py script for duration specified.
  # system("python water.py #{relay} #{duration}")
  system("python /home/pi/Projects/garden-watering-project/water.py #{relay} #{duration}")
  puts Time.now.localtime.to_s+" Turning off watering system"
end

def water_by_zone
  for i in 1..@number_of_zones_to_water do
    relay = instance_variable_get("@zone_"+i.to_s+"_relay")
    duration = instance_variable_get("@zone_"+i.to_s+"_duration")
    if duration.to_i != 0
      grove_reset
      puts Time.now.localtime.to_s+" Session start time is "+@session_start_time.to_s
      water_garden(relay, duration)
      grove_reset
      puts Time.now.localtime.to_s+" "+instance_variable_get("@zone_"+i.to_s+"_friendly_name")+" done"
    elsif duration.to_i == 0
      puts Time.now.localtime.to_s+" "+instance_variable_get("@zone_"+i.to_s+"_friendly_name")+" skipped as no zero specified"
    end
    puts "\n\n===== MOVING TO NEXT ZONE =====\n\n\n"
  end
end

# Report about watering session
def report
  @litres_used = 0
  @total_session_duration = 0
  for i in 1..@number_of_zones_to_water do
    # litres_used = litres_used+ARGV[i].to_i*instance_variable_get("@zone_"+i.to_s+"_flow_rate")
    duration = instance_variable_get("@zone_"+i.to_s+"_duration").to_f
    flow_rate_sec = instance_variable_get("@zone_"+i.to_s+"_flow_rate").to_f
    # puts this_session_duration.to_s+"thissessionduration"
    litres_used_this_session = (duration*flow_rate_sec)
    # puts litres_used_this_session.to_s+"litres_used_this_session"
    @total_session_duration = @total_session_duration + duration
    @litres_used = @litres_used.to_f + litres_used_this_session.to_f
  end
  @total_session_duration = @total_session_duration/60
end

def notify
  report = Time.now.localtime.to_s+"A watering session has just finished. It lasted "+@total_session_duration.round(2).to_s+" minutes and used "+@litres_used.to_s+ " litres of water"
  url = URI.parse("https://api.pushover.net/1/messages.json")
  req = Net::HTTP::Post.new(url.path)
  req.set_form_data({
    :token => ENV['PUSHOVER_APP_TOKEN'],
    :user => ENV['PUSHOVER_USER_KEY'],
    :message => report,
  })
  res = Net::HTTP.new(url.host, url.port)
  res.use_ssl = true
  res.verify_mode = OpenSSL::SSL::VERIFY_PEER
  res.start {|http| http.request(req) }
  if ENV['PUSHOVER_APP_TOKEN'] != nil
    puts Time.now.localtime.to_s+" notified iOS application successfully"
  end
end

water_by_zone
report
notify
