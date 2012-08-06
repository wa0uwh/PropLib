CON

CON

    _CLKMODE = XTAL1 + PLL16X
    _XINFREQ = 5_000_000

    CLK_FREQ = ((_clkmode-xtal1)>>6)*_xinfreq
    MS_001 = CLK_FREQ / 1_000


CON
    'Single 8 Bint Expander, Max one / I2C Circuit
    DEF_EXP1addr  = $20 <<1 ' I2C Expander # 1

    IODIR     = $00     ' 1=Input, 0=Output
    GPIO      = $09     ' General I/O registor
    OLAT      = $0A     ' Latched I/O registor

CON
    'Dual 8 bit Expanders, Max Four / I2C Circuit
    DEF_EXP2addr  = $20 <<1 ' I2C Expander # 2
    DEF_EXP3addr  = $21 <<1 ' I2C Expander # 3
    DEF_EXP4addr  = $22 <<1 ' I2C Expander # 4
    DEF_EXP5addr  = $23 <<1 ' I2C Expander # 5

    ' Defined for Bank0
    IOCON      = $0B     ' A None Address if in Bank1 mode

    ' Defined for Bank1 A
    IODIRA     = $00     ' 1=Input, 0=Output
    IPOLA      = $01     ' Input Polarity
    GPINTENA   = $02     ' GP Interrupt Enable
    DEFVALA    = $03     ' Holds DEF Inter Value
    INTCONA    = $04     ' Interrupt Control
    IOCONA     = $05     ' Bank CTL in bank1 mode
    GPPUA      = $06     ' Pull Ups
    INTFA      = $07     ' Interrupt Flag
    INTCAPA    = $08     ' Inter Event Save
    GPIOA      = $09     ' General I/O registor
    OLATA      = $0A     ' Latched I/O registor

    ' Defined for Bank1 B
    IODIRB     = $10     ' 1=Input, 0=Output
    IPOLB      = $11     ' Input Polarity
    GPINTENB   = $12     ' GP Interrupt Enable
    DEFVALB    = $13     ' Holds DEF Inter Value
    INTCONB    = $14     ' Interrupt Contro
    IOCONB     = $15     ' Bank CTL in bank1 mode
    GPPUB      = $16     ' Pull Ups
    INTFB      = $17     ' Interrupt Flag
    INTCAPB    = $18     ' Inter Event Save
    GPIOB      = $19     ' General I/O registor
    OLATB      = $1A     ' Latched I/O registorl



    BANKA      = $00
    BANKB      = $80

CON

  ' Expander I/O Pin Names for BankA
  #0, Encoder0PinA, Encoder0PinB, Encoder0ButPin, Push0ButPin
  #4, Encoder1PinA, Encoder1PinB, Encoder1ButPin, Push1ButPin

CON
        KNOB_ISR_PIN = 8 'Interrupt PIN on Prop

CON
    ' LED's Driven by Expander
    #0, RedR, BluR,   RedL, BluL
    RedS = 1<<RedL | 1<<RedR
    BluS = 1<<BluL | 1<<BluR


CON
    ' Max one / I2C Circuit
    DEF_RTCaddr = $68 << 1
    #0, cSS, cMM, cHH, cWW, cDD, cLL, cYY, A1M1  'LL = Lunar (or Month)

CON
    ' Max one / I2C Circuit
    DEF_PotMCP4018addr  = $2F << 1
    DEF_PotMCP4018value = $3F

OBJ
        I2C : "jm_i2c"

PUB Demo | okay, stat, L

      Start

      DemoLCD

      repeat
          repeat L from 0 to 3
              repeat 10
                 stat := on(L)
                 pause(50)
                 'stat := off(L)
                 pause(50)

          pauseSec(2)

OBJ

      'LCD  : "jm_lcd4_ez"  ' Rev 1.4
      LCD  : "wa0uwh_DSPL"
      MCP  : "wa0uwh_MCP4018"

CON
    ' LCD Info
    #16, LCD_RS, LCD_RW, LCD_E, LCD_BL
    #12, LCD_DB4, LCD_DB5, LCD_DB6, LCD_DB7
    #16, LCD_COLS
    #2,  LCD_ROWS

VAR
     LONG RTC, EXP1, EXP2, EXP3
     LONG E0, B0, E1, B1, B2, B3

VAR  ' Locks
     Long Junk, BusLock, Exp2Lock, LCDLock, TaskLock
     Long K0, K1, P0, P1, P2, P3

PUB DemoLCD | okay, C

      K0 := K1:= 0
      P0 := P1:= 0
      P2 := P3:= 0

      'LCD.Startx(LCD_BL, LCD_E, LCD_RW, LCD_RS ,LCD_DB4, LCD_COLS, LCD_ROWS)
      LCD.StartVGA
      LCD.lock
        LCD.clear
        LCD.blon
        LCD.str(string("I2C Dev Demo:"))
      LCD.unlock

        pauseSec(3)

      LCD.lock
        LCD.clear
        LCD.str(string("Starting Knobs: "))
        LCD.dec(Exp2Lock)
      LCD.unlock

      StartKnobs(@E0, @B0, @E1, @B1, @B2, @B3)

      pauseSec(1)

      if True
        pauseSec(1)
        LCD.lock
          LCD.moveto(1,1)
          LCD.str(string("Time:            "))
        LCD.unlock

      if False
        on2(RedL)
        on2(RedR)
        pauseSec(1)
        allLEDoff2

      C := cnt

      repeat 'Repeat the Rest of the Method Once a Second
        waitcnt(CLKFREQ + C)
        C := cnt

        'Display The Time of Day
        if True
           LCD.lock
             LCD.moveto(3,2)
             LCD.rjdecSufx(getHour, 2,"0", string(":"))
             LCD.rjdecSufx(getMin, 2,"0", string(":"))
             LCD.rjdec(getSec, 2,"0")
           LCD.unlock

        'Udate the Knobs and Buttons Counters
        K0 += E0~
        K1 += E1~
        P0 += B0~
        P1 += B1~
        P2 += B2~
        P3 += B3~

        'DEBUG
        if False
           'Display Knobs and Button Counters
           LCD.lock
            LCD.moveto(3,3)
            LCD.rjdec(K1, 5," ")
            LCD.rjdec(K0, 5," ")

            LCD.moveto(3,4)
            LCD.rjdec(P1, 5," ")
            LCD.rjdec(P0, 5," ")

            LCD.moveto(3,5)
            LCD.rjdec(P3, 5," ")
            LCD.rjdec(P2, 5," ")
           LCD.unlock

        'Busy Task, Blink LED's
        if True
            pause(100)
            winkon2(RedL)
            pause(100)
            winkon2(RedR)

            pause(100)
            winkon2(BluL)
            pause(100)
            winkon2(BluR)

        pause(100)  'Default Task


DAT
PUB Start | okay

     InitLocks

      lock(BusLock)
        I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)
      unlock(BusLock)

      StartEXP

      StartRTC

      MCP.Start

DAT
Pri InitLocks

      ' Initialize LOCKs
      if (Junk := locknew) == -1
         return -1
      if (BusLock := locknew) == -1
         return -1
      if (Exp2Lock := locknew) == -1
         return -1
      if (TaskLock := locknew) == -1
         return -1

PUB StartEXP

      EXP1 := DEF_EXP1addr
      EXP2 := DEF_Exp2addr
      EXP3 := DEF_Exp3addr

      lock(Exp2Lock)

        I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)

        putbyte(EXP1, IODIR, $00)
        putbyte(EXP1,  OLAT, $FF)

        putbyte(EXP2, IOCON, $80)    ' Set for Bank1 Mode
        putbyte(EXP2, IOCONB,$80)    ' Set for Bank1 Mode
        putbyte(EXP2, OLATB, $FF)    ' Clear Output Latch
        putbyte(EXP2, IODIRB,$00)    ' Set for Output

        putbyte(EXP3, IOCON, $80)    ' Set for Bank1 Mode
        putbyte(EXP3, OLATB, $FF)    ' Clear Output Latch
        putbyte(EXP3, IODIRB,$00)    ' Set for Output

      unlock(Exp2Lock)


DAT

VAR
   Long cog, cogStack[256]

PUB StartKnobs(pE0, pB0, pE1, pB1, pB2, pB3) | okay, IntPinMask
' The Arguments are pointers (p) to variable (counter) within the calling APP
' A typical APP will, check Counter for non Zero, take the value, and then reset Counter to Zero
' See usage in the above Demo Method

    stopKnobs

    IntPinMask := 0
    IntPinMask |= 1<<Encoder0PinA
    IntPinMask |= 1<<Encoder1PinA
    IntPinMask |= 1<<Encoder0ButPin
    IntPinMask |= 1<<Encoder1ButPin
    IntPinMask |= 1<<Push0ButPin
    IntPinMask |= 1<<Push1ButPin

    lock(Exp2Lock)
      putbyte(EXP2, IOCON,    $80)          ' Set for Bank1 Mode, Active Low IntA
      putbyte(EXP2, IOCONA,   $80)          ' Set for Bank1 Mode, Active Low IntA, if aready in Bank1 mode
      putbyte(EXP2, IODIRA,   $FF)          ' Set ALL Pins for Input
      putbyte(EXP2, IPOLA,    $FF)
      putbyte(EXP2, GPPUA,    $FF)          ' Turn on 100K Pull Ups for ALL Pins
      putbyte(EXP2, GPINTENA, IntPinMask)   ' Interrupt Condition = On Change for some Pins
      putbyte(EXP2, DEFVALA,  IntPinMask)   ' Sets None Interrupt State for some Pins
      'putbyte(EXP2, INTCONA,  IntPinMask)   ' Enable Interrputs for some Pins
      putbyte(EXP2, INTCONA,  0)   ' Enable Interrputs for some Pins
    unlock(Exp2Lock)

    'DEBUG
    if False
       LCD.lock
         LCD.moveto(1,7)
         LCD.bin(IntPinMask,8)
         LCD.str(string(" Expdr IntPinMask"))
       LCD.unlock


    okay := cog := (cognew(KnobButISR(pE0, pB0, pE1, pB1, pB2, pB3), @cogStack) +1)

    pauseSec(1)

    return cog

DAT
PUB StopKnobs
{{Stop; frees a cog.}}

  if cog
    cogstop(cog~ - 1)

DAT
PRI KnobButISR(pE0, pB0, pE1, pB1, pB2, pB3)|a,b,c,d,e,f, i,j,w, L,tmp, pins, mask, ISRv, ButtonMask, KnobMask, IntMask

    ' ############## THIS IS NOT WORKING YET ########################
    ' RotaryEncoder Knobs
    ' Pin Direction defaults to IN
    i:= j:= w := 0
    a := b := c := d := e := f := 0

    pins := 1<<KNOB_ISR_PIN
    mask := pins

    KnobMask := 0
    KnobMask |= 1<<Encoder0PinA
    KnobMask |= 1<<Encoder1PinA

    ButtonMask := 0
    ButtonMask |= 1<<Encoder0ButPin
    ButtonMask |= 1<<Encoder1ButPin
    ButtonMask |= 1<<Push0ButPin
    ButtonMask |= 1<<Push1ButPin

    IntMask := KnobMask | ButtonMask

    dira[pins]~                   ' Set for Input, and Float high via Pullup 10K Resistors


    'DEBUG
    if False
       LCD.lock
         L := 12
         LCD.moveto(1,L++)
        'DEBUG
        if True
           LCD.bin(ButtonMask,8)
           LCD.str(string(" ButtonMask"))
        'DEBUG
        if True
           LCD.moveto(1,L++)
           LCD.Bin(pins,16)
           LCD.str(string(" Prop Int Pin"))
        'DEBUG
        if True
           LCD.moveto(1,L++)
           LCD.Bin(mask,16)
           LCD.str(string(" Prop Int Mask"))
       LCD.unlock

    lock(Exp2Lock)
      ISRv := getbyte(EXP2, INTCAPA)  'Get Interrupts
    unlock(Exp2Lock)


    repeat
      i++

      'DEBUG
      if True
        LCD.lock
          L := 3
          LCD.moveto(1,L++)
          LCD.rjdec(b//1000, 5," ")
          LCD.rjdec(a//100, 5," ")
          LCD.rjdec(Long[pE1]//1900, 5," ")
          LCD.rjdec(long[pE0]//1000, 5," ")

          LCD.moveto(1,L++)
          LCD.rjdec(d//1000, 5," ")
          LCD.rjdec(c//1000, 5," ")
          LCD.rjdec(Long[pB1]//1000, 5," ")
          LCD.rjdec(Long[pB0]//1000, 5," ")

          LCD.moveto(1,L++)
          LCD.rjdec(f//1000, 5," ")
          LCD.rjdec(e//1000, 5," ")
          LCD.rjdec(Long[pB3]//1000, 5," ")
          LCD.rjdec(Long[pB2]//1000, 5," ")
        LCD.unlock

       'DEBUG
        if False
          lock(Exp2Lock)
             tmp := getbyte(EXP2, GPINTENA)
          unlock(Exp2Lock)
          LCD.lock
          LCD.moveto(1,L++)
            if True
              LCD.str(string("ISRv "))
              LCD.bin(ISRv,8)
            if True
                LCD.moveto(1,L++)
                LCD.str(string("GPINTENA "))
                LCD.bin(tmp,8)
            LCD.rjdec(i//100 , 3, " ")
          LCD.unlock



       j := 0
       lock(Exp2Lock)
         ISRv := getbyte(EXP2, INTCAPA)
       unlock(Exp2Lock)

       ' ISRv := 1<<Encoder0PinA | 1<<Encoder0PinB

       'DEBUG
        if False
          LCD.lock
            'DEBUG
            if True
              LCD.moveto(1,L++)
              LCD.str(string("ISRvv "))
              LCD.bin(ISRv,8)
            if True
              LCD.moveto(1,L++)
              LCD.str(string("ina[] "))
              LCD.hex(ina,4)
            LCD.rjdec(i//100 , 3, " ")
          LCD.unlock

        ifnot ISRv
           w++
           'DEBUG
           if True
              LCD.lock
                'DEBUG
                if True
                    LCD.moveto(20,1)
                    LCD.str(string("wpeq "))
                    LCD.hex(ina[pins],4)
                    LCD.rjdec(w//100 , 3, " ")
               LCD.unlock

           lock(Exp2Lock)
             ISRv := getbyte(EXP2, INTCAPA)
           unlock(Exp2Lock)
           waitpeq(mask, pins, 0) ' waiting for all to be High

           'DEBUG
           if True
              LCD.lock
                LCD.moveto(20,2)
                LCD.str(string("wpne "))
                LCD.rjdec(w//100 , 3, " ")
              LCD.unlock

           waitpne(mask, pins, 0) ' waiting for something to go low
           lock(Exp2Lock)
             ISRv := getbyte(EXP2, INTCAPA) & IntMask  'Get Interrupts
           unlock(Exp2Lock)
        {END ifnot}

        ' Now Check for Knob Turned
        'DEBUG       'DEBUG
        if True
          LCD.lock
            'DEBUG       'DEBUG
            if True
               LCD.moveto(1,L++)
               LCD.bin(ISRv,8)
               LCD.str(string(" In GB "))
            'DEBUG       'DEBUG
            if True
               LCD.moveto(1,L++)
               LCD.bin(ISRv,8)
               LCD.str(string(" ISRv "))
            LCD.rjdec(i//100 , 3, " ")
          LCD.unlock


       ' Check for Encoder0 Turned
        if (ISRv & 1<<Encoder0PinA)
           if(ISRv & 1<<Encoder0PinB)
             Long[pE0]--
             a++
           else
             Long[pE0]++
             a--

       ' Check for Encoder1 Turned
        if (ISRv & 1<<Encoder1PinA)
           if(ISRv & 1<<Encoder1PinB)
             Long[pE1]++
             b++
           else
             Long[pE1]--
             b--

        repeat while (ISRv & ButtonMask)
            if (ISRv & 1<<Encoder0ButPin)
              Long[pB0]++
              c++
            if (ISRv & 1<<Encoder1ButPin)
              Long[pB1]++
              d++
            if (ISRv & 1<<Push0ButPin)
              Long[pB2]++
              e++
            if (ISRv & 1<<Push1ButPin)
              Long[pB3]++
              f++
            ISRv := 0
            pause(200)
            lock(Exp2Lock)
              getbyte(EXP2, GPIOA)
              ISRv := getbyte(EXP2, INTCAPA) & ButtonMask  'Get Interrupts
            unlock(Exp2Lock)

DAT
PUB StartRTC

      lock(BusLock)
        I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)
      unlock(BusLock)

      RTC := DEF_RTCaddr
      return setInteruptOnSec

DAT
OBJ
PUB on(ExpPin) ' LED Control
    return onmask(1<<ExpPin)

PUB onmask(mask) | Latched
    lock(BusLock)
      putbyte(EXP1, IODIR, 0)
      Latched := I2C.getbyte(EXP1, OLAT) & ! mask
      RESULT := I2C.putbyte(EXP1, OLAT, Latched)
    unlock(BusLock)
    return

DAT
PUB off(ExpPin) ' LED Control
    return offmask(1<<ExpPin)

PUB offmask(mask) : stat | Latched
    lock(BusLock)
      Latched := I2C.getbyte(EXP1, OLAT) | mask
      RESULT := I2C.putbyte(EXP1, OLAT, Latched)
    unlock(BusLock)
    return

DAT
PUB blinkon(pin, dur)
     on(pin)
     pause(dur)
     off(pin)

PUB blinkoff(pin, dur)
     off(pin)
     pause(dur)
     on(pin)

DAT
PUB winkon(pin)
     blinkon(pin, 30)

PUB winkoff(pin)
     blinkoff(pin, 30)

DAT
PUB allLEDon
    return onmask($FF)

PUB allLEDoff
    return offmask($FF)

DAT
PUB on2(ExpPin)
    return onmask2(1<<ExpPin)

PUB onmask2(mask) | Latched
    lock(Exp2Lock)
      lock(BusLock)
        I2C.putbyte(EXP2, IODIRB, 0)
        Latched := I2C.getbyte(EXP2, OLATB) & ! mask
        RESULT := I2C.putbyte(EXP2, OLATB, Latched)
      unlock(BusLock)
    unlock(Exp2Lock)
    return

DAT
PUB off2(ExpPin)
    return offmask2(1<<ExpPin)

PUB offmask2(mask) : stat | Latched
    lock(Exp2Lock)
      lock(BusLock)
        Latched := I2C.getbyte(EXP2, OLATB) | mask
        RESULT := I2C.putbyte(EXP2, OLATB, Latched)
      unlock(BusLock)
    unlock(Exp2Lock)
    return

DAT
PUB blinkon2(pin, dur)
     on2(pin)
     pause(dur)
     off2(pin)

PUB blinkoff2(pin, dur)
     off2(pin)
     pause(dur)
     on2(pin)

DAT
PUB winkon2(pin)
     blinkon2(pin, 30)

PUB winkoff2(pin)
     blinkoff2(pin, 30)

DAT
PUB allLEDon2
    return onmask2($FF)

PUB allLEDoff2
    return offmask2($FF)

OBJ
PUB setPotWiper(addr, value)
    lock(BusLock)
      MCP.putbyte(addr, value)
    unlock(BusLock)
    return getPotWiper(addr)

PUB getPotWiper(addr)
    lock(BusLock)
      RESULT := MCP.getbyte(addr)
    unlock(BusLock)
    return

OBJ
PUB setSec(_arg)
      return putbyte(RTC, cSS, (_arg/10)<<4 + (_arg // 10))

PUB setMin(_arg)
      return putbyte(RTC, cMM, (_arg/10)<<4 + (_arg // 10))

PUB setHour(_arg)
      return putbyte(RTC, cHH, (_arg/10)<<4 + (_arg // 10))

PUB setDay(_arg)
      return putbyte(RTC, cDD, (_arg/10)<<4 + (_arg // 10))

PUB setMonth(_arg)
      return putbyte(RTC, cLL, (_arg/10)<<4 + (_arg // 10))

PUB setYear(_arg)
      return putbyte(RTC, cYY, (_arg/10)<<4 + (_arg // 10))

DAT
PUB getSec
      RESULT := getbyte(RTC, cSS)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

PUB getMin
      RESULT := getbyte(RTC, cMM)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

PUB getHour
      RESULT := getbyte(RTC, cHH)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

PUB getDay
      RESULT := getbyte(RTC, cDD)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

PUB getMonth
      RESULT := getbyte(RTC, cLL)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

PUB getYear
      RESULT := getbyte(RTC, cYY)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

DAT
Pri getbyte(adr, reg)
    lock(BusLock)
      RESULT := I2C.getbyte(adr, reg)
    unlock(BusLock)
    return

DAT
Pri putbyte(adr, reg, val)
    lock(BusLock)
      RESULT := I2C.putbyte(adr, reg, val)
    unlock(BusLock)
    return

DAT
PUB setInteruptOnSec
      return putbyte(RTC, $0E, 0)

PUB setInteruptOnKnob  'Not working yet.
      'putbyte(KNOBS,$0E, 0)

DAT
Pri Lock(id)
    repeat until not lockset(id)

Pri unLock(id)
    return lockclr(id)

DAT
OBJ
PRI pauseSec(sec)
    pause(1000 * sec)

PRI pause(ms)  | t
    t := cnt - 1088             ' 1088 is Published Time for Overhead at 80mHz
    repeat ms
       waitcnt(t += MS_001)

DAT
