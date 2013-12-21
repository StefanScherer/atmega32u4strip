/*
 atmega32u4strip
 
 Have some fun with an Adafruit Atmega32u4 breakout board and 2 meters NeoPixel LED strip.

 Hardware requiremetns:
 - Adafruit Atmega32u4 breakout board
 - Adafruit Electret Microphone Amplifier (ID: 1063)
   connected to pin B4 (analog ADC11)
 - Adafruit NeoPixel Digitial LED strip or anything like that
   connectet to pin B5 (OC1A)
 - an IR receiver (TSOP 4838)
   connected to pin B6 (OC1B)

 Written by Stefan Scherer under the BSD license.
 This parapgraph must be included in any redistribution.
 
*/


#include <IRremote.h>
#include <Adafruit_NeoPixel.h>




/*
Transcend Remote Control
*/

#define KEY_POWER     0x67940BF
#define KEY_MENU      0x6794AB5

#define KEY_MUSIC     0x679AA55
#define KEY_CALENDAR  0x6796A95
#define KEY_SETTINGS  0x679807F
#define KEY_THUMBNAIL 0x6792AD5
#define KEY_PHOTOVIEW 0x679C03F
#define KEY_SLIDESHOW 0x679609F
#define KEY_SELECT    0x67910EF

#define KEY_LEFT      0x67918E7
#define KEY_UP        0x6791AE5
#define KEY_OK        0x679DA25
#define KEY_RIGHT     0x6799867
#define KEY_DOWN      0x6795AA5

#define KEY_OPTIONS   0x679EA15
#define KEY_PAGEDOWN  0x67928D7
#define KEY_PAGEUP    0x679C837
#define KEY_ROTATE    0x67920DF

#define KEY_PLAYLIST  0x679CA35
#define KEY_ADDDEL    0x679A857
#define KEY_FAVORITES 0x6796897
#define KEY_ZOOM      0x67958A7

#define KEY_PREVSONG  0x67938C7
#define KEY_PLAYPAUSE 0x679708F
#define KEY_NEXTSONG  0x679B847
#define KEY_BACKLIGHT 0x6799A65

#define KEY_MODE      0x679F807
#define KEY_STOP      0x679B04F
#define KEY_MUTE      0x67948B7
#define KEY_SLEEP     0x67950AF

#define KEY_VOLDOWN   0x6797887
#define KEY_VOLUP     0x679A05F


// IR receiver settings and variables

int RECV_PIN = CORE_INT1_PIN;  // IR receiver TSOP4838 is connected to this pin (SDA/INT1/D1)

IRrecv irrecv(RECV_PIN);
decode_results results;


// NeoPixel settings and variables

#define STRIP_PIN  CORE_T1_PIN  // NeoPixel LED strand is connected to this pin (T1/!OC4D/ADC9/D6)

#define N_PIXELS   120  // Number of pixels in strand


#define LAST_PIXEL_OFFSET N_PIXELS-1
  
// Parameter 1 = number of pixels in strip
// Parameter 2 = pin number (most are valid)
// Parameter 3 = pixel type flags, add together as needed:
//   NEO_KHZ800  800 KHz bitstream (most NeoPixel products w/WS2812 LEDs)
//   NEO_KHZ400  400 KHz (classic 'v1' (not v2) FLORA pixels, WS2811 drivers)
//   NEO_GRB     Pixels are wired for GRB bitstream (most NeoPixel products)
//   NEO_RGB     Pixels are wired for RGB bitstream (v1 FLORA pixels, not v2)
Adafruit_NeoPixel strip = Adafruit_NeoPixel(N_PIXELS, STRIP_PIN, NEO_GRB + NEO_KHZ800);


// Microphone settings and variables

#define MIC_PIN    0  // Microphone is attached to this analog pin (T0/OC4D/ADC10/D7)
#define DC_OFFSET  0  // DC offset in mic signal - if unusure, leave 0
#define NOISE     30  // Noise/hum/interference in mic signal
#define SAMPLES   60  // Length of buffer for dynamic level adjustment
#define TOP       (N_PIXELS + 1) // Allow dot to go slightly off scale
#define PEAK_FALL_MILLIS 10  // Rate of peak falling dot

int
  peak      = 0,      // Used for falling dot
  volCount  = 0;      // Frame counter for storing past volume data
int
  vol[SAMPLES];       // Collection of prior volume samples
int
  lvl       = 10,     // Current "dampened" audio level
  minLvlAvg = 0,      // For dynamic adjustment of graph low & high
  maxLvlAvg = 512;



// Modes
enum 
{
  MODE_OFF,
  MODE_WIPE_RED,
  MODE_WIPE_GREEN,
  MODE_WIPE_BLUE,
  MODE_WIPE_YELLOW,
  MODE_WIPE_CYAN,
  MODE_WIPE_MAGENTA,
  MODE_WIPE_COLORS,
  MODE_RAINBOW,
  MODE_RAINBOW_CYCLE,
  MODE_VUMETER,
  MODE_DOT_UP,
  MODE_DOT_DOWN,
  MODE_DOT_ZIGZAG,
  MODE_COLOR_STRIPS,
  MODE_MAX
} MODE;


int mode = MODE_WIPE_RED;
int powerSaveMode = MODE_WIPE_RED;
bool reverse = false;

int BRIGHTNESS_MAX = 80;
int brightness = 20;

// cycle variables
int CYCLE_MIN_MILLIS = 2;
int CYCLE_MAX_MILLIS = 1000;
int cycleMillis = 20;
bool paused = false;
long lastTime = 0;


void setup()
{
  Serial.begin(9600);
  irrecv.enableIRIn(); // Start the receiver
  
  strip.begin();
  strip.setBrightness(brightness);
  show(); // Initialize all pixels to 'off'
 
  // clear vumeter
  memset(vol, 0, sizeof(vol)); 
  
  Serial.println("Setup done");
}


void loop()
{
  if (irrecv.decode(&results))
  {
    if (results.bits)
    {
      Serial.println(results.value, HEX);
//      dump(&results);

      int n = -120;
      switch (results.value)
      {
        case KEY_POWER:
          n = 0;
          if (mode)
          {
            powerSaveMode = mode; // save current mode
            mode = MODE_OFF;
          }
          else
          {
            mode = powerSaveMode; // restore saved mode
          }
        break;
          
        case KEY_RIGHT:
          n = 1;
          paused = false;
          break;
        
        case KEY_LEFT:
          n = -1;
          paused = false;
          break;
        
        case KEY_UP:
          // speed up
          if (cycleMillis < 12)
          {
            cycleMillis--;
          }
          else
          {
            cycleMillis = cycleMillis / 1.25;
          }
          if (cycleMillis <CYCLE_MIN_MILLIS) cycleMillis = CYCLE_MIN_MILLIS;
          break;
          
        case KEY_DOWN:
          // slow down
          if (cycleMillis < 12)
          {
            cycleMillis++;
          }
          else
          {
            cycleMillis = cycleMillis * 1.25;
          }
          if (cycleMillis >CYCLE_MAX_MILLIS) cycleMillis = CYCLE_MAX_MILLIS;
          break;
          
        case KEY_PLAYPAUSE:
          paused = !(paused);
          break;
          
        case KEY_VOLUP:
          brightness++;
          if (brightness > BRIGHTNESS_MAX) brightness = BRIGHTNESS_MAX;
          strip.setBrightness(brightness);
          n = 0; // re-render
          break;

        case KEY_VOLDOWN:
          brightness--;
          if (brightness < 0) brightness = 0;
          strip.setBrightness(brightness);
          n = 0; // re-render
          break;
          
        case KEY_ROTATE:
          reverse = !(reverse);
          break;
      }

      if (n != -120)
      {
        switchMode(n);
      }
    }
    irrecv.resume(); // Receive the next value
  }
  
  switch (mode) {
    case MODE_OFF:
      off();
      break;

    case MODE_VUMETER:
      vumeter();
      break;

    case MODE_DOT_UP:
      runningDotUp();
      break;

    case MODE_DOT_DOWN:
      runningDotDown();
      break;

    case MODE_DOT_ZIGZAG:
      runningDotZigZag();
      break;

    case MODE_RAINBOW:
      rainbow();
      break;

    case MODE_RAINBOW_CYCLE:
      rainbowCycle();
      break;

    case MODE_WIPE_RED:
      colorWipe(255, 0, 0);
      break;

    case MODE_WIPE_GREEN:
      colorWipe(0, 255, 0);
      break;

    case MODE_WIPE_BLUE:
      colorWipe(0, 0, 255);
      break;

    case MODE_WIPE_YELLOW:
      colorWipe(255, 255, 0);
      break;

    case MODE_WIPE_CYAN:
      colorWipe(0, 255, 255);
      break;

    case MODE_WIPE_MAGENTA:
      colorWipe(255, 0, 255);
      break;
      
    case MODE_COLOR_STRIPS:
      colorStripsCycle();
      break;

      
  }  
}


void show()
{
  while (!irrecv.isIdle())
  {
     delay(1);
//     Serial.println("show() called, but irrecv is not idle!");
  }
  
  strip.show();
//  irrecv.resume(); // Throw away values in the meantime because interrupts were stopped
}

void off()
{
  if (peak != N_PIXELS) // only once
  {
    peak = N_PIXELS; // move outside
    drawDot();
  }
}


void switchMode(int steprate)
{
  peak = 0;
  lvl = 10;
  mode += steprate;
  if (mode >= MODE_MAX)
  {
    mode = 1;
  }
  else if (steprate && mode <= 0) // if steprate = 0, also allow mode = 0
  {
    mode = MODE_MAX-1;
  }
  Serial.print("switchMode to ");
  Serial.print(mode, DEC);
  Serial.println("");
  

}

bool cycle()
{
  if (paused)
  {
    return false;
  }
  
  if (millis() - lastTime >= cycleMillis)
  {
    lastTime = millis();
    return true;
  }
  return false;
}

void runningDotUp()
{
  if (cycle())
  {
    drawDot();
 
    if (peak>=LAST_PIXEL_OFFSET)
    {
      peak = 0;
    }
    else
    {
      peak++;
    }
  }
}

void runningDotDown()
{
  if (cycle())
  {
    drawDot();
 
    if (peak <= 0)
    {
      peak = LAST_PIXEL_OFFSET;
    }
    else
    {
      peak--;
    }
  }
}

byte runningDotZigZag()
{
  byte prevpeak = peak;
  if (reverse)
  {
    runningDotDown();
    if (prevpeak != peak && peak == LAST_PIXEL_OFFSET)
    {
      reverse = false;
      peak = prevpeak;
    }
  }
  else
  {
    runningDotUp();
    if (prevpeak != peak && !peak)
    {
      reverse = true;
      peak = prevpeak;
    }
  }
}



void drawDot()
{
  for (int i=0; i<N_PIXELS;i++)
  {
    if (i != peak)
    {
      strip.setPixelColor(i, 0,0,0);
    }
    else
    {
      strip.setPixelColor(i, 255,255,255);
    }
  }
  show();
}

// Fill the dots one after the other with a color
void colorWipe(uint8_t r, uint8_t g, uint8_t b)
{
  if (cycle())
  {
    int pixel = peak;
    if (reverse)
    {
      pixel = LAST_PIXEL_OFFSET - peak;
    }
    
    strip.setPixelColor(peak, r, g, b);

    if (peak <= LAST_PIXEL_OFFSET)
    {
      show();
      peak++;
    }
  }
}

void rainbow()
{
  uint16_t i;

  if (cycle())
  {
    if (lvl >= 256)
    {
      lvl = 0;
    }
    else
    {
      lvl++;
    }
    
    for(i=0; i<strip.numPixels(); i++)
    {
      int pixel = i;
      if (reverse)
      {
        pixel = LAST_PIXEL_OFFSET - i;
      }
      strip.setPixelColor(pixel, Wheel((i+lvl) & 255));
    }
    show();
  }
}

// Slightly different, this makes the rainbow equally distributed throughout
void rainbowCycle() {
  uint16_t i;

  if (cycle())
  {
    if (lvl >= 5*256) // 5 cycles of all colors on wheel
    {
      lvl = 0;
    }
    else
    {
      lvl++;
    }
    
    for(i=0; i< strip.numPixels(); i++)
    {
      int pixel = i;
      if (reverse)
      {
        pixel = LAST_PIXEL_OFFSET - i;
      }      
      strip.setPixelColor(pixel, Wheel(((i * 256 / strip.numPixels()) + lvl) & 255));
    }
    show();
  }
}

void colorStripsCycle() {
  uint16_t i;

  if (cycle())
  {
    if (lvl >= 120)
    {
      lvl = 0;
    }
    else
    {
      lvl++;
    }
    
    for(i=0; i< strip.numPixels(); i++)
    {
      int pixel = i;
      if (reverse)
      {
        pixel = LAST_PIXEL_OFFSET - i;
      }
      strip.setPixelColor(pixel, ColorStrips(i+lvl));
    }
    show();
  }
}

void vumeter()
{
  uint8_t  i;
  uint16_t minLvl, maxLvl;
  int      n, height;

  n   = analogRead(MIC_PIN);                        // Raw reading from mic 
  n   = abs(n - 512 - DC_OFFSET); // Center on zero
  n   = (n <= NOISE) ? 0 : (n - NOISE);             // Remove noise/hum
  lvl = ((lvl * 7) + n) >> 3;    // "Dampened" reading (else looks twitchy)

  // Calculate bar height based on dynamic min/max levels (fixed point):
  height = TOP * (lvl - minLvlAvg) / (long)(maxLvlAvg - minLvlAvg);

  if(height < 0L)       height = 0;      // Clip output
  else if(height > TOP) height = TOP;
  if(height > peak)     peak   = height; // Keep 'peak' dot at top


#ifdef CENTERED
 // Color pixels based on rainbow gradient
  for(i=0; i<(N_PIXELS/2); i++) {
    if(((N_PIXELS/2)+i) >= height)
    {
      strip.setPixelColor(((N_PIXELS/2) + i),   0,   0, 0);
      strip.setPixelColor(((N_PIXELS/2) - i),   0,   0, 0);
    }
    else
    {
      strip.setPixelColor(((N_PIXELS/2) + i),Wheel(map(((N_PIXELS/2) + i),0,strip.numPixels()-1,30,150)));
      strip.setPixelColor(((N_PIXELS/2) - i),Wheel(map(((N_PIXELS/2) - i),0,strip.numPixels()-1,30,150)));
    }
  }
  
  // Draw peak dot  
  if(peak > 0 && peak <= LAST_PIXEL_OFFSET)
  {
    strip.setPixelColor(((N_PIXELS/2) + peak),255,255,255); // (peak,Wheel(map(peak,0,strip.numPixels()-1,30,150)));
    strip.setPixelColor(((N_PIXELS/2) - peak),255,255,255); // (peak,Wheel(map(peak,0,strip.numPixels()-1,30,150)));
  }
#else
  // Color pixels based on rainbow gradient
  for(i=0; i<N_PIXELS; i++)
  {
    if(i >= height)
    {
      strip.setPixelColor(i,   0,   0, 0);
    }
    else
    {
      strip.setPixelColor(i,Wheel(map(i,0,strip.numPixels()-1,30,150)));
    }
  }

  // Draw peak dot  
  if(peak > 0 && peak <= LAST_PIXEL_OFFSET)
  {
    strip.setPixelColor(peak,255,255,255); // (peak,Wheel(map(peak,0,strip.numPixels()-1,30,150)));
  }
  
#endif  

  // Every few frames, make the peak pixel drop by 1:

  if (millis() - lastTime >= PEAK_FALL_MILLIS)
  {
    lastTime = millis();

    show(); // Update strip

    //fall rate 
    if(peak > 0) peak--;
    }

  vol[volCount] = n;                      // Save sample for dynamic leveling
  if(++volCount >= SAMPLES) volCount = 0; // Advance/rollover sample counter

  // Get volume range of prior frames
  minLvl = maxLvl = vol[0];
  for(i=1; i<SAMPLES; i++)
  {
    if(vol[i] < minLvl)      minLvl = vol[i];
    else if(vol[i] > maxLvl) maxLvl = vol[i];
  }
  // minLvl and maxLvl indicate the volume range over prior frames, used
  // for vertically scaling the output graph (so it looks interesting
  // regardless of volume level).  If they're too close together though
  // (e.g. at very low volume levels) the graph becomes super coarse
  // and 'jumpy'...so keep some minimum distance between them (this
  // also lets the graph go to zero when no sound is playing):
  if((maxLvl - minLvl) < TOP) maxLvl = minLvl + TOP;
  minLvlAvg = (minLvlAvg * 63 + minLvl) >> 6; // Dampen min/max levels
  maxLvlAvg = (maxLvlAvg * 63 + maxLvl) >> 6; // (fake rolling average)
}



// Input a value 0 to 255 to get a color value.
// The colours are a transition r - g - b - back to r.
uint32_t Wheel(byte WheelPos) {
  if(WheelPos < 85) {
   return strip.Color(WheelPos * 3, 255 - WheelPos * 3, 0);
  } else if(WheelPos < 170) {
   WheelPos -= 85;
   return strip.Color(255 - WheelPos * 3, 0, WheelPos * 3);
  } else {
   WheelPos -= 170;
   return strip.Color(0, WheelPos * 3, 255 - WheelPos * 3);
  }
}


// Input a value 0 to 119 to get a color value.
uint32_t ColorStrips(int WheelPos)
{
  int offset = WheelPos % 20;
  int col = (WheelPos % 120) / 20;
  
  int light = 255-(offset*16);
  if (light < 0) light = 0;
  
  switch (col)
  {
    case 0:
    default:
      return strip.Color(light,0,0);
    case 1:
      return strip.Color(0,light,0);
    case 2:
      return strip.Color(light,0,light);
    case 3:
      return strip.Color(0,light,light);
    case 4:
      return strip.Color(light,light,0);
    case 5:
      return strip.Color(0,0,light);
  }
}




// Dumps out the decode_results structure.
// Call this after IRrecv::decode()
// void * to work around compiler issue
//void dump(void *v) {
//  decode_results *results = (decode_results *)v
void dump(decode_results *results) {
  int count = results->rawlen;
  if (results->decode_type == UNKNOWN) {
    Serial.print("Unknown encoding: ");
  } 
  else if (results->decode_type == NEC) {
    Serial.print("Decoded NEC: ");
  } 
  else if (results->decode_type == SONY) {
    Serial.print("Decoded SONY: ");
  } 
  else if (results->decode_type == RC5) {
    Serial.print("Decoded RC5: ");
  } 
  else if (results->decode_type == RC6) {
    Serial.print("Decoded RC6: ");
  }
  else if (results->decode_type == PANASONIC) {	
    Serial.print("Decoded PANASONIC - Address: ");
    Serial.print(results->panasonicAddress,HEX);
    Serial.print(" Value: ");
  }
  else if (results->decode_type == JVC) {
     Serial.print("Decoded JVC: ");
  }
  Serial.print(results->value, HEX);
  Serial.print(" (");
  Serial.print(results->bits, DEC);
  Serial.println(" bits)");
  /*
  Serial.print("Raw (");
  Serial.print(count, DEC);
  Serial.print("): ");

  for (int i = 0; i < count; i++) {
    if ((i % 2) == 1) {
      Serial.print(results->rawbuf[i]*USECPERTICK, DEC);
    } 
    else {
      Serial.print(-(int)results->rawbuf[i]*USECPERTICK, DEC);
    }
    Serial.print(" ");
  }
  */
  Serial.println("");
}

