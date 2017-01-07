#!/usr/bin/env python

# NOTE: Relay is normally open. LED will illuminate when closed and you will hear a definitive click sound
import time
import grovepi
import sys

# Connect the Grove Relay to digital port D8
# SIG,NC,VCC,GND
relay = 5
led = 8

grovepi.pinMode(relay,"OUTPUT")

while True:
    try:
        # switch on for 5 seconds
        grovepi.digitalWrite(relay,1)
        grovepi.digitalWrite(led,1)
        print ("Water is on")
        time.sleep(5) # This is the duration of watering in minutes.

        # switch off for 5 seconds
        grovepi.digitalWrite(relay,0)
        grovepi.digitalWrite(led,0)
        print ("Water is off")
        # time.sleep(5)
        print ("Now closing Python")
        sys.exit()

    except KeyboardInterrupt:
        grovepi.digitalWrite(relay,0)
        grovepi.digitalWrite(led,0)
        break
    except IOError:
        print ("Error")
