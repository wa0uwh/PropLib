CON
' ======================================================================
'
'   File...... wa0uwh_OSC.spin
'   Purpose... To Control RF, SideTone Oscillators
'   Author.... Eldon Brown - WA0UWH
'   E-mail.... eldonb@ebcon.com
'   Started... 09 Feb 2012
'   Updated... 09 Feb 2019
'
'
' NOTE: NOT working in it own COG yet
'
' ======================================================================
{{

}}
    WMin = 381

    _CLKMODE = XTAL1 + PLL16X
    _XINFREQ = 5_000_000

    CLK_FREQ = ((_clkmode-xtal1)>>6)*_xinfreq
    MS_001 = CLK_FREQ / 1_000


     DemoRfFreq = 10140000
     DemoTone = 0
     DenoRfFreqCal = -380

     DemoRfPin = 27
     DemoAfPin = 20

     DemoLedPin = 8
     DemoRedLedPin = 9

    ' LCD Info
    #16, LCD_RS, LCD_RW, LCD_E, LCD_BL
    #12, LCD_DB4, LCD_DB5, LCD_DB6, LCD_DB7
    #16, LCD_COLS
    #2,  LCD_ROWS

DAT
    FuncName BYTE "OSC", 0

DAT
    ' Process Messages
    sInit   BYTE " Init:", 0
    sSync   BYTE " Sync:", 0
    sBeacon BYTE " Beacon:", 0
    sHz     BYTE "Hz", 0
    sDone   BYTE " Done", 0

OBJ
    Freq  : "Synth"

VAR
  Long cog, cogStack[16]

  Long RfPin
  Long AFPin
  Long LedPin
  Long LastFreq

OBJ
    KNB   : "wa0uwh_knobs"
    LCD   : "ko7mLCD"
PUB Demo | okay, RfFreq, RfFreqCal,Tone, E0, B0, E1, B1, Lcog


      'LCD.Startx(LCD_BL, LCD_E, LCD_RW, LCD_RS ,LCD_DB4, LCD_COLS, LCD_ROWS)
      LCD.begin(LCD#driverModeParallel, 16, 2)
      LCD.blon
      'LCD.cmd(LCD#CLS)
      LCD.clear
      LCD.str(@FuncName)
      LCD.moveto(2,2)
      LCD.str(@sInit)
      pauseSec(2)

      KNB.Start(@E0, @B0, @E1, @B1)

      RfFreq := DemoRfFreq
      Tone := DemoTone
      RfFreqCal := DenoRfFreqCal

      Lcog := Start(DemoRfPin, DemoAfPin, DemoLedPin)

      'A Freq test, not a normal Beacon Operation, set "IF" as necessary
       'LCD.cmd(LCD#CLS)
       LCD.clear
       LCD.str(string("Freq CAL: "))
       LCD.moveto(1,2)
       LCD.dec(RfFreq+Tone)
       LCD.str(@sHz)

       repeat     'Repeat Forever, this is a only a Calibration Test
         RfFreqCal += E1~
         LCD.moveto(13,1)
         LCD.rjdec(RfFreqCal, 4," ")
         sendTone(RfFreq, RfFreqCal, Tone)
         pauseSec(4)
         noTone
         pauseSec(1)

DAT
PUB Start(RfPinArg, AfPinArg, LedPinArg) | okay

    'Stop
    Init(RfPinArg, AfPinArg, LedPinArg)

    'okay := (cog := cognew(Start_, @cogStack) + 1)

PUB Start_
      repeat
        pauseSec(1)

PUB Stop
{{Stop; frees a cog.}}

  if cog
    cogstop(cog~ - 1)

DAT
Pri Init(RfPinArg, AfPinArg, LedPinArg)

      RfPin := RfPinArg
      AfPin := AfPinArg
      LedPin := LedPinArg

      dira[RfPin]~              'Set For Not Output
      dira[AfPin]~              'Set For Not Output
      dira[LEDPin]~             'Set For Not Output

DAT
PUB sendTone(RfFreq, RfFreqCal, Tone) | ThisFreq
    ThisFreq := RfFreq + Tone + RfFreqCal
    if ThisFreq <> LastFreq
      Freq.Synth("A",RfPin, ThisFreq)
      LastFreq := ThisFreq
    dira[RfPin]~~              'Set For Output

    'dira[AfPin]~~              'Set For Output
    'dira[LEDPin]~~             'Set For Output

PUB noTone
      dira[RfPin]~              'Set For Not Output

      'dira[AfPin]~              'Set For Not Output
      'dira[LEDPin]~             'Set For Not Output

PUB stopTone
      Freq.Synth("A",RfPin, 0)
      noTone

DAT

PRI pauseSec(sec)
      pause(1000 * sec)

PUB pause(ms)
      waitcnt(((clkfreq / 1_000 * ms - 3932) #> WMin) + cnt)

DAT
{{

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

}}
