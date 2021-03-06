CON
{{
     This Object Provides Consistant User Environment for User Prop Programs, using
     WA0UWH's - Propeller USB ProtoBoard UI and Supporting Objects

     FileName: wa0uwh_UI_01.spin
     Author:   Eldon R. Brown - WA0UWH
     Date:     Jun 11, 2011
     Rev:      0.01

     The UI contains the following peripherals
     01. DS3231   - Realtime Clock (RTC) with onboard Lithium Battery
     02. MCP23017 - Dual Port I2C Expander (16 pins total) - used as a driver for LEDs, Knobs and Buttons
     03. MCP23008 - Single Port I2C Expander (8 pins) - used as a driver for the Parallel LCD
     04. MCP4441  - A Quad POT used to adjust LCD Backlight Level, Contrast Level and Speaker Volume
     05. Eight LEDs for user feedback
     06. Two Rotary Encoders with Push Buttons
     07. Two simple Push Buttons
     08. Support for an Alternate I2C LCD - C0220BiZ
     09. Peizo Speaker (beeper)
     10. DS3231   - With 1Hz tick, the Prop computes PPB Error as "ppb"

}}

CON
    WMin = 381

    CLKSRC = 1 '*2    'Comment out the "*2" for 5MHz Cystal, UnComment for 10MHz TCVCXO
    _CLKMODE = XTAL1 * CLKSRC * CLKSRC + PLL16X / CLKSRC
    _XINFREQ = 5_000_000 * CLKSRC

CON
    KNOB_ISR_PIN = 8 'Interrupt PIN on Prop

CON
    RfPin1     = 7
    RfPin2     = 6
    SpeakerPin = 5

OBJ
      I2C     : "jm_i2c"              'Low level I2C Driver
      EXP0    : "wa0uwh_MCP230XX_01"  'Expander, A is Connected to Encoders and Buttons, B is Connected to LEDs
      EXP1    : "wa0uwh_MCP230XX_01"  'Expander, Connected to LCD
      SPOT0   : "wa0uwh_MCP4018_01"   'Single POT, used to adjust TCVCXO if installed
      QPOT0   : "wa0uwh_MCP4441_01"   'Quad POT, used to set; BackLight, Contrast and Volume
      RTC     : "wa0uwh_DS3231_01"    'RealTime Clock
      LEDS    : "wa0uwh_LEDS_01"      'LED Driver
      KNOB    : "wa0uwh_Knobs_01"     'Rotary Encoders Knobs and Push Buttons
      LI2C    : "wa0uwh_Lock_01"      'Lock I2C IO
      LOBJ    : "wa0uwh_Lock_01"      'Lock Objects

VAR
     Long E0, B0, E1, B1, B2, B3 'Passed By Ref to Knob COG

     Long I2CKey, DspKey1, DspKey2                 'Lock Keys
     Long Sec, Minute, Hour, Temp, Ppb             'RTC
     Long Contrast, BackLight, SpkrVol, SpkrTone            '
     Long FuncKey0, FuncKey1
     Long i, j                                      'MainLoop Counters

DAT 'DEMO
'{  'To Run Demo, Comment this line out with a single quote as the First Character

CON
     K = 5 'Time Slice Increments for LEDs Blink and Tone Sequence

OBJ 'DEMO, Needed for DEMO only
      DSP1  : "wa0uwh_DSPL_01"
      DSP2  : "wa0uwh_DSPL_01"
      OSC1  : "Synth"

VAR 'DEMO, Needed for DEMO only
     Long K0, P0, K1, P1, P2, P3       'Used to collect Knob and Button Events
     Long PotS, Pot0, Pot1, Pot2, Pot3 'Used to collect POT Values

PUB Demo |  okay, Csync, Tsync, PrevI

      I2CKey := DspKey1 := DspKey2 := Ppb := 0

      DspKey1 := DSP1.StartDspVGA(0, 32, 15)
      DSP1.ClearStr(string("DEBUG"))    'Just to see if it works

      DSP1.Lock
        DSP1.ClearStr(string("Start I2C Devs:"))
      DSP1.UnLock

      I2CKey  := Start(Locknew+1)  'Starts I2C Bus, must be before I2C Display
      DspKey2 := DSP2.StartDspI2C(I2CKey, 16, 2)
      'DspKey2 := DSP2.StartDspBiZ(I2CKey, 16, 2)
      DSP2.ClearStr(string("DEBUG"))    'Just to see if it works

      DSP1.Lock
        DSP1.XyStr(1,3, string("DspKey2="))
        DSP1.Dec(DspKey2)
      DSP1.UnLock

      RTC.StartFreqError(@Ppb, 0, 120)

      'Initialize Knob and Push Button Counters
      K0 := P0:= 0
      K1 := P1:= 0
      P2 := P3:= 0

      Contrast := 4  'Set Default Contrast
      setContrast(Contrast)

      Backlight := 92 'Set Default Backlight
      setBackLight(BackLight)

      j := i := -1       'Initialize Loop Counters

      DSP1.Lock
        DSP1.ClearStr(string("UI Dev Demo:"))
      DSP1.unLock

      DSP1.Lock
        DSP1.XyStr(1,3, string("Lobj=")) 'Display Lock OBJ Number
        DSP1.Dec(getLockNum)
        DSP1.Str(string(" I2CK="))       'Display I2C Lock Number
        DSP1.Dec(I2CKey)
        DSP1.Str(string(" DspKey1="))    'Display the Displays Lock Number
        DSP1.Dec(DSP1.GetLockNum)
      DSP1.unLock

      pauseSec(1)
      DSP1.Lock
        DSP1.ClearStr(string("Start KNOB COG: "))
      DSP1.unLock

      E0 := B0 := E1 := B1 := B2 := B3 := 0
      KNOB.Start(I2CKey)
      KNOB.StartI2CKnobs(@E0, @B0, @E1, @B1, @B2, @B3)

      if True
        pauseSec(1)
        DSP1.lock
          DSP1.XyStr(1,1, string("Time:            "))

          DSP1.XyStr(1,3, string("LK="))
          DSP1.Dec(GetLockNum)
          DSP1.Sp
          DSP1.Str(string("DT1="))
          DSP1.Dec(DSP1.GetDSPLType)
          DSP1.Sp
          DSP1.Str(string("DK1="))
          DSP1.Dec(DSP1.GetLockNum)

          DSP1.Sp
          DSP1.Str(string("DT2="))
          DSP1.Dec(DSP2.GetDSPLType)
          DSP1.Sp
          DSP1.Str(string("DK2="))
          DSP1.Dec(DSP2.GetLockNum)
        DSP1.unlock

        DSP2.lock
           DSP2.XyStr(1,1, string("Time: DK2="))
           DSP2.Dec(DSP2.GetLockNum)
        DSP2.unLock
      {if_end}


      OutputFreqStandard(10_000_000)       'Output on RF Output Pin

      'Reset these again for Main Loop
      Contrast := 4  'Set Default Contrast
      setContrast(Contrast)

      Backlight := 92 'Set Default Backlight
      setBackLight(BackLight)

      SpkrVol := 64   'Set Default Speaker Volume
      setSpkrVol(SpkrVol)

      SpkrTone := 600

'### Main Loop ##################################################################

      PrevI := 0
      Csync := cnt
      repeat 'Loop Forever
        i++

        'Display Shorted Loop Counter, i.e, a Busy Light
        DSP1.Lock
          DSP1.XyRjDec(20,1, i//1000, 4, " ")
          'Display the Loop Counter in Full Precision
          DSP1.XyRjdec(1,10, i, 16," ")
        DSP1.UnLock

        ifnot i//10
          DSP2.Lock
             DSP2.XyRjDec(13,1, i//1000, 4, " ")
          DSP2.UnLock
        {if_end}

        DecodeKnobs 'Update Knob and Button Counter

        'Display The Time of Day
        if CLKFREQ <  cnt - Csync 'Update the following only Once Each Second
           Csync += CLKFREQ
           j := 0 'Used by LED to sync flashes

           DSP1.Lock
             DSP1.XyRjdec(1,11, i-PrevI, 16," ")
           DSP1.UnLock
           PrevI := i

           'DSP1.ClearStr(string("DEBUG"))

           Hour := RTC.GetHour
           Minute := RTC.GetMin
           Sec := RTC.GetSec
           Temp := RTC.GetTempf

           ifnot Sec
             OutputFreqStandard(10_000_000)
           {if_end}

            'Display the Time and Temperature
           DSP1.Lock
             DSP1.XyRjDecSufx(7,1, Hour, 2,"0", string(":"))
             DSP1.RjDecSufx(Minute, 2,"0", string(":"))
             DSP1.RjDecSufx(Sec, 2,"0", string("z"))
             DSP1.XyStr(1,2,string("CLK Er:"))
             DSP1.DecSufx(Ppb,string("ppb"))
             DSP1.CSp
             DSP1.Str(string("T="))
             DSP1.DecSufx(temp, string("F"))
           DSP1.UnLock

           DSP2.Lock
             DSP2.XyRjDecSufx(1,2, Hour, 2,"0", string(":"))
             DSP2.RjDecSufx(Minute, 2,"0", string(":"))
             DSP2.RjDecSufx(Sec, 2,"0", string("z "))
             DSP2.Dec(Ppb)
           DSP2.UnLock

        {if_end}



        if False 'Used only with TCVCXO
           'setPotWiper(DEF_PotMCP4018addr, i//128)
        {if_end}

        'Just for fun, get POT Wiper Values
        ifnot i//10 - 5
          Pot0 := getQPotWiper(QPOT0#WIPER0)
          Pot1 := getQPotWiper(QPOT0#WIPER1)
          Pot2 := getQPotWiper(QPOT0#WIPER2)
          Pot3 := getQPotWiper(QPOT0#WIPER3)
        {if_end}


        'DEBUG
        ifnot i//10 - 6
          'Display Knobs and Button Counters
          DSP1.Lock
            'Display Decoded Backlight, Contrast, Spkr Volume, and Spkr Tone
            DSP1.moveto(1,4)
            DSP1.str(string("Bkl="))
            DSP1.rjdec(BackLight,3," ")
            DSP1.CSp
            DSP1.str(string("Cont="))
            DSP1.rjdec(Contrast,3," ")
            DSP1.nl
            DSP1.str(string("Vol="))
            DSP1.rjdec(SpkrVol,3," ")
            DSP1.CSp
            DSP1.str(string("Tone="))
            DSP1.rjdec(SpkrTone,5," ")

            'Display the Decocde Values of the Knobs and Buttons
            DSP1.nl
            DSP1.rjdec(K1, 5," ")
            DSP1.rjdec(K0, 5," ")

            DSP1.nl
            DSP1.rjdec(P1, 5," ")
            DSP1.rjdec(P0, 5," ")

            DSP1.nl
            DSP1.rjdec(P3, 5," ")
            DSP1.rjdec(P2, 5," ")

            'Just for fun, Display the Values of the POTs
            DSP1.nl
            DSP1.sp
            DSP1.hex(Pot3, 4)
            DSP1.sp
            DSP1.hex(Pot2, 4)
            DSP1.sp
            DSP1.hex(Pot1, 4)
            DSP1.sp
            DSP1.hex(Pot0, 4)
'
          DSP1.UnLock
        {if_end}

        'Busy Task, Blink LED's and Do Tones
        case j++
          K*1:  LEDS.WinkOn(LEDS#GrnL)
                setSpkrTone(SpkrTone)
          K*2:  LEDS.WinkOn(LEDS#GrnR)
          K*3:  LEDS.WinkOn(LEDS#YelL)
                setSpkrTone(SpkrTone-100)
          K*4:  LEDS.WinkOn(LEDS#YelR)
                setSpkrTone(SpkrTone+100)
          K*5:  LEDS.WinkOn(LEDS#RedL)
          K*6:  LEDS.WinkOn(LEDS#RedR)
                noTone
          K*7:  LEDS.WinkOn(LEDS#BluL)
          K*8:  LEDS.WinkOn(LEDS#BluR)
          K*9:  LEDS.WinkOn(LEDS#BluL)
          K*10: LEDS.WinkOn(LEDS#BluR)
        {case_end}

      {repeat_end}

'}
DAT
VAR 'Decode Knobs and Buttons
    Long PrevP0, PrevP1
PUB DecodeKnobs

        'Udate the Knobs and Buttons Counters at full Loop rate
        if E0 'Encoder Knob 0
            if FuncKey0
              SpkrTone += E0 * 50
              SpkrTone  := SpkrTone #> 0 <# 5_000
            else
              SpkrVol  += E0 * 2
              SpkrVol   := SpkrVol #> 0 <# 128
              setSpkrVol(SpkrVol)
            {if end}

            K0 += E0~
            K0 := K0 #> 0 <# 255
            P0~
        {if_end}

        if E1 'Encoder Knob 1
            if FuncKey1
              BackLight += E1
              BackLight := BackLight #> 78 <# 110
              setBackLight(BackLight)
            else
              Contrast -= E1 * 4
              Contrast  := Contrast #> 0 <# 48
              setContrast(Contrast)
            {if end}

            K1 += E1~
            K1 := K1 #> 0 <# 255
            P1~
            setQPotWiper(QPOT0#WIPER3, K1) 'POT not Wired to anything
        {if_end}

        'Update Push Button Counters
        if (B2 AND B3)
           P2 := P3 := B2 := B3 := 0
           PauseMS(100)
        else
          P2 += B2~
          P3 += B3~
        {if_end}

        'Rotary Encoder Buttons
        if (B0 AND B1)
           P0 := P1 := B0 := B1 := 0
           FuncKey0 := FuncKey1 := 0
           PauseMS(100)
        {if_end}

        'Check for Button 1 FuncKey Pressed
        if B1~
           ifnot P1++
              FuncKey1 := NOT FuncKey1
              E1~ 'Clear Pending Rotary Action
        {if_end}

        'Check for Button 0 FuncKey Pressed
        if B0~
           ifnot P0++
              FuncKey0 := NOT FuncKey0
              E0~ 'Clear Pending Rotary Action
        {if_end}

VAR 'STARTS
PUB Start(key)
      RESULT := StartI2C(key)
      StartLock(0)
      return

PUB StartI2C(key) | okay

      I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)

      RESULT := LI2C.StartLock(key)

      StartEXP0(key, 0)
      StartEXP1(key, 0)
      StartQPot(key, 0)

      LEDS.Start(key, 0)
      RTC.Start(key, 0)
      'SPOT0.Start(key, 0)
      return

DAT
PUB StartQPot(key, addr)

      'Quad POT #0
      ifnot addr
        addr := QPOT0#DEF_Addr0

      RESULT := QPOT0.Start(key, addr)

      '$FB = All POT Ports On, Except Port A on POT 0 (contrast port)
      QPOT0.putbyte(QPOT0#TCON0, $FB)
      QPOT0.putbyte(QPOT0#TCON1, $FF)

      'Set POT Wipers for the following
      setContrast(10)  'Set LCD Default Contrast
      setBackLight(92) 'Set LCD Default BackLight
      setSpkrVol(64)   'Set Speaker Volume

      return

DAT
PUB StartEXP0(key, addr)

      'Expander #0
      ifnot addr
        addr := EXP0#DEF_Addr0

      RESULT := EXP0.Start(key, addr)
      return

PUB StartEXP1(key, addr)

      'Expander #1
      ifnot addr
        addr := EXP0#DEF_Addr1

      RESULT := EXP1.Start(key, addr)
      EXP1.putbyte(EXP1#OLAT,  $01)    'Clear A Output Latch, Except BackLight ON
      return



DAT
VAR 'RF Control
PUB OutputFreqStandard(Freq)
      Freq += (((Freq/1_000) * ppb)/1_000_000)
      OSC1.Synth("A", RFPin1, Freq)

VAR 'SPEAKER TONE CONTROL
    Long LastTone 'Local Static Variables
PUB Beep
      BeepToneDur(1000, 100)

PUB BeepTone(tone)
      BeepToneDur(tone, 100)

PUB BeepToneDur(tone, dur)
     setSpkrTone(tone)
     pauseMS(dur)
     noTone

PUB setSpkrTone(Tone)
      if Tone <> LastTone
        OSC1.Synth("B",SpeakerPin, Tone)
        LastTone := Tone
      dira[SpeakerPin]~~           'Set For Output

PUB noTone
      dira[SpeakerPin]~            'Set For No Output

PUB stopTone
      OSC1.Synth("B",SpeakerPin, 0)
      noTone

DAT
VAR 'LCD - CONTRAST, BACKLIGHT and SPEAKER VOLUME
PUB setContrast(val)
      return setQPotWiper(QPOT0#WIPER0, val)

PUB setBackLight(val)
      return setQPotWiper(QPOT0#WIPER1, val)

PUB setSpkrVol(val)
      return setQPotWiper(QPOT0#WIPER2, val)

DAT
PUB getContrast
      return getQPotWiper(QPOT0#WIPER0)

PUB getBackLight
      return getQPotWiper(QPOT0#WIPER1)

PUB getSpkrVol
      return getQPotWiper(QPOT0#WIPER2)

VAR 'SET POT WIPER For MCP4018
PUB setSPotWiper(addr, val) 'POT Single Wiper Control
      return SPOT0.putbyte(val #>0 <#128)

PUB getSPotWiper(addr) 'POT Single Wiper Control
      return  SPOT0.getbyte

VAR 'SET POT WIPER For Dual and Quad Devices - MCP4441
PUB setQPotWiper(reg, val) 'Quad POT Wiper Control
      return QPOT0.setwiper(reg, val #>0 <#128)

PUB getQPotWiper(reg) | tmp 'Quad POT Wiper Control
      return QPOT0.getwiper(reg)

VAR 'Simple LOCK IO
PRI StartLock(num)
{{
      Processor provided Lock 'num' (1 - 8) to use if sharing resources.
      Use -1 to request a new lock number.
      This Lock is used to prevent multiple COGs from mangling resources.
}}
     return LOBJ.StartLock(num)

PRI Lock
     return LOBJ.Lock

PRI unLock
     return LOBJ.unLock

PUB GetLockStat
     return LOBJ.GetLockStat

PUB getLockNum
     return LOBJ.getLockNum

VAR 'Simple DEBUG Return Values
PUB LoopCount  'MainLoop Counter
     return i

PUB DeBug
     return LOBJ.DeBug   'Change this to anything of DEBUG interest !

VAR 'PAUSE
PRI PauseSec(_sec)
      PauseMS(1000 * _sec)

PRI PauseMS(ms)
      waitcnt(((clkfreq / 1_000 * ms - 3932) #> WMin) + cnt)

VAR 'END
