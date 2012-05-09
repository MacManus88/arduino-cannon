/*
    Circus Cannon Nunchuck Control
    von Pascal König    
    http://pascals-koenigreich.de/canon.html
    
    mit Arduino 0023 und USB Host Shield v1 Library ausführen
    
    Code Teile von 
    http://www.circuitsathome.com/mcu/driving-the-cheeky-mail-notifier-from-arduino
    und
    http://todbot.com/blog/2008/02/18/wiichuck-wii-nunchuck-adapter-available/
*/
#include <SPI.h>
#include <Max3421e.h>
#include <Usb.h>

#include <Wire.h>
#include "nunchuck_funcs.h"

#define Canon_ADDR               1
#define Canon_EP                 1
#define Canon_IF                 0
#define EP_MAXPKTSIZE            8
#define EP_POLL               0x0a
 
EP_RECORD ep_record[ 1 ];
 
MAX3421E Max;
USB Usb;

byte joyx,joyy,zbut,cbut;
 
void setup() {
  Serial.begin( 9600 );
  Serial.println("Start");
  pinMode(18, OUTPUT);
  pinMode(19, OUTPUT);
  digitalWrite(18, LOW);
  digitalWrite(19, HIGH);
  Max.powerOn();
  nunchuck_setpowerpins();
  nunchuck_init(); // send the initilization handshake
  delay( 200 );
  Serial.println("Initialized");
}
 
void loop() {
  Max.Task();
  Usb.Task();
  if( Usb.getUsbTaskState() == USB_STATE_CONFIGURING ) {  //wait for addressing state
    Canon_init();
    Usb.setUsbTaskState( USB_STATE_RUNNING );
  }
  if( Usb.getUsbTaskState() == USB_STATE_RUNNING ) {  //poll the Mail Notifier 
    //Code
    nunchuck_get_data();
    
    joyx  = nunchuck_joyx();
    joyy  = nunchuck_joyy();
    zbut = nunchuck_zbutton();
    cbut = nunchuck_cbutton(); 
    
/*
down  0
up    1
left  2
right 3
fire  4
hold  5
*/
    
    if (joyy > 30 && joyy < 40)
      Canon_poll(0);
    else if (joyy > 215 && joyy < 230)
      Canon_poll(1);
    else if (joyx > 25 && joyx < 35)
      Canon_poll(2);
    else if (joyx > 215 && joyx < 230)
      Canon_poll(3);
    else if (zbut == 1)
      Canon_poll(4);
    else
      Canon_poll(5);
  }
}

void Canon_init( void )
{
  byte rcode = 0;  //return code
  ep_record[ 0 ] = *( Usb.getDevTableEntry( 0,0 ));  //copy endpoint 0 parameters
  ep_record[ 1 ].MaxPktSize = EP_MAXPKTSIZE;
  ep_record[ 1 ].Interval  = EP_POLL;
  ep_record[ 1 ].sndToggle = bmSNDTOG0;
  ep_record[ 1 ].rcvToggle = bmRCVTOG0;
  Usb.setDevTableEntry( 1, ep_record );              //plug Canon.endpoint parameters to devtable

  delay(2000);
  Serial.println("Cannon initialized");
}

void Canon_poll( int i )
{
  char down[] = { 0x01 };
  char up[] = { 0x02 };
  char left[]  = { 0x04 };
  char right[]  = { 0x08 };
  char fire[] = { 0x10 };
  char hold[] = { 0x20 };
  char rstatus[] = { 0x40 };  //request status
  
  byte rcode = 0;     //return code
  
  switch (i)
  {
    case 0:
      rcode = Usb.setReport( Canon_ADDR,0x00,0x08,Canon_IF,0x02,0x00, down );
      break;
    case 1:
      rcode = Usb.setReport( Canon_ADDR,0x00,0x08,Canon_IF,0x02,0x00, up );
      break;
    case 2:
      rcode = Usb.setReport( Canon_ADDR,0x00,0x08,Canon_IF,0x02,0x00, left );
      break;
    case 3:
      rcode = Usb.setReport( Canon_ADDR,0x00,0x08,Canon_IF,0x02,0x00, right );
      break;
    case 4:
      rcode = Usb.setReport( Canon_ADDR,0x00,0x08,Canon_IF,0x02,0x00, fire );
      break;
    case 5:
      rcode = Usb.setReport( Canon_ADDR,0x00,0x08,Canon_IF,0x02,0x00, hold );
      break;
  }
  Serial.println("send");
  delay(500);
}
