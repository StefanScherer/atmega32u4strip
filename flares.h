//
// Copyright (c) 2013 Danny Havenith
//
// Distributed under the Boost Software License, Version 1.0. (See accompanying
// file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef FLARES_HPP_
#define FLARES_HPP_
#include <stdlib.h>
#include <Adafruit_NeoPixel.h>

namespace 
{
using ws2811::rgb;

class flare
{
public:
  void step( rgb *leds)
  {
    step();
    set( leds);
  }

  flare()
  :color( 255,255,255), position(0), amplitude(0), speed(0)
  {}

  rgb    color;
  uint16_t position;
  uint16_t amplitude;
  int8_t    speed;

private:

  /// multiply an 8-bit value with an 8.8 bit fixed point number.
  /// multiplier should not be higher than 1.00 (or 256).
  static uint8_t mult( uint8_t value, uint16_t multiplier)
  {
    return (static_cast<uint16_t>( value) * multiplier) >> 8;
  }

  rgb calculate() const
  {
    return rgb(
        mult( color.red, amplitude),
        mult( color.green, amplitude),
        mult( color.blue, amplitude)
    );
  }

  void set( rgb *leds) const
  {
    rgb *myled = leds + position;
    *myled = calculate();
  }

  void step()
  {
    if (speed < 0 && static_cast<uint16_t>(-speed) > amplitude)
    {
      amplitude = 0;
    }
    else
    {
      amplitude += speed;
      if (amplitude > 256)
      {
        amplitude = 256;
        speed = -(speed/4 + 1);
      }
    }
  }

};

uint8_t random_brightness()
{
  return  150 - (rand() % 80);
}

void create_random_flare( flare &f, uint16_t count)
{
  f.color = rgb( random_brightness(), random_brightness(), random_brightness());
  f.amplitude = 0;
  f.position = rand() % count; // not completely random.
  f.speed = (2 * (rand() & 0x07))+4;
}

} // end namespace flares

class Flares
{
 
public:
  
Flares( Adafruit_NeoPixel *strip)
{
  this->strip = strip;
    current_flare = 0;
    flare_pause = 1;

}

void animate()
{
  rgb *leds = (rgb *)strip->getPixels();
  
      if (flare_pause)
      {
        --flare_pause;
      }
      else
      {
        if (!flares[current_flare].amplitude)
        {
          create_random_flare( flares[current_flare], strip->numPixels());
          ++current_flare;
          if (current_flare >= flare_count) current_flare = 0;
          flare_pause = rand() % 80;
        }
      }

      for (uint8_t idx = 0; idx < flare_count; ++idx)
      {
        flares[idx].step( leds);
      }


  for (uint8_t i = 0; i < strip->numPixels(); i++)
  {
    strip->setPixelColor(0, leds->red, leds->green, leds->blue); // overwrite with brightness
    leds++;
  }
  strip->show();
}

private:
  Adafruit_NeoPixel *strip;
    static const uint8_t flare_count = 16;
    flare flares[flare_count];
    uint8_t current_flare;
    uint8_t flare_pause;
  
};









#endif /* FLARES_HPP_ */
