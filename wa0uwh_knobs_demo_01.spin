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
    NCW =  1  'Normal Clockwise
    CCW = -1  'Counter Clockwise, some Encoders encode increase value in reverse
    ROTATION = NCW

CON
    'Pin Names for Expander1 of  BankA
    #0, Encoder0PinA, Encoder0PinB, Encoder0ButPin, Push0ButPin
    #4, Encoder1PinA, Encoder1PinB, Encoder1ButPin, Push1ButPin


    KnobIntMask = 1<<Encoder0PinA | 1<<Encoder1PinA

    ButtonIntMask = 1<<Encoder0ButPin | 1<<Encoder1ButPin | 1<<Push0ButPin | 1<<Push1ButPin

    IntMask = KnobIntMask | ButtonIntMask


OBJ
      I2C     : "jm_i2c"              'Low level I2C Driver
      EXP0    : "wa0uwh_MCP230XX_01"  'Expander, A is Connected to Encoders and Buttons, B is Connected to LEDs
      LIO     : "wa0uwh_Lock_01"      'Lock IO
      LOBJ    : "wa0uwh_Lock_01"      'Lock Objects
      KNBS    : "wa0uwh_knobs_01"

VAR
     Long E0, B0, E1, B1, B2, B3
     Long DeBugVar

DAT 'DEMO
'{  To Run Demo, Comment this line out with a single quote as the first character

OBJ 'DEMO, Needed for DEMO only
      DSP1  : "wa0uwh_DSPL_01"
      DSP2  : "wa0uwh_DSPL_01"
      RTC   : "wa0uwh_DS3231_01"
      LEDS  : "wa0uwh_LEDS_01"

VAR 'DEMO, Needed for DEMO only
     Long K0, P0, K1, P1, P2, P3
     Long I2CKey, Exp0Key, Exp1Key, DspKey1, DspKey2
     Long LoopCnt

PUB Demo | Sec, Minute, Hour, PrevSec, okay, Csync, Tsync, SpkrTone

      K0 := P0 := P2 := 0
      K1 := P1 := P3 := 0

      I2CKey := Exp0Key := DspKey1 := DspKey2 := 0

      I2CKey  := KNBS.Start(Locknew+1)  'Starts I2C Bus, must be before I2C Display

      E0 := B0 := E1 := B1 := B2 := B3 := 0 ' Initize Encoder and Button Counters
      KNBS.StartI2CKnobs(@E0, @B0, @E1, @B1, @B2, @B3)

      DspKey1 := DSP1.StartDspVGA(Locknew+1, 32, 15 )

      DspKey2 := DSP2.StartDspBiZ(I2CKey, 16, 2 )
      'DspKey2 := DSP2.StartDspI2C(I2CKey, 16, 2 )
      'DspKey2 := DSP2.StartDspNull(0, 16, 2 )

      RTC.Start(I2CKey, 0)
      LEDS.Start(I2CKey, 0)

      'DSP1.ClearStr(string("DEBUG"))
      'DSP2.ClearStr(string("DEBUG"))

      DSP1.XyStr(1,3,string("DspKey2="))
      DSP1.Dec(DspKey2)

      PauseMS(500)

      LoopCnt := -1       'Loop Counter

      DSP1.Lock
        DSP1.ClearStr(string("Knob Demo:"))
      DSP1.unLock

      pauseSec(1)
      DSP1.Lock
        DSP1.ClearStr(string("Start KNOB COG: "))
      DSP1.unLock


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
        LoopCnt++

        ifnot LoopCnt//10
          Hour := RTC.GetHour
          Minute := RTC.GetMin
          Sec := RTC.GetSec

          if sec <> PrevSec
            PrevSec := Sec
            DSP1.Lock
              DSP1.MoveTo(1,3)
              DSP1.RjDecSufx(Hour, 2,"0", string(":"))
              DSP1.RjDecSufx(Minute, 2,"0", string(":"))
              DSP1.RjDecSufx(Sec, 2,"0", string("z"))
            DSP1.UnLock

            ifnot sec//2
              LEDS.winkon(LEDS#RedR)
              LEDS.winkon(LEDS#BLuR)
            else
              LEDS.winkon(LEDS#RedL)
              LEDS.winkon(LEDS#BluL)
        else


        DSP1.lock
          DSP1.XyRjDec(20,1, LoopCnt//100_000, 6, " ")
          DSP1.XyRjDec(20,2, KNBS.GetCogStat//100_000, 6, " ")
        DSP1.UnLock

        ifnot LoopCnt//10
          DSP2.Lock
            DSP2.XyRjDec(13,1, LoopCnt//1000, 4, " ")
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
           PauseMS(100)
           P0 := P1 := B0 := B1 := 0
           K0 := K1 := 0
        else
          if B0
             P0 += B0~  'Encoder Button 0
             P0 := P0 #> -128 <# 127
          else
          if B1
             P1 += B1~  'Encoder Botton 1
             P1 := P1 #> -128 <# 127
          else
        {if end}

        if (B2 AND B3)
           PauseMS(100)
           P2 := P3 := B2 := B3 := 0
        else
          if B2
             P2 += B2~  'Button 2
             'P2 := P2 #> -128 <# 127
          else
          if B3
             P3 += B3~  'Button 3
             'P3 := P3 #> -128 <# 127
          else
        {if end}

        ifnot LoopCnt//10 - 5
           'Display Knobs and Button Counters
            DSP1.Lock
              DSP1.moveto(1,2)
              DSP1.rjdec(K1, 4," ")
              DSP1.rjdec(P1, 4," ")
              DSP1.rjdec(K0, 4," ")
              DSP1.rjdec(P0, 4," ")
              DSP1.moveto(9,1)
              DSP1.rjdec(P3//1000, 4," ")
              DSP1.rjdec(P2//1000, 4," ")
            DSP1.unLock

            DSP2.Lock
              DSP2.moveto(1,2)
              DSP2.rjdec(K1, 4," ")
              DSP2.rjdec(P1, 4," ")
              DSP2.rjdec(K0, 4," ")
              DSP2.rjdec(P0, 4," ")
            DSP2.unLock
        else

'}
DAT
VAR 'STARTS
PUB Start(key)
      RESULT := StartI2C(key)
      StartLock(0)
      return

Pri StartI2C(key) | okay

      I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)

      RESULT := LIO.StartLock(key)

      StartEXP0(key, 0)

      return


Pri StartEXP0(key, addr)

      'Expander #0
      ifnot addr
        addr := EXP0#DEF_Addr0

      RESULT := EXP0.Start(key, addr)

      EXP0.putbyte(EXP0#IOCON, $80)    'Set for Dual Bank(1) Mode

      'Connected to Encoders and Buttons
      EXP0.putbyte(EXP0#IOCONA,$80)    'Set for Dual Bank(1) Mode (same as previous line only using Bank Reg)
      EXP0.putbyte(EXP0#IODIRA,$00)    'Set for Output
      EXP0.putbyte(EXP0#OLATA, $00)    'Clear Output Latch

      'Set up the I2C Expander
      EXP0.putbyte(EXP0#IOCON,    $80)          'Set for Bank1 Mode, Active Low IntA
      EXP0.putbyte(EXP0#IOCONA,   $80)          'Set for Bank1 Mode, Active Low IntA, if aready in Bank1 mode
      EXP0.putbyte(EXP0#IODIRA,   $FF)          'Set ALL Pins for Input
      EXP0.putbyte(EXP0#IPOLA,    $FF)          'Set ALL Pins for Reverse Polarity
      EXP0.putbyte(EXP0#GPPUA,    $FF)          'Turn on 100K Pull Ups for ALL Pins
      EXP0.putbyte(EXP0#GPINTENA, IntMask)   'Interrupt Condition = On Change for some Pins
      'Enable Interrputs; Change from Stored Value for Buttons, Change From Previous for Encoders
      EXP0.putbyte(EXP0#INTCONA,  !KnobIntMask) 'Change type per pin
      EXP0.putbyte(EXP0#DEFVALA,  $00)   'Sets None Interrupt Stored Value

      return

DAT
VAR 'Simple LOCK IO
PRI StartLock(num)
{
      Processor provided Lock 'num' (1 - 8) to use if sharing resources.
      Use -1 to request a new lock number.
      This Lock is used to prevent multiple COGs from mangling resources.
}
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
     return DeBugVar   'Change this to anything of DEBUG interest !

VAR 'PAUSE
PRI PauseSec(sec)
      PauseMS(1000 * sec)

PRI PauseMS(ms)
      waitcnt(((clkfreq / 1_000 * ms - 3932) #> WMin) + cnt)

VAR 'END
