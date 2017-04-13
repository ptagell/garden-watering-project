require 'dotenv/load'

current_hour = Time.now.hour
unless current_hour == 5
  system("curl -k -X POST https://us.wio.seeed.io/v1/node/pm/sleep/200?access_token=#{ENV['WIO_TOKEN']}")
else
  # Do nothing. Watering script will control for this hour.
end
