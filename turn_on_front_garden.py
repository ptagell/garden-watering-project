#!/usr/bin/env python

# Code to specifically turn off the watering system in the event the "Off" code does not work using Python.

import time
import grovepi

# Connect the Grove Relay to digital port D5.
relay = 6

grovepi.pinMode(relay,"OUTPUT")

# switch off for 5 seconds
print ("Ending...turning off water")
grovepi.digitalWrite(relay,1)
print ("Water is on")
