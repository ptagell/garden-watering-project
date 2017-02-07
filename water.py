#!/usr/bin/env python

# This script requires two parameters to be passed in the correct order to be run.
# The first parameter must specify the relay number, and the second parameter must
# specify the duration of watering in seconds.

# Primary watering controller. Waters the garden for the duration_of_watering specified (in seconds)
import sys
import time
import grovepi

# Accept parameters from Ruby/Command line and store for watering session
# Relay and Duration from Parameters
relay = int(sys.argv[1:][0])
duration = int(sys.argv[1:][1])
grovepi.pinMode(relay,"OUTPUT")

print ("PYTHON: Attempting to turn on the water")
# Turn the relay to the on position
grovepi.digitalWrite(relay,1)
# Confirm the water is on. Note: Not sure how to verify this without some sort of flow sensor.
print ("PYTHON: Water is on")
# This is the duration of watering in seconds.
time.sleep(duration)

print ("PYTHON: Ending...trying to turning off water")
# Turn the relay off.
grovepi.digitalWrite(relay,0)
print ("PYTHON: Water is off")
