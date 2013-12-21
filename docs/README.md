# Introduction

I've just finished this little project controlling an LED strip with an Atmega32u4 breakout board. I started with an Adafruit Trinket with just 512 Bytes of RAM, but found a limit of about 80 LEDs using another code like a VU meter inside that also needs a little RAM.

So I switched to a bigger CPU and found the Adafruit Atmega32u4 breakout board. With 2.5 KByte RAM the development was much more straight forward without the low memory restrictions. 

# Features

The project should have following features

1. driving lots of LEDs, at the moment I have 2 meters of NeoPixel strip (60 LEDs/m)
2. controlled by an IR remote control
3. some LED effects using a microphone

# Hardware

The first setup of the parts was done with a breadboard. Flashing the Adafruit Trinket or the Atmega32u4 with a simple USB connection to the PC makes it really easy to develop the firmware.

1. Adafruit Atmega32u4 breakout board
2. Adafruit Electret Microphone Amplifier - MAX4466 with Adjustable Gain
3. Adafruit NeoPixel strip 60 LEDs/meter, 
4. Adafruit NeoPixel stick 8 x WS2812 LEDs for simple development/tests without the external power supply
5. 5V 2A power supply that I found from an old Transcend photo frame
6. IR remote control from the same old photo frame
7. TSOP4838 IR receiver
8. 470uF/25V 
9. a small case for the parts

![The complete hardware setup](https://github.com/StefanScherer/atmega32u4strip/raw/master/docs/images/complete-hardware-setup.jpg)

# Developing

Switching from Trinket to the bigger Atmega32u4 makes developing/debugging much more easier. The preinstalled bootloader offers an USB COM interface, so you just can add output in your code to be sent to the serial port and you can watch it inside the Arduino IDE's serial monitor.

The USB port is 'internal' and there is no hole in the case, so I have to open the case for debugging. I also have to remove the microphone breakout board which is connected with a three pin connector to the main board. After that I can reach the onboard reset button of the Atmega.

Pressing the reset button on the breakout board enters the bootloader again and you can then upload new code to the board. Flashing is pretty fast and after that you can reopen the serial monitor and watch the output of the new flashed code. Really simple.

![Debugging the LED controller](https://github.com/StefanScherer/atmega32u4strip/raw/master/docs/images/led-controller-debugging.jpg)

# Action

Here is a picture of the LED strip in action.

![LED's in action](https://github.com/StefanScherer/atmega32u4strip/raw/master/docs/images/leds-in-action.jpg)

On the IR remote control many buttons are already working

1. On / Off toggle button
2. Left and Right to switch between the different LED modes
3. Up and Down to speed up / slow down the LED cycle
4. Rotate to flip the animations
5. Volume Up and Down to increase / decrease the LED brightness

The maximum brightness of the LEDs is set the 80 in the code which does take about 5V / 1,1 A from the power supply in the lightest modes. I do not have a complete white mode, but the 2A power supply is enough to drive the 120 LEDs here.
