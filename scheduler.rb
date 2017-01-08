# Specify a start time as the hour of the day (eg. 17 = 5pm)


# Find current time.
current_time_utc = Time.now
current_time_local = current_time_utc.localtime.hour
puts "Current UTC time is "+current_time_utc.to_s
puts "Current time hour is "+current_time_local.to_s

# puts Time.now.local

start_time_hour = 5
puts "Start time hour is "+start_time_hour.to_s

if start_time_hour == current_time_local
  puts Time.now.to_s+" Reset grove to clear warnings"
  system("avrdude -c gpio -p m328p")
  puts Time.now.to_s+" Grove Reset"

  puts Time.now.to_s+" Turning on watering system"
  system("python /home/pi/Projects/garden/water.py")
  puts Time.now.to_s+" Turning off watering system"
#
else
  puts Time.now.to_s+" Not time to water yet"
end
