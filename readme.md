# Readme

* [Overview](#overview)
* [Code](#code)
** [Code snippets](#codesnippets)
* [Plumbing](#plumbing)
** [Code snippets](#codesnippets)
* [Progress diary](#progress-diary)
* [Ideas](#ideas)

## Overview

A simple project to automate my home watering. I already have a quite extensive system of pipes and such set up to water my plants. The problem is that from what I've been reading it's best to water plants low and slow in the morning under mulch, rather than high and fast in the evening with a beer and hose. This is better for the plants from a mildew perspective and also conserve moisture as, if I water just before dawn, it will get a chance to soak in and get to the roots before the sun is high.

I'm not an early riser.

So, to overcome these things I've put together this series of scripts to control two solenoids (starting with one) on a timer using:

* [Raspberry Pi](https://littlebirdelectronics.com.au/products/raspberry-pi-2-model-b-1)
* [GrovePi+ board](https://www.dexterindustries.com/shop/grovepi-board/)
* [Seeed Studio Grove relay](https://www.seeedstudio.com/Grove-Relay-p-769.html)
* [Some 25mm solenoids](https://www.bunnings.com.au/k-rain-solenoid-valve_p3120237)
* [A 240 > 24V transformer](https://www.jaycar.us/mains-adaptor-24vac-1a-unregulated-bare-ends/p/MP3032) (this is the bit that worries me)
* Some [7 core irrigation wire](https://www.bunnings.com.au/toro-10m-7-core-irrigation-wire_p3110720).
* Existing watering system (made primarily with [19mm PVC poly pieces](https://www.bunnings.com.au/search/products?q=19mm%20poly))
* [Pope 25mm 3 outlet manifold](https://www.bunnings.com.au/pope-25mm-3-outlet-manifold_p3120691)
* 3 x lengths of BSP pipe
* [Assorted BSP 1" bits and pieces](https://www.bunnings.com.au/search/products?q=bsp%20pipe%201%22) - I would recommend staying away from the "[nut and tail](https://www.bunnings.com.au/pope-25mm-poly-nut-and-tail_p3123863)" type joins as they seem quite hard to get to stop leaking. 

![Map of plumbing and wiring](files/wiring.png)

# Code

## Challenges

As I see it, there are a few challenges I will face in this project.

* **Not that familiar with Python.**
Everything to do with IoT seems to be in Python. I have more experience in Ruby so this could trip me up.
* **Not that familiar with electricity...and electricity and water don't mix.**
Seems obvious.
* **Learning raspberry pi.**
Hurrah. In we go.


## Method & Progress

From a hardware perspective, I'm feeling pretty confident. Plug the things together in a circuit and then plumb in the solenoids to the existing pipes.

**Update**: This was completely wrong. Plumbing is hard when you care about saving water and removing leaks. It's actually really difficult to get cheap poly pipes, solenoids and valves under pressure not to leak. See the [plumbing section](#plumbing) for more info about this.

Software is where it seems like there is more complexity, so I'm writing out these as somewhat logical steps to follow in this project.

- [X] Be able to turn on and off the relay using a switch.
- [X] Be able to turn on and off the relay using a script, keeping it on for a few seconds, then turning it off.
- [X] Be able to turn the relay on for a period of minutes, then off again.
- [X] Be able to turn the relay on at a defined time for a period of time (eg. at 3pm for 20 mins). Stop scripts from stomping on each other.
- [ ] Be able to do the same thing with more than one system.
- [ ] Integrate my timing with Google Calendar to use that to turn on and off the system using named calendar events.
- [ ] Deliver push notifications to my phone when watering is started, stopped or if there is an error.



# Progress diary

## 6th Jan, 2017. 

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

## 7th Jan, 2017
### Be able to turn the relay on at a defined time for a period of time (eg. at 3pm for 20 mins). Stop scripts from stomping on each other.

#### Thoughts:

**System**
- Set up a cronjob to run every `n` mins.

**Ruby** (scheduling, APIs)
- Get `Time.now.hour` and `Time.now.min` using Ruby.
- If `Hour` and `Min` are within a target range at the time of checking, run a python script.

**Python**
- Run an `on` script for a `period` of time. This would run for n minutes and then turn off. Eventually, I could probably set `n` using the duration of a google calendar item.
- Close the script and python.

**System**
- Restart

This would let me run most of the logic in ruby and only dive into Python when I need to toggle the systems on or off.

### Report:

Got this working quite easily and much like the above.

I did run into a small issue whereby the Seed grove that I was using the control the relay would error and display a red RST light. Reading on the forums this is a relatively common issue with the board.

Apart from disconnecting the power, the only solution to the issue is to run a reset command for the board, which I've now put into a seperate ruby script so I can run it when I need to.

Another issue I've come across is that while the script seems to work all of the time, occasionally, the solenoid does not work. I'm not sure what could be causing this. It's either that the relay is not closing properly or that the solenoid isn't working. Potentially this could be to do with the mechanical components within the solenoid not making contact correctly, and therefore the solenoid circut not being completed. Strangely it does not happen every time though.

### 4:56pm, 7 Jan, 2017

_Success_. After assembling the solenoids, pi and watering systems, rewiring my shed with additional ethernet cables and bashing a hole through the tin side of my shed with a back-hoe, I've had my first successful test firing. I've been able to control the flow of water in my back garden safely using the internet! What a time to be alive. The joy, the wonder. Amaze.

The issue I found before whereby the solenoid would not fire has also seemingly resolved itself. Perhaps the solenoids work differently under pressure from the water than they do without this. Interesting.

My script also checks the time correctly in production, which is great.

My first trial only includes a single bed and I need one more relay before I can move onto the second step - controlling more than one zone. It's all wired up though, so should just be a question of ordering a few more relays (I suspect I want to move onto my garden lights next). I suspect the limiting factor for my beds will end up being water pressure. I also may need additional zones to cater to the fact that some plants need more water (usually vegetables) and some less (usually flowers and natives).  

## Monday 9th Jan 2017

### Disaster strikes

Just before leaving, I was showing @andryorwss went to look at the system and found that the three way manifold I'd created from poly pipe (leading from the mains and to the solenoids) had failed. This was due to the fact that the hoses before the manifold had popped off the valve due to the mains pressure. I was very glad this happened as it showed that my initial plumbing design had been flawed...if it hadn't failed when it did, my shed would've become even more flooded (the plastic box well and was overflowing with water when I found it).

I replaced the failed-manifold with one that was far better constructed, as well as the various connectors. This added $100 to the cost, but now I'm relatively confident that it won't burst again. I just need to remember to drain the irrigation system before winter sets in (and the pipes potentially freeze).

**Note**: Hardware list above has been updated.

## Sunday 15 Jan 2017.

After being away at the beach for a week with only as neighbour to check on the system, I've returned home and there is neither water leaking everywhere or a dry garden. The system worked. Although I initially had the system watering for 1 hour at 5am, I decided to change this to 30 minutes.

The logs I set up were also of great use. I was able to check each morning to make sure that, at least according to the logs, the system had turned off each morning.

# Ideas

Ideas for next steps for this project include: 

* Wireless, solar powered soil moisture sensors
* Wireless, solar charged, battery operated solenoids to allow bed-by-bed irrigation