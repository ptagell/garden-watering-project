# Readme

A simple project to automate my home watering. I already have a quite extensive system of pipes and such set up to water my plants. The problem is that from what I've been reading it's best to water plants low and slow in the morning under mulch, rather than high and fast in the evening with a beer and hose. This is better for the plants from a mildew perspective and also conservse moisture as, if I water just before dawn, it will get a chance to soak in and get to the roots before the sun is high.

I'm not an early riser.

So, to overcome these things I've put together this series of scripts to control two solenoids (starting with one) on a timer using:

* Raspberry Pi
* Seeed Grove Pi sensor board
* Seeed relay
* Some 25mm solenoids
* A 240 > 24V transformer (this is the bit that worries me)
* Some garden safe sprinkler system automation wire.

## Challenges

As I see it, there are a few challenges I will face in this project.

1. Not that familiar with Python.

Everything to do with IoT seems to be in Python. I have more experience in Ruby so this could trip me up.

2. Not that familiar with electricity...and electricity and water don't mix.

Seems obious.

3. Learning raspberry pi.

Hurrah. In we go.

## Method

From a hardware perspective, I'm feeling pretty confident. Plug the things together in a circut and then plumb in the solenoids to the existing pipes.

Software is where it seems like there is more complexity, so I'm writing out these as somewhat logical steps to follow in this project.

[X] Be able to turn on and off the relay using a switch.
[X] Be able to turn on and off the relay using a script, keeping it on for a few seconds, then turning it off.
[X] Be able to turn the relay on for a period of minutes, then off again.
[ ] Be able to turn the relay on at a defined time for a period of time (eg. at 3pm for 20 mins). Stop scripts from stomping on each other.
[ ] Be able to do the same thing with more than one system.
[ ] Integrate my timing with Google Calendar to use that to turn on and off the system using named calendar events.
[ ] Deliver push notifications to my phone when watering is started, stopped or if there is an error.


### Be able to turn on and off the relay using a switch.

This was easy. I managed to do this using a built in Python script provided by the GrovePi Software

### Be able to turn on and off the relay using a script, keeping it on for a few seconds, then turning it off.

This was also achievable using a modified version of the script. Basically, adjusting the sleep duration after turning the Relay "On" was enough to make this work.

```
#!/usr/bin/env python

# NOTE: Relay is normally open. LED will illuminate when closed and you will hear a definitive click sound
import time
import grovepi
import sys


# Connect the Grove Relay to digital port D8
# SIG,NC,VCC,GND
relay = 7
led = 8

grovepi.pinMode(relay,"OUTPUT")

while True:
    try:
        # switch on for 5 seconds
        grovepi.digitalWrite(relay,1)
        grovepi.digitalWrite(led,1)
        print ("on")
        time.sleep(5)

        # switch off for 5 seconds
        grovepi.digitalWrite(relay,0)
        grovepi.digitalWrite(led,0)
        print ("Water off")
        time.sleep(5)

        sys.exit()

    except KeyboardInterrupt:
        grovepi.digitalWrite(relay,0)
        break
    except IOError:
        print ("Error")
```

### Be able to turn the relay on at a defined time for a period of time (eg. at 3pm for 20 mins). Stop scripts from stomping on each other.

Thoughts:

System
- Set up a cronjob to run every `n` mins.

Ruby (scheduling, APIs)
- Get `Time.now.hour` and `Time.now.min` using Ruby.
- If `Hour` and `Min` are within a target range at the time of checking, run a python script.

Python
- Run an `on` script for a `period` of time. This would run for n minutes and then turn off. Eventually, I could probably set `n` using the duration of a google calendar item.
- Close the script and python.

System
- Restart

This would let me run most of the logic in ruby and only dive into Python when I need to toggle the systems on or off.
