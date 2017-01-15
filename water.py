#!/usr/bin/env python

# Primary watering controller. Waters the garden for the duration_of_watering specified (in seconds)

import time
import grovepi

# Connect the Grove Relay to digital port D5. LED to D8
# SIG,NC,VCC,GND
relay = 5
# Specify the duration of watering in seconds
duration_of_watering_in_seconds = 120
duration_of_watering_as_float = float(duration_of_watering_in_seconds)

grovepi.pinMode(relay,"OUTPUT")

print ("Attempting to turn on the water")
# Turn the relay to the on position
grovepi.digitalWrite(relay,1)
# Confirm the water is on. Note: Not sure how to verify this without some sort of flow sensor.
print ("Water is on")
# This is the duration of watering in seconds.
time.sleep(duration_of_watering_as_float)

# switch off for 5 seconds
print ("Ending...turning off water")
grovepi.digitalWrite(relay,0)
print ("Water is off")
