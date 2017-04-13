require 'dotenv/load'

current_hour = Time.now.hour
puts Time.now.localtime.to_s+" Checking time and putting to sleep if required"
unless current_hour == 5
  remainder_of_hour = ((59-Time.now.min)*60)+40
  system("curl -k -X POST https://us.wio.seeed.io/v1/node/pm/sleep/#{remainder_of_hour}?access_token=#{ENV['WIO_TOKEN']}")
  puts Time.now.localtime.to_s+" Have put system to sleep for the "+remainder_of_hour.to_s+"seconds remaining in the hour"
else
  puts Time.now.localtime.to_s+" Rise and shine. Ready to water."
end
