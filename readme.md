# Readme

* [Overview](#overview)
* [Plumbing](#plumbing)
* [Electronics](#electronics)
* [Code](#code)
* [Ideas](#ideas)

# Overview

A simple project to automate my home watering. I already have a quite extensive system of pipes and such set up to water my plants. The problem is that from what I've been reading it's best to water plants low and slow in the morning under mulch, rather than high and fast in the evening with a beer and hose. This is better for the plants from a mildew and fungal perspective and also conserve moisture as, if I water just before dawn, it will get a chance to soak in and get to the roots before the sun is high.

I'm not an early riser.

So, to overcome these things I've put together this series of scripts to control two solenoids (starting with one) on a timer using:

* [Raspberry Pi](https://littlebirdelectronics.com.au/products/raspberry-pi-2-model-b-1)
* [GrovePi+ board](https://www.dexterindustries.com/shop/grovepi-board/)
* [Seeed Studio Grove relay](https://www.seeedstudio.com/Grove-Relay-p-769.html)
* [Some 25mm solenoids](https://www.bunnings.com.au/k-rain-solenoid-valve_p3120237)
* [A 240 > 24V transformer](https://www.jaycar.us/mains-adaptor-24vac-1a-unregulated-bare-ends/p/MP3032) (this is the bit that worries me)
* Some [7 core irrigation wire](https://www.bunnings.com.au/toro-10m-7-core-irrigation-wire_p3110720).
* [Irrigation wire connectors](https://www.bunnings.com.au/holman-wire-cable-irrigation-connectors-10-pack_p3119565)
* Existing watering system (made primarily with [19mm PVC poly pieces](https://www.bunnings.com.au/search/products?q=19mm%20poly))
* [Pope 25mm 3 outlet manifold](https://www.bunnings.com.au/pope-25mm-3-outlet-manifold_p3120691)
* 3 x lengths of rigid BSP pipe (thicker, solid pipe with male threaded ends)
* [Assorted BSP 1" bits and pieces](https://www.bunnings.com.au/search/products?q=bsp%20pipe%201%22) - I would recommend staying away from the "[nut and tail](https://www.bunnings.com.au/pope-25mm-poly-nut-and-tail_p3123863)" type joins as they seem quite hard to get to stop leaking.

I should also point out that I've found lots of great projects online which tackle this problem in similar ways. [Open Sprinkler Pi](https://opensprinkler.com/product/opensprinkler-pi/) really took my fancy, but I realised that because I already had a Pi and Grove, I didn't really need to buy a seperate controller.

**If you're considering this yourself, a word of warning**

This probably won't save you money.

It may not even save your garden.

For me, excluding the cost of the Pi and Grove (which I already had) the total cost of this experiment has probably been about $180AUD allowing $150 for plumbing supplies, $30 for additional power boards, ethernet cables etc.  This actually isn't insane given that it will easily cost [about $100](https://www.bunnings.com.au/search/products?facets=CategoryIdPath%3D2a021706-07d5-4648-bf26-2ea8fea049df%20%3E%2001f69b03-7098-42c3-b3c2-0a3c184efb7c%20%3E%20e5264067-f17e-4981-9c75-26549d354caa%20%3E%2042eb706d-7dc4-4acb-af34-f13db5f9c46a%20%3E%201cd2c5bb-f801-4add-bb56-6a7e8e76dce7) to buy a controller at your hardware shop and then you'll have to hand over more for solenoids, pipes, wires etc.

For me, the most important thing I've learnt through this project is the _consequences actions can have when you move from the digital world into the real world_. Most web developers and designers play in a world where the worst that can happen to them personally as a result of a failure in their decisions is that they get less conversions on a transactions, or their site goes offline for a few hours. In this project, making a mistake could cost me my garden (which could die or be drowned) or damage the foundations of my house (if the manifold or pipes burst and spew water out, underneath my house, for days while I'm away from home).

Still, I'd recommend this regardless. It's been great fun. I hope this helps you automate your own garden.

This document is broken into four sections for easy reference, and the code is really simple. I'll try and keep the software concerns seperate as I build this project out over time so you can pick it up and use what you need without needing to understand lots of complicated code. I'll also try and remember to comment lots so it's easy to understand. Thank you to all the other open source projects that do this also! It's only because of the forethought and generosity of time others have given that I've been able to learn how to do any of this.  

# Plumbing

The plumbing setup is quite simple.

![Map of plumbing and wiring](files/wiring.png)

Using my existing watering system, essentially my goal was to create an intelligent hub through which the water flowed when I wanted to.

To do this, the mains water goes into the manifold, where it is then stopped by the solenoids. When the solenoid is opened by the relays attached to the RPi, the water flows. By default, the relays are closed and take electric current to keep them open. This works for me because it means that in the event of a power-failure I won't flood my house.

Although I felt quite confident about the plumbing side of things, one of the things I learnt through this process is that it's actually really hard to do plumbing if you care about slow drips. Also important is to consider that this is one of the few projects where you're combining water and electricity - two things that shouldn't really meet unless you're interested in entering the Darwin awards.

![In order to avoid the Darwin awards, I put the solenoids in a box to contain any water explosions and splashes](/files/solenoids-in-box.jpg)

My first attempt at building out the manifold used 19mm Poly pipes and joiners to connect things. This didn't work so well and burst just before I proudly demonstrated my new fool-proof internet-powered garden watering system to [Andy Carson](https://github.com/arcarson). The mains water pressure was too much for the plastic clips I used.

![Attempt 1: Manifold made with Poly pipe](files/poly-pipe-manifold.png)

To solve this, I decided to replace the entire manifold and feeder system with more study rigid BSP pipes and [steel screw-tightened clips](https://www.bunnings.com.au/kinetic-11-25mm-304-stainless-steel-hose-clamps_p4920192) wherever I moved into poly pipe.

![Attempt 2: Proper PVC manifold and BSP threaded joiners](files/pvc-manifold.jpg)

Here you can see all the pieces assembled and in their box in preparation for going into my shed.

![All the pieces in one place before going into the shed](/files/all-the-pieces.jpg)

Once I put this in, I found that there was then an issue with the "Nut and Tail" joints I'd used at the end of the BSP. They leaked - I even cracked the plastic on one hand-tightening it so it wasn't going to last long. In the picture below you can see the failed unit on the bottom, and the replacement on the top.

![Avoid these Nut and tail joints if you can](/files/nut-and-tail.jpg)

 This is because it's difficult to get a tight enough seal as the joint is made in two pieces with a washer. I solved this buy replacing the Nut and tail with a BSP female threaded joint and one piece 19mm reducers.

![The final inlet/outlet pipe joins showing metal clips and one piece solid reducers](files/bsp-connectors.jpg)

Once I had this all assembled, I set up a `cron` job to trigger my watering system on and off for a minute at a time in order to pressure test and rock/jerk the system around a bit. Turning water one and off with a solenoid is quite a violent process (you'll hear it - there is quite a bit of pressure involved in mains water) and I think this is what caused my first iteration to fail. Turning it on and off rapidly means you get to i) see if it leaks and ii) hopefully accelerate any failure so you can fix it before you come to rely on it working properly.

# Electronics

From an electronics perspective, it took me a while to figure out what was needed. Thanks to by Grove Pi kit, I had a relay, but just no real idea how to use it. Also no idea how to avoid electrocute myself.

Enter many hours of youtube research and videos.

Through this research I found that I'd need to do the following:

![Map of electronics used](files/electronics.png)

1. Connect the black wire to one of the cables from each solenoid (they have two each) and also to the transformer. This is the "power wire" and provides one half of the circuit needed to turn on the solenoid.
2. The second wire (I chose red and white (shown as yellow) provides the "control" wire.
3. The "control" wire is fed through the relay and then back to the second wire from the transformer. This way, when the relay is activated, the circuit is completed and the solenoid is able to activate (allowing water to flow).

Because water is being used in close proximity to electricity here, I wouldn't recommend doing this unless you felt pretty confident in your knowledge. There are a few things I did to keep myself safe.

1. _Most importantly:_ I did not plug in the transformer until I was sure there were no exposed wires
2. I made sure that I put electrical tape over the ends of any exposed wires before I plugged anything in.
3. The transformer I used for this project takes the 240VAC (240 Volts Alternating Current) found in an Australian powerpoint and drops it down to 24VAC. This is a much lower voltage (garden lights use 12VAC so that you don't die if you cut through a wire), but I'd prefer to be safer than sorry. Supposedly a 24V current can kill you if it gets under your skin.
4. I put the solenoids (which were the piece most likely to come into direct contact with water) were inside a plastic tub. This way, if the solenoid failed or there was a leak, water wouldn't spay all over my shed, and would just dribble over the floor (turned out this safety feature was used :-) ).
5. I ended up using these nifty [little waterproof wire connectors](https://www.bunnings.com.au/holman-wire-cable-irrigation-connectors-10-pack_p3119565). They are one used only, but flood themselves with a gel when used to create a water proof seal on the wires. This is important as although the solenoids _shouldn't_ get wet when they're being used, as I found when I flooded mine, they can sometimes.

With all this in mind, I ended up with a situation like this.

![Brain Box](files/brain-box.jpg)

Here you can see:

1. Raspberry Pi and Grove Pi board on left inside green box.
2. Input compartment bottom right for 7 core irrigation wire.
3. First relay connected in it's own compartment (white wires)
4. Wires taped waiting for second relay to arrive from [Little Bird Electronics](https://littlebirdelectronics.com.au).
5.  Temperature/humidity sensor top right (for a [seperate project](http://tagell.com/projects/kyneton-temperature-logger/))
6.  Holes for ethernet and USB-power to come into the green box to power and control the Raspberry Pi.

# Code

## Challenges

For me there were are a few challenges I have/will faced in this project.

* **Not that familiar with Python.**
Everything to do with IoT seems to be in Python. I have more experience in Ruby so this could trip me up.
* **Not that familiar with electricity...and electricity and water don't mix.**
Seems obvious.
* **Learning raspberry pi.**
Hurrah. In we go.

## Method & Progress

To help myself overcome some of these issues, I've broken the challenge down into some smaller steps to knock over one at a time. I'll keep this list updated as I go.

- [X] Be able to turn on and off the relay using a switch.
- [X] Be able to turn on and off the relay using a script, keeping it on for a few seconds, then turning it off.
- [X] Be able to turn the relay on for a period of minutes, then off again.
- [X] Be able to turn the relay on at a defined time for a period of time (eg. at 3pm for 20 mins). Stop scripts from stomping on each other.
- [ ] Be able to do the same thing with more than one system.
- [ ] Be able to reliably start and stop smaller watering jobs (eg. 10 minute watering session) via my mobile phone - I currently use SimpleSSH for iOS but am keen to give [Prompt2](https://panic.com/prompt/) a go.
- [ ] MAYBE: Integrate with a home assistant so that I can verbally say "water my garden for `n` minutes" and actually have that work...because we live in the future (also gives me a good reason to buy said assistant)
- [ ] MAYBE: Integrate my timing with Google Calendar to use that to turn on and off the system using named calendar events.
- [ ] MAYBE: Deliver push notifications to my phone when watering is started, stopped or if there is an error.


# Code progress diary

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

Another issue I've come across is that while the script seems to work all of the time, occasionally, the solenoid does not work. I'm not sure what could be causing this. It's either that the relay is not closing properly or that the solenoid isn't working. Potentially this could be to do with the mechanical components within the solenoid not making contact correctly, and therefore the solenoid circuit not being completed. Strangely it does not happen every time though.

The crontab is pretty simple. Every hour, at 5 minutes past the hour, run the `schedule.rb` file. If the hour is correct, run the `water.py` script for the length of time provided in the original command parameter (in this case, 1800 seconds, or 30 minutes).

```
5 * * * *  ruby /home/pi/Projects/garden/scheduler.rb 1800 >> /tmp/cron_output

```

Eventually I'll need to expand this to allow for more parameters - for example, zones (-z) or time (-t).

### 4:56pm, 7 Jan, 2017

_Success_. After assembling the solenoids, pi and watering systems, rewiring my shed with additional ethernet cables and bashing a hole through the tin side of my shed with a back-hoe, I've had my first successful test firing. I've been able to control the flow of water in my back garden safely using the internet! What a time to be alive. The joy, the wonder. Amaze.

The issue I found before whereby the solenoid would not fire has also seemingly resolved itself. Perhaps the solenoids work differently under pressure from the water than they do without this. Interesting.

My script also checks the time correctly in production, which is great.

My first trial only includes a single bed and I need one more relay before I can move onto the second step - controlling more than one zone. It's all wired up though, so should just be a question of ordering a few more relays (I suspect I want to move onto my garden lights next). I suspect the limiting factor for my beds will end up being water pressure. I also may need additional zones to cater to the fact that some plants need more water (usually vegetables) and some less (usually flowers and natives).  

## Monday 9th Jan 2017

### Disaster strikes

Just before leaving, I was showing [@arcarson](https://github.com/arcarson) went to look at the system and found that the three way manifold I'd created from poly pipe (leading from the mains and to the solenoids) had failed. This was due to the fact that the hoses before the manifold had popped off the valve due to the mains pressure. I was very glad this happened as it showed that my initial plumbing design had been flawed...if it hadn't failed when it did, my shed would've become even more flooded (the plastic box well and was overflowing with water when I found it).

I replaced the failed-manifold with one that was far better constructed, as well as the various connectors. This added $100 to the cost, but now I'm relatively confident that it won't burst again. I just need to remember to drain the irrigation system before winter sets in (and the pipes potentially freeze).

**Note**: Hardware list above has been updated.

## Sunday 15 Jan 2017.

After being away at the beach for a week with only as neighbour to check on the system, I've returned home and there is neither water leaking everywhere or a dry garden. The system worked. Although I initially had the system watering for 1 hour at 5am, I decided to change this to 30 minutes.

The logs I set up were also of great use. I was able to check each morning to make sure that, at least according to the logs, the system had turned off each morning.

# Ideas

Ideas for next steps for this project include:

* Wireless, solar powered soil moisture sensors
* Wireless, solar charged, battery operated solenoids to allow bed-by-bed irrigation
