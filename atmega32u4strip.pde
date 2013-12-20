/*
 atmega32u4strip
 
 Have some fun with an Adafruit Atmega32u4 breakout board and NeoPixel LED strip.

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

int RECV_PIN = CORE_OC1B_PIN;

IRrecv irrecv(RECV_PIN);
decode_results results;


// NeoPixel settings and variables

#define STRIP_PIN  CORE_OC1A_PIN  // NeoPixel LED strand is connected to this pin

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

#define MIC_PIN    11  // Microphone is attached to this analog pin ADC11 / B4
#define DC_OFFSET  0  // DC offset in mic signal - if unusure, leave 0
#define NOISE    100  // Noise/hum/interference in mic signal
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
  MODE_MAX
} MODE;


int mode = MODE_WIPE_RED;
byte reverse = 0;
byte dotRunMillis = 20;




void setup()
{
  Serial.begin(9600);
  irrecv.enableIRIn(); // Start the receiver
  
  strip.begin();
  strip.setBrightness(30);
  strip.show(); // Initialize all pixels to 'off'
 
  // clear vumeter
  memset(vol, 0, sizeof(vol)); 
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


void loop() {
  if (irrecv.decode(&results)) {
    if (results.bits) {
      Serial.println(results.value, HEX);
//      dump(&results);
    }
    irrecv.resume(); // Receive the next value
  }
}
