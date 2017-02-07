#!/usr/bin/env python

import time
import grovepi

# Connect the Grove Moisture Sensor to analog port A0
# SIG,NC,VCC,GND
sensor = 0

# uncomment when working
print(grovepi.analogRead(sensor))
