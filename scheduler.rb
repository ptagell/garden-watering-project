

# Specify a start time as the hour of the day (eg. 17 = 5pm)
start_time_hour = 20

# Find current time.
current_time = Time.now.hour

if start_time_hour == current_time
  puts "Reset grove to clear warnings"
  system("avrdude -c gpio -p m328p")
  puts "Grove Reset"

  puts "Turning on watering system"
  system("python /home/pi/Projects/garden/water.py")
  puts "Turning off watering system"

else
  puts "Not time to water yet"
endcrone
