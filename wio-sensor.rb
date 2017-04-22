require 'dotenv/load'
require 'DateTime'
now = DateTime.now
puts DateTime.now.localtime.to_s+" Checking time and putting to sleep if required"
target_time = DateTime.new(now.year, now.month, now.day, 4, 59, 50, now.zone)
seconds_till_target_time = ((target_time-now)*24*60*60).to_i

# Sleep time is just under 5 hours. Max sleep time for Wio node is 5 hours.
max_sleep_duration_seconds = 17000

unless now.hour == target_time.hour+1
  if seconds_till_target_time > max_sleep_duration_seconds
    sleep_duration = max_sleep_duration_seconds
  else
    sleep_duration = seconds_till_target_time
  end
  system("curl -k -X POST https://us.wio.seeed.io/v1/node/pm/sleep/#{sleep_duration}?access_token=#{ENV['ZONE_1_WIO_TOKEN']}")
  puts Time.now.localtime.to_s+" Have put system to sleep for "+sleep_duration.to_s+" seconds."
else
  puts Time.now.localtime.to_s+" Rise and shine. Ready to water."
end
