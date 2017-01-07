#!/usr/bin/env python

import time
import grovepi

# Connect the Grove Relay to digital port D5. LED to D8
# SIG,NC,VCC,GND
relay = 5
led = 8

grovepi.pinMode(relay,"OUTPUT")

# switch on for 5 seconds
print ("Turning on the water")
grovepi.digitalWrite(relay,1)
grovepi.digitalWrite(led,1)
print ("Water is on")
time.sleep(100) # This is the duration of watering in minutes.

# switch off for 5 seconds
print ("Ending...turning off water")
grovepi.digitalWrite(relay,0)
grovepi.digitalWrite(led,0)
print ("Water is off")