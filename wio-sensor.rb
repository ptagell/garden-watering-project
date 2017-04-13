require 'dotenv/load'

current_hour = Time.now.hour
puts Time.now.localtime.to_s+" Checking time and putting to sleep if required"
unless current_hour == 5
  system("curl -k -X POST https://us.wio.seeed.io/v1/node/pm/sleep/3590?access_token=#{ENV['WIO_TOKEN']}")
  puts Time.now.localtime.to_s+" Put to sleep for this hour"
else
  puts Time.now.localtime.to_s+" Rise and shine. Ready to water."
end
