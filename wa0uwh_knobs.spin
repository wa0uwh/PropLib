CON
' ======================================================================
'
'   File...... wa0uwh_knobs.spin   REV 1.2
'   Purpose... Decode Rotary Encoders
'   Author.... Eldon Brown - WA0UWH
'   E-mail.... eldonb@ebcon.com
'   Started... 09 Feb 2012
'   Updated... 28 Feb 2012
'
' ======================================================================

CON

    _CLKMODE = XTAL1 + PLL16X
    _XINFREQ = 5_000_000

    WMin     = 381       ' WAITCNT-expression-overhead Minimum

    CLK_FREQ = ((_clkmode-xtal1)>>6)*_xinfreq
    MS_001 = CLK_FREQ / 1_000


    ' Enumerated Pin Numbers on Propeller
    #21, Encoder0But, Encoder0PinA, Encoder0PinB
         Encoder1But, Encoder1PinA, Encoder1PinB

    ' LCD Info
    #16, LCD_RS, LCD_RW, LCD_E, LCD_BL
    #12, LCD_DB4, LCD_DB5, LCD_DB6, LCD_DB7
    #16, LCD_COLS
    #2,  LCD_ROWS


VAR
      Long cog
      Long cogStack[64]

OBJ

      LCD : "jm_lcd4_ez"  ' Rev 1.4


DAT
PUB Demo | okay, LoopCnt, ChildCogID, E0, B0, E1, B1, B0prev, B1prev

      ' Initize Encoder Counters
      E0 := E1 := 0
      ' Initize Button Counters
      B0 := B1 := 0

      ' Initize Loop Counter
      LoopCnt := 0

      ChildCogID := Start(@E0, @B0, @E1, @B1)

      LCD.Startx(LCD_BL, LCD_E, LCD_RW, LCD_RS ,LCD_DB4, LCD_COLS, LCD_ROWS)
      LCD.cmd(LCD#CLS)
      LCD.blon
      LCD.str(string("Init:"))
      LCD.moveto(1,2)
      LCD.str(string("COGs = "))
      LCD.dec(cogid)
      LCD.str(string(","))
      LCD.dec(ChildCogID)

      pauseSec(4)
      LCD.cmd(LCD#CLS)
      LCD.str(string("Encoder Demo"))

      repeat

        ' A trick to reset Buttons that can be used in an App: Hold both down
        if B0 > B0prev AND B1 > B1prev
          B0 := B1 := 0
        B0prev := B0
        B1prev := B1

        ' Report the Counts

        LCD.moveto(14,1)
        LCD.rjdec(LoopCnt++ // 1000, 3, "0")

        LCD.moveto(1,2)
        LCD.rjdec(E0,4," ")

        LCD.moveto(5,2)
        LCD.rjdec(B0,4," ")

        LCD.moveto(9,2)
        LCD.rjdec(B1,4," ")

        LCD.moveto(13,2)
        LCD.rjdec(E1,4," ")


DAT
PUB Start(pcntEnc0, pbut0, pcntEnc1, pbut1) | okay
' The Arguments are pointers (p) to variable (counter) within the calling APP
' A typical APP will, check Counter for non Zero, take the value, and then reset Counter to Zero
' See usage in the above Demo Method

    stop

    okay := cog := (cognew(RotaryEncoder(pcntEnc0, pbut0, pcntEnc1, pbut1), @cogStack) +1)

    return cog

DAT
PUB Stop
{{Stop; frees a cog.}}

  if cog
    cogstop(cog~ - 1)

DAT
PRI RotaryEncoder(pCntE0, pE0But, pCntE1, pE1But)| pins, mask

  ' RotaryEncoder Knobs
  ' Pin Direction defaults to IN

  pins := 0
  pins |= 1<<Encoder0PinA | 1<<Encoder0But
  pins |= 1<<Encoder1PinA | 1<<Encoder1But

  mask := pins

  dira[pins]~                   ' Set for Input, and Float high via Pullup 10K Resistors

  repeat
    waitpeq(mask, pins, 0) ' waiting for all to be high
    waitpne(mask, pins, 0) ' waiting for something to go low

    ' Now Check to see which is low

    if NOT ina[Encoder0PinA]
      if ina[Encoder0PinB]
        Long[pCntE0]++
      else
        Long[pCntE0]--

    if  NOT ina[Encoder1PinA]
      if ina[Encoder1PinB]
        Long[pCntE1]--
      else
        Long[pCntE1]++

    ' Check for a Button Pushed
    repeat while NOT ina[Encoder0But] OR NOT ina[Encoder1But]
      if NOT ina[Encoder0But]
        Long[pE0But]++
      if NOT ina[Encoder1But]
        Long[pE1But]++
      pauseMS(200)

DAT
PRI pauseSec(Duration)
      pauseMS(1000*Duration)

PRI pauseMS(Duration)
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> WMin) + cnt)

PRI pauseUS(Duration)
  waitcnt(((clkfreq / 1_000_000 * Duration - 3932) #> WMin) + cnt)

DAT
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
