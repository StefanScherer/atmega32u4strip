//
// Copyright (c) 2013 Danny Havenith
//
// Distributed under the Boost Software License, Version 1.0. (See accompanying
// file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef CHASERS_HPP_
#define CHASERS_HPP_
#include <stdlib.h>
#include <Adafruit_NeoPixel.h>
#include <string.h>
using ws2811::rgb;

namespace
{
static const uint16_t amplitudes[] = {
    256, 200, 150, 100, 80, 60, 50, 40, 30, 20, 10, 5, 4, 3, 2, 1
};
}
class chaser
{
public:
  void step( rgb *leds, int size)
  {
    step( size);
    draw( leds, size);
  }


  chaser( const rgb &color, uint16_t position, bool forward)
  :color( color), position(position), going_forward(forward)
  {}

  rgb   color;
  uint16_t position;
  bool   going_forward;

private:

  /// multiply an 8-bit value with an 8.8 bit fixed point number.
  /// multiplier should not be higher than 1.00 (or 256).
  static uint8_t mult( uint8_t value, uint16_t multiplier)
  {
    return (static_cast<uint16_t>( value) * multiplier) >> 8;
  }

  static rgb scale(rgb value, uint16_t amplitude)
  {
    return rgb(
        mult( value.red, amplitude),
        mult( value.green, amplitude),
        mult( value.blue, amplitude)
    );
  }

  static uint8_t add_clipped( uint16_t left, uint16_t right)
  {
    uint16_t result = left + right;
    if (result > 255) result = 255;
    return result;
  }

  static rgb add_clipped( const rgb &left, const rgb &right)
  {
    return rgb(
        add_clipped(left.red, right.red),
        add_clipped( left.green, right.green),
        add_clipped( left.blue, right.blue)
        );
  }

  void draw( rgb *leds, uint16_t end) const
  {
    uint16_t step = going_forward?static_cast<uint16_t>(-1):1;
    uint16_t pos = position;
    for (uint8_t count = 0; count < sizeof amplitudes/sizeof amplitudes[0];++count)
    {
      rgb value = scale( color, amplitudes[count]);
      if (pos < end)
      {
        leds[pos] = add_clipped( leds[pos], value);
      }
      pos += step;
      if( pos == end)
      {
        step = -step;
        pos = end -1;
      }
    }
  }

  void step( uint16_t end)
  {
    if (going_forward)
    {
      if (++position >= end)
      {
        position = end -1;
        going_forward = false;
      }
    }
    else
    {
      if (!--position)
      {
        going_forward = true;
      }
    }
  }

};


  chaser thechasers[] = { chaser( rgb( 50, 75, 15), 0, true),
              chaser( rgb( 10, 40, 60), 30, true),
              chaser( rgb( 255, 0,0), 50, true),
              chaser( rgb( 100, 100, 100), 35, false)
  };

class Chasers
{
public:


Chasers( Adafruit_NeoPixel *strip)
{
  this->strip = strip;


}

void animate()
{
  rgb *leds = (rgb *)strip->getPixels();
  memset( leds, 0, strip->numPixels()*sizeof(rgb));
  for ( uint8_t idx = 0; idx < sizeof thechasers/sizeof thechasers[0]; ++idx)
  {
   thechasers[idx].step( leds, strip->numPixels());
  }
  
  for (uint8_t i = 0; i < strip->numPixels(); i++)
  {
    strip->setPixelColor(i, leds->red, leds->green, leds->blue); // overwrite with brightness
    leds++;
  }
}

private:
  Adafruit_NeoPixel *strip;

};

#endif /* CHASERS_HPP_ */
