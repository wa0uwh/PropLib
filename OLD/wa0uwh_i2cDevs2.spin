CON
{{
     WA0UWH UI Support Object
}}
CON
    WMin = 381

    CLKSRC = 1 *2    'Comment out the "*2" for 5MHz Cystal, UnComment for 10MHz TCVCXO
    _CLKMODE = XTAL1 * CLKSRC * CLKSRC + PLL16X / CLKSRC
    _XINFREQ = 5_000_000 * CLKSRC


CON 'Address for MCP23017 Dual 8bit and MCP23008 Single 8 Bit Expanders
    'Max Eight / I2C Circuit

    DEF_ExpAddr0  = ($20 +0) <<1
    DEF_ExpAddr1  = ($20 +1) <<1
    DEF_ExpAddr2  = ($20 +2) <<1
    DEF_ExpAddr3  = ($20 +3) <<1
    'etc

CON 'MCP23008 Expander Registors

    IODIR     = $00     ' 1=Input, 0=Output
    GPIO      = $09     ' General I/O registor
    OLAT      = $0A     ' Latched I/O registor

CON 'MCP23017 Expander Registors

    'Defined for Bank0
    IOCON      = $0B     ' A None Address if in Bank1 mode

    'Defined for Bank1 A
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

    'Defined for Bank1 B
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
    'Expander I/O Pin Names for BankA
    #0, Encoder0PinA, Encoder0PinB, Encoder0ButPin, Push0ButPin
    #4, Encoder1PinA, Encoder1PinB, Encoder1ButPin, Push1ButPin

CON
    KNOB_ISR_PIN = 8 'Interrupt PIN on Prop

CON
    'LED's Driven by Expander
    #0, RedR, BluR,   RedL, BluL, GrnR, YelR, GrnL, YelL
    RedS = 1<<RedL | 1<<RedR
    BluS = 1<<BluL | 1<<BluR
    GrnS = 1<<GrnL | 1<<GrnR
    YelS = 1<<YelL | 1<<YelR

CON
    SpeakerPin = 5

CON
    'Max of one RTC / I2C Bus
    DEF_RTCaddr = $68 << 1
    #0, cSS, cMM, cHH, cWW, cDD, cLL, cYY, A1M1  'LL = Lunar (or Month)

CON
    ' Max of one MCP4018 POT / I2C Bus
    DEF_PotMCP4018Addr  = $2F << 1
    DEF_PotMCP4018value = $3F

CON
    'Max of four MCP4441 Quad POTs  / I2C Bus
    DEF_PotMCP4441Addr0  = ($2C + 0) << 1
    DEF_PotMCP4441Addr1  = ($2C + 1) << 1
    DEF_PotMCP4441Addr3  = ($2C + 2) << 1
    DEF_PotMCP4441Addr4  = ($2C + 3) << 1

    MCP4441_WIPER0    = $00 << 4
    MCP4441_WIPER1    = $01 << 4
    MCP4441_WIPER2    = $06 << 4
    MCP4441_WIPER3    = $07 << 4

    MCP4441_STATUS    = $50
    MCP4441_TCON0     = $40
    MCP4441_TCON1     = $A0

OBJ
      I2C     : "jm_i2c"
      MCP4018 : "wa0uwh_MCP4018"

VAR
     Long E0, B0, E1, B1, B2, B3

     Long RTC, EXP1, EXP2, EXP3
     Long QPot0


DAT 'DEMO
'{' To Run Demo, Comment this line out with a single quote

OBJ 'DEMO, Needed for DEMO only
      DSP1  : "wa0uwh_DSPL"
      DSP2  : "wa0uwh_DSPL"
      FREQ  : "Synth"

VAR 'DEMO, Needed for DEMO only
     Long K0, P0, K1, P1, P2, P3
     Long PotS, Pot0, Pot1, Pot2, Pot3
     Long Contrast, BackLight, SpkrVol

PUB Demo | sec, minute, hour, devsIOKey, dsp1IOKey, dsp2IOKey, okay, Csync, Tsync, SpkrTone, i, j, k

      devsIOKey := dsp1IOKey := dsp2IOKey:= 0
      'locknew

      devsIOKey := Start(Locknew+1)
      'dsp1IOKey := DSP1.StartVGA(Locknew+1, 32, 15)
      'dsp1IOKey := DSP1.StartI2C(devsIOKey, 16, 2 )
      dsp1IOKey := DSP1.StartPAR(0, 16, 2 )

      DSP1.InitLock(locknew+1)
      'DSP2.InitLock(locknew+1)


      K0 := P0:= 0
      K1 := P1:= 0
      P2 := P3:= 0

      Contrast := 10  'Set Default Contrast
      Backlight := 92 'Set Default Backlight
      SpkrVol := 32   'Set Default Speaker Volume
      SpkrTone := 1000

      j := i := -1       'Loop Counters

      DSP1.Lock
        DSP1.clear
        DSP1.blon
        DSP1.str(string("I2C Dev Demo:"))
      DSP1.unLock

      pauseSec(4)
      DSP1.Lock
        DSP1.clear
        DSP1.str(string("Start KNOB COG: "))
      DSP1.unLock

      E0 := B0 := E1 := B1 := B2 := B3 := 0
      StartKnobs(@E0, @B0, @E1, @B1, @B2, @B3)

      if True
        pauseSec(1)
        DSP1.lock
          DSP1.XyStr(1,1,string("Time:            "))

          DSP1.XyStr(1,2,string("devsKey="))
          DSP1.Dec(GetLockNum)
          DSP1.Str(string(", DSPLKey="))
          DSP1.Dec(DSP1.GetLockNum)

          DSP1.NewLine
          DSP1.Str(string("DSPLType="))
          DSP1.Dec(DSP1.GetDSPLType)
        DSP1.unlock

        'DSP2.lock
        '   DSP2.XyStr(1,1,string("Time: I:"))
        '   DSP2.Dec(DSP2.GetLockNum)
        'DSP2.unLock

      else
      PauseSec(2)
      if False
        on2(RedL)
        on2(RedR)
        pauseSec(1)
        allLEDoff2
      else

      Csync := cnt
      repeat 'Repeat the Rest of the Method Once a Second
        i++

        DSP1.XyRjDec(20,1, i//1000, 4, " ")
        ifnot i//10
          DSP2.XyRjDec(13,1, i//1000, 4, " ")
        else

        'Display The Time of Day
        if CLKFREQ <  cnt - Csync 'Update only Once Each Second
           Csync += CLKFREQ
           j := 0 'Used by LED to sync flashes

           hour := GetHour
           minute := GetMin
           sec := GetSec

            DSP1.Lock
             DSP1.moveto(8,1)
             DSP1.rjdecSufx(hour, 2,"0", string(":"))
             DSP1.rjdecSufx(minute, 2,"0", string(":"))
             DSP1.rjdecSufx(sec, 2,"0", string("Z"))
            DSP1.unLock

            'DSP2.lock
            ' DSP2.XyRjDecSufx(2,2,hour, 2,"0", string(":"))
            ' DSP2.RjDecSufx(minute, 2,"0", string(":"))
            ' DSP2.RjDecSufx(sec, 2,"0", string("Z"))
            'DSP2.unLock

        else

        'Udate the Knobs and Buttons Counters at full Loop rate
        if E0 'Encoder Knob 0
            Contrast -= E0 * 2
            Contrast  := Contrast #> 0 <# 48
            setContrast(Contrast)

            SpkrVol  += E0 * 16
            SpkrVol   := SpkrVol #> 0 <# 128
            setSpkrVol(SpkrVol)

            K0 += E0~
            K0 := K0 #> 0 <# 255
        else

        if E1 'Encoder Knob 1
            BackLight += E1
            BackLight := BackLight #> 78 <# 110
            setBackLight(BackLight)

            SpkrTone += E1 * 50
            SpkrTone  := SpkrTone #> 0 <# 5_000

            K1 += E1~
            K1 := K1 #> 0 <# 255
            setQPotWiper(QPot0, MCP4441_WIPER3, K1) 'POT not Wired to anything
        else

        'Update Push Button Counters
        if (B0 AND B1)
           P0 := P1 := B0 := B1 := 0
           pause(100)
        else
           P0 += B0~  'Encoder Button 0
           P1 += B1~  'Encoder Botton 1

        if (B2 AND B3)
           P2 := P3 := B2 := B3 := 0
           pause(100)
        else
           P2 += B2~  'Button 2
           P3 += B3~  'Button 3



        if False
           setPotWiper(DEF_PotMCP4018addr, i//128)
        else

        'get POT Wiper Values
        ifnot i//10 - 5
           Pot0 := getQPotWiper(QPot0, MCP4441_WIPER0)
           Pot1 := getQPotWiper(QPot0, MCP4441_WIPER1)
           Pot2 := getQPotWiper(QPot0, MCP4441_WIPER2)
           Pot3 := getQPotWiper(QPot0, MCP4441_WIPER3)
        else


        'DEBUG
        ifnot i//10 - 6
           'Display Knobs and Button Counters
            DSP1.Lock
              DSP1.moveto(1,4)
              DSP1.str(string("  BKL="))
              DSP1.rjdec(BackLight,3," ")
              DSP1.str(string(" CONT="))
              DSP1.rjdec(Contrast,3," ")
              DSP1.str(string(" VOL="))
              DSP1.rjdec(SpkrVol,3," ")

              DSP1.newLine
              DSP1.rjdec(K1, 5," ")
              DSP1.rjdec(K0, 5," ")

              DSP1.newLine
              DSP1.rjdec(P1, 5," ")
              DSP1.rjdec(P0, 5," ")

              DSP1.newLine
              DSP1.rjdec(P3, 5," ")
              DSP1.rjdec(P2, 5," ")

              DSP1.newLine
              DSP1.hex(Pot3, 4)
              DSP1.str(string(" "))
              DSP1.hex(Pot2, 4)
              DSP1.str(string(" "))
              DSP1.hex(Pot1, 4)
              DSP1.str(string(" "))
              DSP1.hex(Pot0, 4)

              DSP1.newLine
              DSP1.rjdec(i, 16," ")
            DSP1.unLock
        else

        'Busy Task, Blink LED's
        case j++
            k:=0: winkon2(GrnL)
                  setSpkrTone(SpkrTone)
            k+=5: winkon2(GrnR)

            k+=5: winkon2(YelL)
                  setSpkrTone(SpkrTone-100)
            k+=5: winkon2(YelR)
                  setSpkrTone(SpkrTone+100)

            k+=5: winkon2(RedL)
            k+=5: winkon2(RedR)
                  noTone

            k+=5: winkon2(BluL)
            k+=5: winkon2(BluR)
            k+=5: winkon2(BluL)
            k+=5: winkon2(BluR)
        'case_end
'}
DAT
VAR 'STARTS
PUB Start(key) | okay

      RESULT := InitLock(key)
      StartEXP
      StartRTC
      StartQPot
      MCP4018.Start

DAT
PUB StartQPot

      QPot0 :=  DEF_PotMCP4441Addr0
      'QPot1 :=  DEF_PotMCP4441Addr1
      'QPot2 :=  DEF_PotMCP4441Addr2
      'QPot3 :=  DEF_PotMCP4441Addr3

      '$FB = All POT Ports On, Except Port A on POT 0 (contrast port)
      putbyte(QPOT0, MCP4441_TCON0, $FB)
      putbyte(QPOT0, MCP4441_TCON1, $FF)

      'Set POT Wipers for the following
      setContrast(10)  'Set LCD Default Contrast
      setBackLight(64) 'Set LCD Default BackLight
      setSpkrVol(127)   'Set Speaker Volume

DAT
PUB StartEXP

      EXP2 := DEF_ExpAddr0
      EXP3 := DEF_ExpAddr1

      I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)

      'Expander #2
      putbyte(EXP2, IOCON, $80)    'Set for Dual Bank(1) Mode

      'Connected to Encoders and Buttons
      putbyte(EXP2, IOCONA,$80)    'Set for Dual Bank(1) Mode (same as previous line only using Bank Reg)
      putbyte(EXP2, IODIRA,$00)    'Set for Output
      putbyte(EXP2, OLATA, $00)    'Clear Output Latch

      'Connected to the LEDs
      putbyte(EXP2, IODIRA,$00)    'Set for Output
      putbyte(EXP2, OLATB,!$00)    'Clear Output Latch (neg true logic)



      'Expander #3
      putbyte(EXP3, IOCON, $80)    'Set for Dual Bank(1) Mode

      'Connected to Parallel LCD
      putbyte(EXP3, IOCONA,$80)    'Set for Dual Bank(1) Mode (same as previous line only using Bank Reg)
      putbyte(EXP3, IODIRA,$00)    'Set for Output
      putbyte(EXP3, OLATA, $01)    'Clear A Output Latch, Except BackLight

      'Not Connected to anything on the UI
      putbyte(EXP3, IODIRB,$FF)    'Set for Input
      putbyte(EXP3, OLATB, $00)    'Clear B Output Latch

DAT
VAR 'START KNOBS
   Long cog, cogStack[256] 'Local Static Variables
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

    putbyte(EXP2, IOCON,    $80)          'Set for Bank1 Mode, Active Low IntA
    putbyte(EXP2, IOCONA,   $80)          'Set for Bank1 Mode, Active Low IntA, if aready in Bank1 mode
    putbyte(EXP2, IODIRA,   $FF)          'Set ALL Pins for Input
    putbyte(EXP2, IPOLA,    $FF)          'Set ALL Pins for Reverse Polarity
    putbyte(EXP2, GPPUA,    $FF)          'Turn on 100K Pull Ups for ALL Pins
    putbyte(EXP2, GPINTENA, IntPinMask)   'Interrupt Condition = On Change for some Pins
    putbyte(EXP2, DEFVALA,  !IntPinMask)   'Sets None Interrupt State for some Pins
    putbyte(EXP2, INTCONA,  !IntPinMask)   'Enable Interrputs for some Pins

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
    long[pE0] := long[pB0] := long[pE1] := long[pB1] := long[pB2] := long[pB3] := 0

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


    getbyte(EXP2, GPIOA)  'Clear Erroneous Interrupts


    repeat 'StartLoop
        'Poll for Button Being Pressed
        ISRv := getbyte(EXP2, INTCAPA) & ButtonMask
        ifnot ISRv 'Wait for Button or Rotory Knob Event
           waitpne(mask, pins, 0) 'waiting for interrupt signal
           ISRv := getbyte(EXP2, INTCAPA)  'Get Interrupt Values
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

VAR 'LED CONTROL VIA PROP PINS
PUB on(ExpPin) ' LED Control
      return onmask(1<<ExpPin)

PUB off(ExpPin) ' LED Control
      return offmask(1<<ExpPin)

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

VAR 'LED CONTROL VIA EXPANDER #2
PUB on2(ExpPin) 'LED Control via Dual I/O Expander
      return onmask2(1<<ExpPin)

PUB off2(ExpPin) 'LED Control via Dual I/O Expander
      return offmask2(1<<ExpPin)

DAT
PUB blinkon2(pin, dur) 'LED Control via Dual I/O Expander
      on2(pin)
      pause(dur)
      off2(pin)

PUB blinkoff2(pin, dur) 'LED Control via Dual I/O Expander
      off2(pin)
      pause(dur)
      on2(pin)

DAT
PUB winkon2(pin) 'LED Control via Dual I/O Expander
      blinkon2(pin, 30)

PUB winkoff2(pin) 'LED Control via Dual I/O Expander
      blinkoff2(pin, 30)

DAT
PUB allLEDon2 'LED Control via Dual I/O Expander
      return onmask2($FF)

PUB allLEDoff2 'LED Control via Dual I/O Expander
      return offmask2($FF)

DAT
PUB onmask2(mask) | Latched
        putbyte(EXP2, IODIRB, 0)
        Latched := getbyte(EXP2, OLATB) & ! mask
        RESULT := putbyte(EXP2, OLATB, Latched)
      return

PUB offmask2(mask) : stat | Latched
        Latched := getbyte(EXP2, OLATB) | mask
        RESULT := putbyte(EXP2, OLATB, Latched)
      return

VAR 'SPEAKER TONE CONTROL
    Long LastTone 'Local Static Variables
PUB Beep
      BeepToneDur(1000, 100)

PUB BeepTone(tone)
      BeepToneDur(tone, 100)

PUB BeepToneDur(tone, dur)
     setSpkrTone(tone)
     pause(dur)
     noTone

PUB setSpkrTone(Tone)
      if Tone <> LastTone
        Freq.Synth("B",SpeakerPin, Tone)
        LastTone := Tone
      dira[SpeakerPin]~~           'Set For Output

PUB noTone
      dira[SpeakerPin]~            'Set For No Output

PUB stopTone
      Freq.Synth("B",SpeakerPin, 0)
      noTone

PUB setSpkrVol(val)
      return putbyte(QPot0,MCP4441_WIPER2, val)

DAT
VAR 'LCD CONTRAST AND BACKLIGHT
PUB setContrast(val)
      return setQPotWiper(QPot0, MCP4441_WIPER0, val)

PUB setBackLight(val)
      return setQPotWiper(QPot0, MCP4441_WIPER1, val)

DAT
PUB getContrast
      return getQPotWiper(QPot0, MCP4441_WIPER0)

PUB getBackLight
      return getQPotWiper(QPot0, MCP4441_WIPER1)


VAR 'SET POT WIPER For MCP4018
PUB setPotWiper(addr, value) 'POT Wiper Control
      Lock
        MCP4018.putbyte(addr, value)
      unLock
      return getPotWiper(addr)

PUB getPotWiper(addr) 'POT Wiper Control
      Lock
        RESULT := MCP4018.getbyte(addr)
      unLock
      return

VAR 'SET POT WIPER For Dual and Quad Devices, MCP23008, MCP23017 Family
PUB setQPotWiper(addr, reg, val) 'Quad POT Wiper Control
      return putbyte(addr, reg, val #>0 <#128)

PUB getQPotWiper(addr, reg) | tmp 'Quad POT Wiper Control
      return getword(addr, reg | $0C) >> 8

VAR 'REALTIME CLOCK
PUB StartRTC 'Init for RTC
      Lock
        I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)
      unLock
      RTC := DEF_RTCaddr
      return setInteruptOnSec

DAT
PUB setSec(arg) ' Real Time Clock (RTC) Control
      return setRTC(RTC, cSS, arg)

PUB setMin(arg) ' Real Time Clock (RTC) Control
      return setRTC(RTC, cMM, arg)

PUB setHour(arg) ' Real Time Clock (RTC) Control
      return setRTC(RTC, cHH, arg)

PUB setDay(arg) ' Real Time Clock (RTC) Control
      return setRTC(RTC, cDD, arg)

PUB setMonth(arg) ' Real Time Clock (RTC) Control
      return setRTC(RTC, cLL, arg)

PUB setYear(arg) ' Real Time Clock (RTC) Control
      return putbyte(RTC, cYY, arg)

pri setRTC(adr,reg,arg) ' Real Time Clock (RTC) Control
      return putbyte(adr, reg, (arg/10)<<4 + (arg // 10))

DAT
PUB setInteruptOnSec ' Real Time Clock (RTC) Control
      return putbyte(RTC, $0E, 0)

DAT
PUB getSec ' Real Time Clock (RTC) Query
      return getRTC(RTC, cSS)

PUB getMin ' Real Time Clock (RTC) Query
      return getRTC(RTC, cMM)

PUB getHour ' Real Time Clock (RTC) Query
      return getRTC(RTC, cHH)

PUB getDay ' Real Time Clock (RTC) Query
      return getRTC(RTC, cDD)

PUB getMonth ' Real Time Clock (RTC) Query
      return getRTC(RTC, cLL)

PUB getYear ' Real Time Clock (RTC) Query
      return getRTC(RTC, cYY)

pri getRTC(adr, reg)
      RESULT := getbyte(adr, reg)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

VAR 'LOW LEVEL I2C TRANSFERS
PUB getbyte(adr, reg) 'Low Level I2C Data Transfer
    Lock
      RESULT := I2C.getbyte(adr, reg)
    unLock
    return

DAT
PUB putbyte(adr, reg, val) 'Low Level I2C Data Transfer
    Lock
      RESULT := I2C.putbyte(adr, reg, val)
    unLock
    return

DAT
PUB getword(adr, reg) 'Low Level I2C Data Transfer
    Lock
      RESULT := I2C.getword(adr, reg)
    unLock
    return

DAT
PUB putword(adr, reg, val) 'Low Level I2C Data Transfer
    Lock
      RESULT := I2C.putword(adr, reg, val)
    unLock
    return

VAR 'LOCKS
     Long LockNum, LockOwner 'Static Variable
Pri InitLock(num)
      'Initialize LOCKs,
      'Processor provided Lock 'num' (1 - 8) to use if sharing the I2C bus.
      'Use -1 to request a new lock number.
      'This Lock is used to prevent multiple COGs from mangling I2C commands

       LockNum := num
       if LockNum < 0
          LockNum := locknew + 1
          if lockNum > 0
             LockOwner := True
       return LockNum

Pri releaseLock
      if LockNum > 0
        if LockOwner
          lockret(LockNum - 1)
          LockNum := -1
      return LockNum

DAT
Pri Lock 'Lock for I2C Bus
      repeat while lockset(LockNum - 1)

Pri unLock
      return lockclr(LockNum -1)

PUB getLockNum
      return LockNum

VAR 'PAUSE
PRI pauseSec(sec)
      pause(1000 * sec)

PRI pause(ms)
      waitcnt(((clkfreq / 1_000 * ms - 3932) #> WMin) + cnt)

VAR 'END
