#!/usr/bin/env python

# Primary watering controller. Waters the garden for the duration_of_watering specified (in seconds)
import sys
import time
import grovepi

# Connect the Grove Relay to digital port D5.
relay = 5
# Specify the duration of watering in seconds.

# duration_of_watering_in_seconds received by seconds = 120
duration_of_watering_in_seconds = sys.argv[1:][0]
print(sys.argv[1:][0])

# Convert the watering duration value to a float as expected per sleep function.
duration_of_watering_as_float = float(duration_of_watering_in_seconds)

grovepi.pinMode(relay,"OUTPUT")

print duration_of_watering_as_float

print ("Attempting to turn on the water")
# Turn the relay to the on position
grovepi.digitalWrite(relay,1)
# Confirm the water is on. Note: Not sure how to verify this without some sort of flow sensor.
print ("Water is on")
# This is the duration of watering in seconds.
time.sleep(duration_of_watering_as_float)


print ("Ending...trying to turning off water")
# Turn the relay off.
grovepi.digitalWrite(relay,0)
print ("Water is off")
