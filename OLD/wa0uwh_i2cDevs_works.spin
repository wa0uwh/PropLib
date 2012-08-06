CON
    WMin = 381

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
    SpeakerPin = 5
CON

  ' Expander I/O Pin Names for BankA
  #0, Encoder0PinA, Encoder0PinB, Encoder0ButPin, Push0ButPin
  #4, Encoder1PinA, Encoder1PinB, Encoder1ButPin, Push1ButPin

CON
        KNOB_ISR_PIN = 8 'Interrupt PIN on Prop

CON
    ' LED's Driven by Expander
    #0, RedR, BluR,   RedL, BluL, GrnR, YelR, GrnL, YelL
    RedS = 1<<RedL | 1<<RedR
    BluS = 1<<BluL | 1<<BluR
    GrnS = 1<<GrnL | 1<<GrnR
    YelS = 1<<YelL | 1<<YelR


CON
    ' Max of one RTC / I2C Bus
    DEF_RTCaddr = $68 << 1
    #0, cSS, cMM, cHH, cWW, cDD, cLL, cYY, A1M1  'LL = Lunar (or Month)

CON
    ' Max of one MCP4018 POT / I2C Bus
    DEF_PotMCP4018addr  = $2F << 1
    DEF_PotMCP4018value = $3F

CON
    'Max of four MCP4441 Quad POTs  / I2C Bus
    DEF_PotMCP4441addr0  = ($2C + 0) << 1
    DEF_PotMCP4441addr1  = ($2C + 1) << 1
    DEF_PotMCP4441addr3  = ($2C + 2) << 1
    DEF_PotMCP4441addr4  = ($2C + 3) << 1

    MCP4441_WIPER0    = $00 << 4
    MCP4441_WIPER1    = $01 << 4
    MCP4441_WIPER2    = $06 << 4
    MCP4441_WIPER3    = $07 << 4

    MCP4441_STATUS       = $50
    MCP4441_TCON0        = $40
    MCP4441_TCON1        = $A0



OBJ
      I2C : "jm_i2c"
      MCP : "wa0uwh_MCP4018"

VAR
     Long E0, B0, E1, B1, B2, B3

     Long RTC, EXP1, EXP2, EXP3
     Long QPot0

VAR  ' Locks
     Long BusLock, Exp2Lock

OBJ 'DEMO
DAT 'DEMO
'{' To Run Demo, Comment this line out with a single quote

OBJ 'DEMO, Needed for DEMO only
      DSPL  : "wa0uwh_DSPL"
      FREQ  : "Synth"

VAR 'DEMO, Needed for DEMO only
     Long K0, P0, K1, P1, P2, P3
     Long PotS, Pot0, Pot1, Pot2, Pot3
     Long Contrast, Backlight

PUB Demo | okay, i, C

      Start

      K0 := P0:= 0
      K1 := P1:= 0
      P2 := P3:= 0

      Contrast := 10 'Default Contrast
      Backlight := 92 '110 is High Backlight

      i := -1       'Loop Counter

      DSPL.StartVGA
      DSPL.lock
        DSPL.clear
        DSPL.blon
        DSPL.str(string("I2C Dev Demo:"))
      DSPL.unlock

        pauseSec(1)

      DSPL.lock
        DSPL.clear
        DSPL.str(string("Start KNOB COG: "))
        DSPL.dec(Exp2Lock)
      DSPL.unlock

      E0 := B0 := E1 := B1 := B2 := B3 := 0
      StartKnobs(@E0, @B0, @E1, @B1, @B2, @B3)

      pauseSec(1)

      if True
        pauseSec(1)
        DSPL.lock
          DSPL.moveto(1,1)
          DSPL.str(string("Time:            "))
        DSPL.unlock

      if False
        on2(RedL)
        on2(RedR)
        pauseSec(1)
        allLEDoff2


      SpeakerTone(1000)

      C := cnt
      repeat 'Repeat the Rest of the Method Once a Second
        'waitcnt(CLKFREQ + C) 'Once per Second
        C := cnt
        i++

        'Display The Time of Day
        ifnot i//10
           DSPL.lock
             DSPL.moveto(3,2)
             DSPL.rjdecSufx(getHour, 2,"0", string(":"))
             DSPL.rjdecSufx(getMin, 2,"0", string(":"))
             DSPL.rjdec(getSec, 2,"0")
           DSPL.unlock
        else

        'Udate the Knobs and Buttons Counters

        Contrast -= E0 * 2
        BackLight += E1

        K0 += E0~
        P0 += B0~

        K1 += E1~
        P1 += B1~

        P2 += B2~
        P3 += B3~

        if False
           setPotWiper(DEF_PotMCP4018addr, i//128)
        else


        ifnot i//10 - 5
           Contrast := Contrast #> 0 <# 48
           BackLight := BackLight #> 78 <# 110
           K0 := K0 #> 0 <# 128
           K1 := K1 #> 0 <# 128

           setContrast(Contrast)
           setBackLight(BackLight)
           setQPotWiper(QPot0, MCP4441_WIPER2, K0)
           setQPotWiper(QPot0, MCP4441_WIPER3, K1)

           Pot0 := getQPotWiper(QPot0, MCP4441_WIPER0)
           Pot1 := getQPotWiper(QPot0, MCP4441_WIPER1)
           Pot2 := getQPotWiper(QPot0, MCP4441_WIPER2)
           Pot3 := getQPotWiper(QPot0, MCP4441_WIPER3)
        else


        'DEBUG
        ifnot i//10 - 6
           'Display Knobs and Button Counters
            DSPL.lock
              DSPL.moveto(1,3)
              DSPL.rjdec(K1, 5," ")
              DSPL.rjdec(K0, 5," ")

              DSPL.moveto(1,4)
              DSPL.rjdec(P1, 5," ")
              DSPL.rjdec(P0, 5," ")

              DSPL.moveto(1,5)
              DSPL.rjdec(P3, 5," ")
              DSPL.rjdec(P2, 5," ")

              DSPL.moveto(1,7)
              DSPL.hex(Pot3, 4)
              DSPL.str(string(" "))
              DSPL.hex(Pot2, 4)
              DSPL.str(string(" "))
              DSPL.hex(Pot1, 4)
              DSPL.str(string(" "))
              DSPL.hex(Pot0, 4)

              DSPL.moveto(8,1)
              DSPL.rjdec(i//1000, 3,"0")
            DSPL.unlock
        else

        'Busy Task, Blink LED's
        case i//100 - 25
            05: winkon2(GrnL)
            10: winkon2(GrnR)

            15: winkon2(YelL)
            20: winkon2(YelR)

            25: winkon2(RedL)
            30: winkon2(RedR)

            35: winkon2(BluL)
            40: winkon2(BluR)
            45: winkon2(BluL)
            50: winkon2(BluR)
'}
DAT
VAR 'STARTS
PUB Start | okay

      StartLocks

      LockBus
        I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)
      unLockBus

      StartEXP
      StartRTC
      StartQPot
      MCP.Start

DAT
Pri StartLocks

      ' Initialize LOCKs
      if (BusLock := locknew) == -1
         return -1
      if (Exp2Lock := locknew) == -1
         return -1


PUB StartQPot

      QPot0 :=  DEF_PotMCP4441addr0
      'QPot1 :=  DEF_PotMCP4441addr1
      'QPot2 :=  DEF_PotMCP4441addr2
      'QPot3 :=  DEF_PotMCP4441addr3

      '$FB = All POT Ports On, Except Port A on POT 0 (contrast port)
      putbyte(QPOT0, MCP4441_TCON0, $FB)
      putbyte(QPOT0, MCP4441_TCON1, $FF)

      setQPotWiper(QPot0, MCP4441_WIPER0, 10) 'Set LCD Default Contrast
      setQPotWiper(QPot0, MCP4441_WIPER1, 64) 'Set LCD Default BackLight

PUB StartEXP

      EXP1 := DEF_EXP1addr
      EXP2 := DEF_Exp2addr
      EXP3 := DEF_Exp3addr

      LockExp2

        I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)

        putbyte(EXP1, IODIR, $00)    ' Set for Output
        putbyte(EXP1,  OLAT, $FF)    ' Clear Output Latch

        putbyte(EXP2, IOCON, $80)    ' Set for Bank1 Mode
        putbyte(EXP2, IOCONA,$80)    ' Set for Bank1 Mode
        putbyte(EXP2, IODIRA,$00)    ' Set for Output
        putbyte(EXP2, OLATA, $FF)    ' Clear Output Latch
        putbyte(EXP2, OLATB, $FF)    ' Clear Output Latch

        putbyte(EXP3, IOCON, $80)    ' Set for Bank1 Mode
        putbyte(EXP2, IOCONA,$80)    ' Set for Bank1 Mode

        putbyte(EXP3, IODIRA,$00)    ' Set for Output
        putbyte(EXP3, IODIRB,$FF)    ' Set for Input

        putbyte(EXP3, OLATA, $01)    ' Clear A Output Latch, Except BackLight

        putbyte(EXP3, OLATB, $00)    ' Clear B Output Latch


      unLockExp2


DAT
VAR 'START KNOBS
   Long cog, cogStack[128] 'Local Static Variables
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

    LockExp2
      putbyte(EXP2, IOCON,    $80)          'Set for Bank1 Mode, Active Low IntA
      putbyte(EXP2, IOCONA,   $80)          'Set for Bank1 Mode, Active Low IntA, if aready in Bank1 mode
      putbyte(EXP2, IODIRA,   $FF)          'Set ALL Pins for Input
      putbyte(EXP2, IPOLA,    $FF)          'Set Reverse Polarity of Inputs
      putbyte(EXP2, GPPUA,    $FF)          'Turn on 100K Pull Ups for ALL Pins
      putbyte(EXP2, GPINTENA, IntPinMask)   'Interrupt Condition = On Change for some Pins
      putbyte(EXP2, DEFVALA,  !IntPinMask)   'Sets None Interrupt State for some Pins
      putbyte(EXP2, INTCONA,  !IntPinMask)   'Enable Interrputs for some Pins
    unLockExp2

    okay := cog := (cognew(KnobButISR(pE0, pB0, pE1, pB1, pB2, pB3), @cogStack) +1)

    pauseSec(1)

    return cog

DAT
PUB StopKnobs
{{Stop; frees a cog.}}

  if cog
    cogstop(cog~ - 1)

DAT
VAR 'KNOB AND BUTTON ISR
PRI KnobButISR(pE0, pB0, pE1, pB1, pB2, pB3)| pins, mask, ISRv, ButtonMask, KnobMask, IntMask, tmp

    'Init
    'StartLoop
    'Poll For Button being Pressed
    'Else, Wait for Button or Rotory Knob Event
    'Decode Rotory Knobs and Buttons, update passed parameters as necessary
    'Loop

    'Note: Locks makes this Multi COG Friendly, User must insert Locks in their code


    'Init
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

    dira[pins]~    'Set for Input, and Float high via Extern Pullup 10K Resistors

    LockExp2
      getbyte(EXP2, GPIOA)  'Clear Erroneous Interrupts
    unLockExp2


    repeat 'StartLoop
        LockExp2 'Poll for Button Being Pressed
           ISRv := getbyte(EXP2, INTCAPA) & ButtonMask
        unLockExp2
        ifnot ISRv 'Wait for Button or Rotory Knob Event
           waitpne(mask, pins, 0) 'waiting for interrupt signal
           LockExp2
             ISRv := getbyte(EXP2, INTCAPA)  'Get Interrupt Values
           unLockExp2
        else

       'Decode Rotory Knobs and Buttons, update passed parameters as necessary
       ' Check for Encoder0 Turned
        if (ISRv & 1<<Encoder0PinA)
           if(ISRv & 1<<Encoder0PinB)
             Long[pE0]--
           else
             Long[pE0]++
        else

       ' Check for Encoder1 Turned
        if (ISRv & 1<<Encoder1PinA)
           if(ISRv & 1<<Encoder1PinB)
             Long[pE1]--
           else
             Long[pE1]++
        else

        ' Check For Buttons Presses
        if  (ISRv & ButtonMask)
            if (ISRv & 1<<Encoder0ButPin)
              Long[pB0]++
            if (ISRv & 1<<Encoder1ButPin)
              Long[pB1]++
            if (ISRv & 1<<Push0ButPin)
              Long[pB2]++
            if (ISRv & 1<<Push1ButPin)
              Long[pB3]++
            pause(100)
        else
    'Loop

VAR 'START RTC
PUB StartRTC 'Init for RTC
      LockBus
        I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)
      unLockBus
      RTC := DEF_RTCaddr
      return setInteruptOnSec

VAR 'LED CONTROL VIA PROP PINS
PUB on(ExpPin) ' LED Control
      return onmask(1<<ExpPin)

PUB off(ExpPin) ' LED Control
      return offmask(1<<ExpPin)

DAT
PUB onmask(mask) | Latched
      putbyte(EXP1, IODIR, 0)
      Latched := getbyte(EXP1, OLAT) & ! mask
      RESULT := putbyte(EXP1, OLAT, Latched)
      return

DAT
PUB offmask(mask) : stat | Latched
      Latched := getbyte(EXP1, OLAT) | mask
      RESULT := putbyte(EXP1, OLAT, Latched)
      return

DAT
PUB blinkon(pin, dur) ' LED Control
      on(pin)
      pause(dur)
      off(pin)

PUB blinkoff(pin, dur) ' LED Control
      off(pin)
      pause(dur)
      on(pin)

DAT
PUB winkon(pin) ' LED Control
      blinkon(pin, 30)

PUB winkoff(pin) ' LED Control
      blinkoff(pin, 30)

DAT
PUB allLEDon ' LED Control
      return onmask($FF)

PUB allLEDoff ' LED Control
      return offmask($FF)

VAR 'LED CONTROL VIA EXPANDER
PUB on2(ExpPin) ' LED Control via Dual I/O Expander
      return onmask2(1<<ExpPin)

PUB off2(ExpPin) ' LED Control via Dual I/O Expander
      return offmask2(1<<ExpPin)

DAT
PUB onmask2(mask) | Latched
      LockExp2
        putbyte(EXP2, IODIRB, 0)
        Latched := getbyte(EXP2, OLATB) & ! mask
        RESULT := putbyte(EXP2, OLATB, Latched)
      unLockExp2
      return

PUB offmask2(mask) : stat | Latched
      LockExp2
        Latched := getbyte(EXP2, OLATB) | mask
        RESULT := putbyte(EXP2, OLATB, Latched)
      unLockExp2
      return

DAT
PUB blinkon2(pin, dur) ' LED Control via Dual I/O Expander
      on2(pin)
      pause(dur)
      off2(pin)

PUB blinkoff2(pin, dur) ' LED Control via Dual I/O Expander
      off2(pin)
      pause(dur)
      on2(pin)

DAT
PUB winkon2(pin) ' LED Control via Dual I/O Expander
      blinkon2(pin, 30)

PUB winkoff2(pin)
      blinkoff2(pin, 30) ' LED Control via Dual I/O Expander

DAT
PUB allLEDon2 ' LED Control via Dual I/O Expander
      return onmask2($FF)

PUB allLEDoff2 ' LED Control via Dual I/O Expander
      return offmask2($FF)


VAR 'SPEAKER TONE CONTROL
    Long LastTone 'Local Static Variables
PUB SpeakerTone(Tone)
      if Tone <> LastTone
        Freq.Synth("B",SpeakerPin, Tone)
        LastTone := Tone
      dira[SpeakerPin]~~           'Set For Output

PUB noTone
      dira[SpeakerPin]~            'Set For No Output

PUB stopTone
      Freq.Synth("B",SpeakerPin, 0)
      noTone
DAT
PUB setSpeakerVolume(val)
      return setQPotWiper(QPot0, MCP4441_WIPER2, val)

VAR 'LCD CONTRAST AND BACKLIGHT
PUB setContrast(val)
      return setQPotWiper(QPot0, MCP4441_WIPER0, val)

PUB setBackLight(val)
      return setQPotWiper(QPot0, MCP4441_WIPER1, val)

VAR 'SET POT WIPERS
PUB setPotWiper(addr, value) 'POT Wiper Control
      LockBus
        MCP.putbyte(addr, value)
      unLockBus
      return getPotWiper(addr)

PUB getPotWiper(addr) 'POT Wiper Control
      LockBus
        RESULT := MCP.getbyte(addr)
      unLockBus
      return

DAT
PUB setQPotWiper(addr, reg, val) 'Quad POT Wiper Control
      return putbyte(addr, reg, val)

PUB getQPotWiper(addr, reg) 'Quad POT Wiper Control
      return getword(addr, reg | $0C) >> 8

VAR 'REALTIME CLOCK
PUB setSec(_arg) ' Real Time Clock (RTC) Control
      return putbyte(RTC, cSS, (_arg/10)<<4 + (_arg // 10))

PUB setMin(_arg) ' Real Time Clock (RTC) Control
      return putbyte(RTC, cMM, (_arg/10)<<4 + (_arg // 10))

PUB setHour(_arg) ' Real Time Clock (RTC) Control
      return putbyte(RTC, cHH, (_arg/10)<<4 + (_arg // 10))

PUB setDay(_arg) ' Real Time Clock (RTC) Control
      return putbyte(RTC, cDD, (_arg/10)<<4 + (_arg // 10))

PUB setMonth(_arg) ' Real Time Clock (RTC) Control
      return putbyte(RTC, cLL, (_arg/10)<<4 + (_arg // 10))

PUB setYear(_arg) ' Real Time Clock (RTC) Control
      return putbyte(RTC, cYY, (_arg/10)<<4 + (_arg // 10))
DAT
PUB setInteruptOnSec ' Real Time Clock (RTC) Control
      return putbyte(RTC, $0E, 0)

DAT
PUB getSec ' Real Time Clock (RTC) Query
      RESULT := getbyte(RTC, cSS)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

PUB getMin ' Real Time Clock (RTC) Query
      RESULT := getbyte(RTC, cMM)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

PUB getHour ' Real Time Clock (RTC) Query
      RESULT := getbyte(RTC, cHH)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

PUB getDay ' Real Time Clock (RTC) Query
      RESULT := getbyte(RTC, cDD)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

PUB getMonth ' Real Time Clock (RTC) Query
      RESULT := getbyte(RTC, cLL)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

PUB getYear ' Real Time Clock (RTC) Query
      RESULT := getbyte(RTC, cYY)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

VAR 'LOW LEVEL I2C TRANSFERS
Pri getbyte(adr, reg) 'Low Level I2C Data Transfer
    LockBus
      RESULT := I2C.getbyte(adr, reg)
    unLockBus
    return

DAT
Pri putbyte(adr, reg, val) 'Low Level I2C Data Transfer
    LockBus
      RESULT := I2C.putbyte(adr, reg, val)
    unLockBus
    return

DAT
Pri getword(adr, reg) 'Low Level I2C Data Transfer
    LockBus
      RESULT := I2C.getword(adr, reg)
    unLockBus
    return

DAT
Pri putword(adr, reg, val) 'Low Level I2C Data Transfer
    LockBus
      RESULT := I2C.putword(adr, reg, val)
    unLockBus
    return


VAR 'LOCKS
PUB Lock   'Shorthand for LockBus
    LockBus
PUB unLock 'Shorthand for unLockBus
    return unLockBus

DAT
PUB LockBus 'Lock for I2C Bus
    _Lock(BusLock)
PUB unLockBus
    return _unLock(BusLock)

DAT
PUB LockExp2 'Lock for I2C Dual I/O Expander
    _Lock( Exp2Lock)
PUB unLockExp2
    return _unLock(Exp2Lock)

DAT
Pri _Lock(id) 'Lock Support
    repeat until not lockset(id)
Pri _unLock(id)
    return lockclr(id)

VAR 'PAUSE
PRI pauseSec(sec)
      pause(1000 * sec)

PUB pause(ms)
      waitcnt(((clkfreq / 1_000 * ms - 3932) #> WMin) + cnt)

VAR 'END
