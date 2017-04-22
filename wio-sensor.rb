require 'dotenv/load'
require 'date'
require 'json'
require 'time'
require 'open-uri'
require 'rest-client'

zones_to_water = ENV['ZONES_TO_WATER'].to_i
now = DateTime.now
puts DateTime.now.to_s+" Checking time and putting to sleep if required"
# Sleep time is just under 5 hours. Max sleep time for Wio node is 5 hours.
max_sleep_duration_seconds = 17000

# Set target tme and work out number of seconds till that time
target_time = DateTime.new(now.year, now.month, now.day, 4, 59, 50, now.zone)
# If target time is no longer the same day, adjust to the next day
if now.hour >= target_time.hour
  target_time = DateTime.new(now.year, now.month, now.day+1, 4, 59, 50, now.zone)
end
seconds_till_target_time = ((target_time-now)*24*60*60).to_i

(1..zones_to_water).each do |i|
  wio_token = "ZONE_"+i.to_s+"_WIO_TOKEN"
  unless ENV[wio_token].nil?
    unless now.hour == target_time.hour+1
      if seconds_till_target_time > max_sleep_duration_seconds
        sleep_duration = max_sleep_duration_seconds
      else
        sleep_duration = seconds_till_target_time
      end
      url = 'https://us.wio.seeed.io/v1/node/pm/sleep/'+sleep_duration.to_s+'?access_token='+ENV[wio_token].to_s
      system("curl -k -X POST #{url}")
      puts Time.now.localtime.to_s+" Have put system to sleep for "+sleep_duration.to_s+" seconds."
    else
      puts Time.now.localtime.to_s+" Rise and shine. Ready to water."
    end
  end
end
