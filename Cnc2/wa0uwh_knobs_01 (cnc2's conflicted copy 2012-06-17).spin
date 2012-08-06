CON
{{
     This Object Provides Knob and Buttons for User Prop Programs, using
     WA0UWH's - Propeller USB ProtoBoard UI and Supporting Objects

     FileName: wa0uwh_knobs_01.spin
     Author:   Eldon R. Brown - WA0UWH
     Date:     Jun 11, 2011
     Rev:      0.01

}}

CON
    WMin = 381

    CLKSRC = 1 '*2    'Comment out the "*2" for 5MHz Cystal, UnComment for 10MHz TCVCXO
    _CLKMODE = XTAL1 * CLKSRC * CLKSRC + PLL16X / CLKSRC
    _XINFREQ = 5_000_000 * CLKSRC

CON
    KNOB_ISR_PIN = 8 'Interrupt PIN on Prop

CON
    'Pin Names for Expander1 of  BankA
    #0, Encoder0PinA, Encoder0PinB, Encoder0ButPin, Push0ButPin
    #4, Encoder1PinA, Encoder1PinB, Encoder1ButPin, Push1ButPin

OBJ
      I2C     : "jm_i2c"              'Low level I2C Driver
      EXP0    : "wa0uwh_MCP230XX_01"  'Expander, A is Connected to Encoders and Buttons, B is Connected to LEDs
      LIO     : "wa0uwh_Lock_01"      'Lock IO
      LOBJ    : "wa0uwh_Lock_01"      'Lock Objects

VAR
     Long E0, B0, E1, B1, B2, B3

DAT 'DEMO
{' To Run Demo, Comment this line out with a single quote

OBJ 'DEMO, Needed for DEMO only
      DSP1  : "wa0uwh_DSPL_01"
      DSP2  : "wa0uwh_DSPL_01"
      RTC   : "wa0uwh_DS3231_01"

VAR 'DEMO, Needed for DEMO only
     Long K0, P0, K1, P1, P2, P3
     Long LioKey, Exp0Key, Exp1Key, DspKey1, DspKey2

PUB Demo | sec, minute, hour, okay, Csync, Tsync, SpkrTone, i, j, k

      K0 := P0 := P2 := 0
      K1 := P1 := P3 := 0

      LioKey := Exp0Key := DspKey1 := DspKey2 := 0

      LioKey  := Start(Locknew+1)  'Starts I2C Bus, must be before I2C Display

      DspKey1 := DSP1.StartDspVGA(Locknew+1, 32, 15 )

      DspKey2 := DSP2.StartDspI2C(LioKey, 16, 2 )
      'DspKey2 := DSP2.StartDspNull(0, 16, 2 )

      RTC.Start(LioKey, 0)

      'DSP1.ClearStr(string("DEBUG"))
      'DSP2.ClearStr(string("DEBUG"))

      DSP1.XyStr(1,3,string("DspKey2="))
      DSP1.Dec(DspKey2)

      PauseMS(500)

      j := i := -1       'Loop Counters

      DSP1.Lock
        DSP1.ClearStr(string("Knob Demo:"))
      DSP1.unLock

      pauseSec(1)
      DSP1.Lock
        DSP1.ClearStr(string("Start KNOB COG: "))
      DSP1.unLock

      E0 := B0 := E1 := B1 := B2 := B3 := 0
      StartKnobs(@E0, @B0, @E1, @B1, @B2, @B3)

      'DSP1.ClearStr(string("DEBUG"))

      if True
        pauseSec(1)
        DSP1.lock
          DSP1.ClearStr(string("KNOBS:"))

          DSP1.XyStr(1,4,string("LK="))
          DSP1.Dec(GetLockNum)
          DSP1.Space
          DSP1.Str(string("DK1="))
          DSP1.Dec(DSP1.GetLockNum)
          DSP1.Space
          DSP1.Str(string("DT1="))
          DSP1.Dec(DSP1.GetDSPLType)
          DSP1.Space

          DSP1.Str(string("DK2="))
          DSP1.Dec(DSP2.GetLockNum)
          DSP1.Space
          DSP1.Str(string("DT2="))
          DSP1.Dec(DSP2.GetDSPLType)
        DSP1.unlock

        DSP2.lock
           DSP2.ClearStr(string("KNOBS: L:"))
           DSP2.Dec(DSP2.GetLockNum)
        DSP2.unLock
      else

      PauseSec(2)

      Csync := cnt
      repeat 'Repeat Forever
        i++

        DSP1.lock
          DSP1.XyRjDec(20,1, i//1000, 4, " ")
        DSP1.UnLock

        ifnot i//10
          DSP2.Lock
            DSP2.XyRjDec(13,1, i//1000, 4, " ")
          DSP2.UnLock
        else

        'Udate the Knobs and Buttons Counters at full Loop rate
        if E0 'Encoder Knob 0
            K0 += E0~
            K0 := K0 #> -128 <# 127
        else

        if E1 'Encoder Knob 1
            K1 += E1~
            K1 := K1 #> -128 <# 127
        else

        'Update Push Button Counters
        if (B0 AND B1)
           P0 := P1 := B0 := B1 := 0
           PauseMS(100)
        else

        if B0
           P0 += B0~  'Encoder Button 0
           P0 := P0 #> -128 <# 127
        else

        if B1
           P1 += B1~  'Encoder Botton 1
           P1 := P1 #> -128 <# 127
        else

        if (B2 AND B3)
           P2 := P3 := B2 := B3 := 0
           PauseMS(100)
        else

        if B2
           P2 += B2~  'Button 2
           P2 := P2 #> -128 <# 127
        else

        if B3
           P3 += B3~  'Button 3
           P3 := P3 #> -128 <# 127
        else

        ifnot i//10 - 5
           'Display Knobs and Button Counters
            DSP1.Lock
              DSP1.moveto(1,2)
              DSP1.rjdec(K1, 4," ")
              DSP1.rjdec(P1, 4," ")
              DSP1.rjdec(K0, 4," ")
              DSP1.rjdec(P0, 4," ")
              DSP1.moveto(9,1)
              DSP1.rjdec(P3, 4," ")
              DSP1.rjdec(P2, 4," ")
            DSP1.unLock

            DSP2.Lock
              DSP2.moveto(1,2)
              DSP2.rjdec(K1, 4," ")
              DSP2.rjdec(P1, 4," ")
              DSP2.rjdec(K0, 4," ")
              DSP2.rjdec(P0, 4," ")
            DSP2.unLock
        else

        hour := RTC.GetHour
        minute := RTC.GetMin
        sec := RTC.GetSec

        ifnot i//10
          DSP1.Lock
            DSP1.MoveTo(1,3)
            DSP1.RjDecSufx(hour, 2,"0", string(":"))
            DSP1.RjDecSufx(minute, 2,"0", string(":"))
            DSP1.RjDecSufx(sec, 2,"0", string("z"))
          DSP1.UnLock
        else

'}
DAT
VAR 'STARTS
PUB Start(key)
      RESULT := StartI2C(key)
      StartLock(0)
      return

PUB StartI2C(key) | okay

      I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)

      RESULT := LIO.StartLock(key)

      StartEXP0(key, 0)

      return


PUB StartEXP0(key, addr)

      'Expander #0
      ifnot addr
        addr := EXP0#DEF_Addr0

      RESULT := EXP0.Start(key, addr)

      EXP0.putbyte(EXP0#IOCON, $80)    'Set for Dual Bank(1) Mode

      'Connected to Encoders and Buttons
      EXP0.putbyte(EXP0#IOCONA,$80)    'Set for Dual Bank(1) Mode (same as previous line only using Bank Reg)
      EXP0.putbyte(EXP0#IODIRA,$00)    'Set for Output
      EXP0.putbyte(EXP0#OLATA, $00)    'Clear Output Latch

      return

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

    EXP0.putbyte(EXP0#IOCON,    $80)          'Set for Bank1 Mode, Active Low IntA
    EXP0.putbyte(EXP0#IOCONA,   $80)          'Set for Bank1 Mode, Active Low IntA, if aready in Bank1 mode
    EXP0.putbyte(EXP0#IODIRA,   $FF)          'Set ALL Pins for Input
    EXP0.putbyte(EXP0#IPOLA,    $FF)          'Set ALL Pins for Reverse Polarity
    EXP0.putbyte(EXP0#GPPUA,    $FF)          'Turn on 100K Pull Ups for ALL Pins
    EXP0.putbyte(EXP0#GPINTENA, IntPinMask)   'Interrupt Condition = On Change for some Pins
    EXP0.putbyte(EXP0#DEFVALA,  !IntPinMask)   'Sets None Interrupt State for some Pins
    EXP0.putbyte(EXP0#INTCONA,  !IntPinMask)   'Enable Interrputs for some Pins

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


    EXP0.getbyte(EXP0#GPIOA)  'Clear Erroneous Interrupts


    repeat 'StartLoop
        'Poll for Button Being Pressed
        ISRv := EXP0.getbyte(EXP0#INTCAPA) & ButtonMask
        ifnot ISRv 'Wait for Button or Rotory Knob Event
           waitpne(mask, pins, 0) 'waiting for interrupt signal
           ISRv := EXP0.getbyte(EXP0#INTCAPA)  'Get Interrupt Values
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
            PauseMS(100)
        else
    'Loop

VAR 'Simple LOCK IO
PRI StartLock(num)
      'Processor provided Lock 'num' (1 - 8) to use if sharing resources.
      'Use -1 to request a new lock number.
      'This Lock is used to prevent multiple COGs from mangling resources.

     return LOBJ.StartLock(num)

PRI Lock
     return LOBJ.Lock

PRI unLock
     return LOBJ.unLock

PUB GetLockStat
     return LOBJ.GetLockStat

PUB getLockNum
     return LOBJ.getLockNum

VAR 'Simple DEBUG Return Value
PUB DeBug
     return LOBJ.DeBug   'Change this to anything of DEBUG interest !

VAR 'PAUSE
PRI PauseSec(sec)
      PauseMS(1000 * sec)

PRI PauseMS(ms)
      waitcnt(((clkfreq / 1_000 * ms - 3932) #> WMin) + cnt)

VAR 'END
