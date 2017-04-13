# required to push notifications
require "net/https"
# required to access .env variables
require 'dotenv/load'
#required for predictive watering based off weather.
require 'date'
require 'json'
require 'time'
require 'open-uri'

# This file is responsible, along with .env, for controlling when the `water.py` script is invoked.
# How many zones will your garden have?
zones_to_water = ENV['ZONES_TO_WATER'].to_i
# What is the absolute path to this project on your Rasberry Pi

# zone 1 settings
@zone_1_friendly_name = ENV['ZONE_1_FRIENDLY_NAME']
@zone_1_flow_rate = ENV['ZONE_1_FLOW_RATE']
@zone_1_relay = ENV['ZONE_1_RELAY']
@zone_1_moisture_sensor_present = ENV['ZONE_1_MOISTURE_SENSOR_PRESENT']
@zone_1_moisture_sensor_relay = ENV['ZONE_1_MOISTURE_SENSOR_RELAY']
@zone_1_full_water_rate = ENV['ZONE_1_FULL_WATER_RATE'].to_f
@zone_1_duration = ARGV[0]

# zone 2 settings
@zone_2_friendly_name = ENV['ZONE_2_FRIENDLY_NAME']
@zone_2_flow_rate = ENV['ZONE_2_FLOW_RATE']
@zone_2_relay = ENV['ZONE_2_RELAY']
@zone_2_moisture_sensor_present = ENV['ZONE_2_MOISTURE_SENSOR_PRESENT']
@zone_2_moisture_sensor_relay = ENV['ZONE_2_MOISTURE_SENSOR_RELAY']
@zone_2_full_water_rate = ENV['ZONE_2_FULL_WATER_RATE'].to_f
@zone_2_duration = ARGV[1]

# zone 3 settings
# ... duplicate the settings above here and in the .env file to add a third (or more) zone...

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

  yesterday = (Date.today-1).strftime('%Y%m%d')
  # Yesterday's rainfall
  yesterday_url = "http://api.wunderground.com/api/#{ENV['WEATHER_UNDERGROUND_KEY']}/history_"+yesterday.to_s+"/geolookup/q/pws:IVICKYNE2.json"
  open(yesterday_url) do |f|
    json_string = f.read
    @history_parsed_json = JSON.parse(json_string)
  end


  # Today's forecast
  url = "http://api.wunderground.com/api/#{ENV['WEATHER_UNDERGROUND_KEY']}/forecast"+"/geolookup/q/pws:IVICKYNE2.json"
  open(url) do |f|
    json_string = f.read
    @parsed_json = JSON.parse(json_string)
  end
  puts Time.now.localtime.to_s+" Finished retrieving forecast"
  puts Time.now.localtime.to_s+" Extracting relevant data from forecast"
  chance_of_rain = @parsed_json['forecast']['simpleforecast']['forecastday'][0]['pop'].to_i
  amount_of_rain = @parsed_json['forecast']['simpleforecast']['forecastday'][0]['qpf_allday']['mm'].to_i
  yesterday_rainfall = @history_parsed_json['history']['dailysummary'][0]['precipm'].to_i

  if yesterday_rainfall >= 5
    @weather_modifier = 0
    report = Time.now.localtime.to_s+" There was "+yesterday_rainfall.to_s+"mm of rain yesterday, so not watering today"
    puts report
    messenger(report)

  else
    if chance_of_rain <= 79
      if amount_of_rain >= 10
        @weather_modifier = 0.75
        report = Time.now.localtime.to_s+" There is only a "+chance_of_rain.to_s+"% chance of rain today, but if it does rain, it's only predicted to rain "+amount_of_rain.to_s+"mm"
        puts report
        messenger(report)

      else
        @weather_modifier = 1.0
        report = Time.now.localtime.to_s+" There is only a "+chance_of_rain.to_s+"% chance of rain today, and even if it does rain, it's only predicted to rain "+amount_of_rain.to_s+"mm"
        puts report
        messenger(report)

      end
    else
      if amount_of_rain >= 10
        @weather_modifier = 0
        report = Time.now.localtime.to_s+" There's a "+chance_of_rain.to_s+"% chance of rain today, and if it does rain, it's predicted to rain around "+amount_of_rain.to_s+"mm"
        puts report
        messenger(report)

      else
        @weather_modifier = 0.5
        report = Time.now.localtime.to_s+" There's a "+chance_of_rain.to_s+"% chance of rain today, but even if it does rain, it's only predicted to rain "+amount_of_rain.to_s+"mm"
        puts report
        messenger(report)

      end
    end
  end
  puts Time.now.localtime.to_s+" Setting weather modifier to "+@weather_modifier.to_s
end

def retrieve_soil_moisture_data(i)

  sensor_url = "https://us.wio.seeed.io/v1/node/GroveMoistureA0/moisture?access_token=#{ENV['WIO_TOKEN']}"
  open(sensor_url) do |f|
    json_string = f.read
    @moisture_data = JSON.parse(json_string)
  end

  # Put Wio node sensor to sleep for

  zone_moisture_level = @moisture_data['moisture'].to_i
  # note - will need to target specific zones for their moisture.
  puts Time.now.localtime.to_s+" soil moisture is currently at "+zone_moisture_level.to_s
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
def water_garden(relay, duration, i)
  puts Time.now.localtime.to_s+" Turning on watering system for "+duration.to_s+" seconds"
  # Run Watering.py script for duration specified.
  # system("python water.py #{relay} #{duration}")
  puts @path_to_project
  system("python #{@path_to_project}water.py #{relay} #{duration.to_i}")
  puts Time.now.localtime.to_s+" Turning off watering system"

  @litres_used = 0
  @total_session_duration = 0
  # litres_used = litres_used+ARGV[i].to_i*instance_variable_get("@zone_"+i.to_s+"_flow_rate")
  flow_rate_sec = instance_variable_get("@zone_"+i.to_s+"_flow_rate").to_f/60.to_f

  # puts this_session_duration.to_s+"thissessionduration"
  # puts litres_used_this_session.to_s+"litres_used_this_session"
  @total_session_duration = duration.to_i/60
  @litres_used = (duration.to_f*flow_rate_sec.to_f).round(2)
  notify
end

def water_by_zone(i, duration)
  relay = instance_variable_get("@zone_"+i.to_s+"_relay")
  if duration.to_i != 0
    # grove_reset
    puts Time.now.localtime.to_s+" Session start time"
    water_garden(relay, duration, i)
    # grove_reset
    puts Time.now.localtime.to_s+" "+@friendly_name+" done"
  elsif duration.to_i == 0
    puts Time.now.localtime.to_s+" "+@friendly_name+" skipped as no duration specified"
  end
end

# Report about watering session

def messenger(report)
  url = URI.parse("https://api.pushover.net/1/messages.json")
  req = Net::HTTP::Post.new(url.path)
  req.set_form_data({
    :token => ENV['PUSHOVER_APP_TOKEN'],
    :user => ENV['PUSHOVER_USER_KEY'],
    :message => report,
    :title => "Crying Robot",
    :html => 1,
  })
  res = Net::HTTP.new(url.host, url.port)
  res.use_ssl = true
  res.verify_mode = OpenSSL::SSL::VERIFY_PEER
  res.start {|http| http.request(req) }

  if ENV['PUSHOVER_APP_TOKEN'] != nil
    puts Time.now.localtime.to_s+" notified iOS application successfully"
  end
end

def notify
  report = "<b>"+@friendly_name+" just finished watering</b>. It lasted "+@total_session_duration.round(2).to_s+" minutes and <b>used "+@litres_used.to_s+ " litres of water</b> Weather modifier was "+@weather_modifier.to_s
  messenger(report)
end


# ================ RUN SCRIPTS ===============
puts "\n\n Today's weather report \n\n\n"
retrieve_weather_data
if @auto_water == true
  puts Time.now.localtime.to_s+" Calculating auto-water logic for each zone"
  for i in 1..@number_of_zones_to_water do
    target_zone_has_sensor = instance_variable_get("@zone_"+i.to_s+"_moisture_sensor_present")
    @friendly_name = instance_variable_get("@zone_"+i.to_s+"_friendly_name").to_s
    puts "\n\n Beginning "+@friendly_name+"\n\n\n"
    if target_zone_has_sensor == "true"
      puts Time.now.localtime.to_s+" "+@friendly_name+" has a moisture sensor"
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
    @friendly_name = instance_variable_get("@zone_"+i.to_s+"_friendly_name").to_s
    puts "\n\n Beginning "+@friendly_name+"\n\n\n"
    duration = instance_variable_get("@zone_"+i.to_s+"_duration")
    water_by_zone(i, duration)
  end
end

puts "\n\n Running Reports \n\n\n"
