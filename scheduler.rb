# required to push notifications
require "net/https"
# required to access .env variables
require 'dotenv/load'

#required for predictive watering based off weather.
require 'date'
require 'json'
require 'time'
require 'open-uri'

# This file is responsible for controlling when the `water.py` script is invoked.

# zone 1 settings
@zone_1_friendly_name = "Back Garden"
@zone_1_flow_rate = "20"
@zone_1_relay = 5
@zone_1_moisture_sensor_present = true
@zone_1_full_water_rate = 1200
@zone_1_duration = ARGV[0]

# zone 2 settings
@zone_2_friendly_name = "Front Garden"
@zone_2_flow_rate = "1.25"
@zone_2_relay = 4
@zone_2_moisture_sensor_present = false
@zone_2_full_water_rate = 4000
@zone_2_duration = ARGV[1]

# zone 3 settings
@zone_3_friendly_name = "Wicking Beds"
@zone_3_flow_rate = "20"
@zone_3_relay = 3
@zone_3_moisture_sensor_present = false
@zone_3_full_water_rate = 0
@zone_3_duration = ARGV[2]

@number_of_zones_to_water = ARGV.count
@session_start_time = Time.now.localtime
@weather_modifier = 100%

# duration of sleep (needed for resets)
@sleep_duration = 1

def retrieve_soil_moisture_data
  for i in 1..@number_of_zones_to_water do
    target_zone = instance_variable_get("@zone_"+i.to_s+"_moisture_sensor_present")
    if target_zone == true
      # note - will need to target specific zones for their moisture.
      zone_moisture_level = `python /Users/paultagell/Sites/moisture_sensor/grove_moisture_sensor.py`.to_i
      if zone_moisture_level.between?(200, 900)
        # no watering needed.
        # do not water zone.
        puts Time.now.localtime.to_s+" Stopping. No need to water as ground is at "+zone_moisture_level.to_s

      elsif zone_moisture_level.between?(100, 199)
        puts "between 100 and 200"
        retrieve_weather_data
        # expect percentage as return value. This could be a float.
        duration = instance_variable_get("@zone_"+i.to_s+"_full_water_rate") * weather_modifier * 75%

        # Light watering needed (1000 seconds)
          # will it rain in the next day. Invoke retieve weather data to return a condition,.
        # pass light watering value to zone n's relay value.

      elsif zone_moisture_level.between?(0, 99)
        puts "between 0 and 100"
        # heavy watering needed.
        retrieve_weather_data
        duration = instance_variable_get("@zone_"+i.to_s+"_full_water_rate") * weather_modifier * 100%

      end
    end
  end
end

def retrieve_weather_data
  puts Time.now.localtime.to_s+" Connecting to the weather underground to retrieve todays weather history"
  date = Date.today.strftime('%Y%m%d')
  url = "http://api.wunderground.com/api/545b187066a10a63/forecast"+"/geolookup/q/pws:IVICKYNE2.json"
  open(url) do |f|
    json_string = f.read
    @parsed_json = JSON.parse(json_string)
  end
  puts "finished"
  # puts @parsed_json['forecast']['simpleforecast']['forecastday']["pop"].to_s
  chance_of_rain = @parsed_json['forecast']['simpleforecast']['forecastday'][0]['pop'].to_i
  amount_of_rain = @parsed_json['forecast']['simpleforecast']['forecastday'][0]['qpf_allday']['mm'].to_i
  puts chance_of_rain
  puts amount_of_rain
  if chance_of_rain <= 80
    puts "between 0 and 80"
    if amount_of_rain >= 10
      #there is a low chance of rain, but if it does rain, it'll rain a lot
      weather_modifier = 75
      puts weather_modifier
    else
      #there is a low chance of rain, and even if it does rain, it won't rain much.
      weather_modifier = 100
      puts weather_modifier
    end
  else
    puts "between 81 and 100"
    if amount_of_rain >= 10
      #there's a high chance of rain, and if it does rain, it's going to rain a lot
      weather_modifier = 0
      puts weather_modifier
    else
      #there's a high chance of rain, but even if it does rain, it's not going to rain much
      weather_modifier = 50
      puts weather_modifier
    end
  end
end

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
      # grove_reset
      puts Time.now.localtime.to_s+" Session start time is "+@session_start_time.to_s
      water_garden(relay, duration)
      # grove_reset
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

retrieve_soil_moisture_data
#
# water_by_zone
# report
# notify




if params exist, use params.
  If no params exist, use auto-watering settings.
