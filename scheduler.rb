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

# How many zones will your garden have?
zones_to_water = 3
# What is the absolute path to this project on your Rasberry Pi


# zone 1 settings
@zone_1_friendly_name = "Back Garden"
@zone_1_flow_rate = "20"
@zone_1_relay = 5
@zone_1_moisture_sensor_present = true
@zone_1_moisture_sensor_relay = 0
@zone_1_full_water_rate = 1200
@zone_1_duration = ARGV[0]

# zone 2 settings
@zone_2_friendly_name = "Front Garden"
@zone_2_flow_rate = "1.25"
@zone_2_relay = 4
@zone_2_moisture_sensor_present = false
@zone_2_full_water_rate = 7200
@zone_2_duration = ARGV[1]

# zone 3 settings
@zone_3_friendly_name = "Wicking Beds"
@zone_3_flow_rate = "20"
@zone_3_relay = 3
@zone_3_moisture_sensor_present = false
@zone_3_full_water_rate = 0
@zone_3_duration = ARGV[2]

@session_start_time = Time.now.localtime
@weather_modifier = 1.0 #default weather modifier value

if ARGV.count == 0
  @number_of_zones_to_water = zones_to_water
  @auto_water = true
else
  @number_of_zones_to_water = ARGV.count
  @auto_water = false
end

# duration of sleep (needed for resets)
@sleep_duration = 1
@path_to_project = ENV['PATH_TO_PROJECT']

def retrieve_weather_data
  puts Time.now.localtime.to_s+" Connecting to the weather underground to retrieve todays weather history"
  date = Date.today.strftime('%Y%m%d')
  url = "http://api.wunderground.com/api/#{ENV['WEATHER_UNDERGROUND_KEY']}/forecast"+"/geolookup/q/pws:IVICKYNE2.json"
  open(url) do |f|
    json_string = f.read
    @parsed_json = JSON.parse(json_string)
  end
  puts Time.now.localtime.to_s+" Finished retrieving forecast"
  puts Time.now.localtime.to_s+" Extracting relevant data from forecast"
  chance_of_rain = @parsed_json['forecast']['simpleforecast']['forecastday'][0]['pop'].to_i
  amount_of_rain = @parsed_json['forecast']['simpleforecast']['forecastday'][0]['qpf_allday']['mm'].to_i
  if chance_of_rain <= 80
    if amount_of_rain >= 10
      puts Time.now.localtime.to_s+" There is only a "+chance_of_rain.to_s+"% chance of rain today, but if it does rain, it's only predicted to rain "+amount_of_rain.to_s+"mm"
      @weather_modifier = 0.75
    else
      puts Time.now.localtime.to_s+" There is only a "+chance_of_rain.to_s+"% chance of rain today, and even if it does rain, it's only predicted to rain "+amount_of_rain.to_s+"mm"
      @weather_modifier = 1.0
    end
  else
    if amount_of_rain >= 10
      puts Time.now.localtime.to_s+" There's a "+chance_of_rain.to_s+"% chance of rain today, and if it does rain, it's predicted to rain around "+amount_of_rain.to_s+"mm"
      @weather_modifier = 0
    else
      puts Time.now.localtime.to_s+" There's a "+chance_of_rain.to_s+"% chance of rain today, but even if it does rain, it's only predicted to rain "+amount_of_rain.to_s+"mm"
      @weather_modifier = 0.5
    end
  end
  puts Time.now.localtime.to_s+" Setting weather modifier to "+@weather_modifier.to_s
end


def retrieve_soil_moisture_data(i)
      # note - will need to target specific zones for their moisture.
    zone_moisture_level = `python #{@path_to_project}grove_moisture_sensor.py`.to_i
    if zone_moisture_level >= 200 && zone_moisture_level <= 900
      puts Time.now.localtime.to_s+" Ground is moist. No water is needed"
    elsif zone_moisture_level >= 100 && zone_moisture_level <= 199
      puts Time.now.localtime.to_s+" Ground is relatively moist. Only a light watering is needed."
      duration = instance_variable_get("@zone_"+i.to_s+"_full_water_rate")*@weather_modifier*0.75
      water_by_zone(i, duration)
    elsif zone_moisture_level >=0 && zone_moisture_level <= 99
      puts Time.now.localtime.to_s+" Ground is dry. Heavy watering required."
      duration = instance_variable_get("@zone_"+i.to_s+"_full_water_rate")*@weather_modifier*1.0
      water_by_zone(i, duration)
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
  puts Time.now.localtime.to_s+" Turning on watering system for "+duration.to_s+" seconds"
  # Run Watering.py script for duration specified.
  # system("python water.py #{relay} #{duration}")
  system("python #{@path_to_project}water.py #{relay} #{duration.to_i}")
  puts Time.now.localtime.to_s+" Turning off watering system"
end

def water_by_zone(i, duration)
  relay = instance_variable_get("@zone_"+i.to_s+"_relay")
  if duration.to_i != 0
    # grove_reset
    puts Time.now.localtime.to_s+" Session start time"
    water_garden(relay, duration)
    # grove_reset
    puts Time.now.localtime.to_s+" "+instance_variable_get("@zone_"+i.to_s+"_friendly_name")+" done"
  elsif duration.to_i == 0
    puts Time.now.localtime.to_s+" "+instance_variable_get("@zone_"+i.to_s+"_friendly_name")+" skipped as no duration specified"
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


# ================ RUN SCRIPTS ===============

puts "\n\n Today's weather report \n\n\n"

retrieve_weather_data

if @auto_water == true
  puts Time.now.localtime.to_s+" Calculating auto-water logic for each zone"
  for i in 1..@number_of_zones_to_water do

    target_zone_has_sensor = instance_variable_get("@zone_"+i.to_s+"_moisture_sensor_present")
    friendly_name = instance_variable_get("@zone_"+i.to_s+"_friendly_name")
    puts "\n\n Beginning "+friendly_name+"\n\n\n"
    if target_zone_has_sensor == true
      puts Time.now.localtime.to_s+" "+friendly_name+" has a moisture sensor"
      retrieve_soil_moisture_data(i)
    else
      puts Time.now.localtime.to_s+" Target zone does not have a moisture sensor."
      duration = instance_variable_get("@zone_"+i.to_s+"_full_water_rate").to_f*@weather_modifier.to_f
      puts Time.now.localtime.to_s+" Using default watering settings for this zone."
      water_by_zone(i, duration)
    end
  end
else
  # water based off parameters instead of autowater
  for i in 1..@number_of_zones_to_water do
    friendly_name = instance_variable_get("@zone_"+i.to_s+"_friendly_name")
    puts "\n\n Beginning "+friendly_name+"\n\n\n"
    duration = instance_variable_get("@zone_"+i.to_s+"_duration")
    water_by_zone(i, duration)
  end
end

puts "\n\n Running Reports \n\n\n"

report
notify
