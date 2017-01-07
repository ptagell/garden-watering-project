

# Specify a start time as the hour of the day (eg. 17 = 5pm)
start_time_hour = 11

# Find current time.
current_time = Time.now.hour

if start_time_hour == current_time
  puts "Turning on watering system"
  exec("python water.py 30")
  puts "Water turned off"
else
  puts "Not time to water yet"
end
