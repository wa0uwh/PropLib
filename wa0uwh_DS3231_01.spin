CON
{{
     WA0UWH - DS3231   - Realtime Clock (RTC) with onboard Lithium Battery

     FileName: wa0uwh_DS3231_01.spin
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
    'Max of one RTC / I2C Bus
    DEF_RTCaddr = $68 << 1

    #$00, cSS, cMM, cHH, cWW, cDD, cLL, cYY, A1M1    'LL = Lunar (or Month)
    #$0E, CTL, STAT
    #$11, iTEMP


OBJ
      I2C     : "jm_i2c"
      SMITH   : "wa0uwh_Lock_01"

VAR
     Long RTCAddr

DAT 'DEMO
{  'To Run Demo, Comment this line out with a single quote as the first character

OBJ 'DEMO, Needed for DEMO only
      DSP1  : "wa0uwh_DSPL_01"
      DSP2  : "wa0uwh_DSPL_01"

VAR 'DEMO, Needed for DEMO only
     Long I2CKey, DspKey1, DspKey2

PUB Demo | sec, minute, hour, tempC, tempF, okay, Csync, i, j, k, ppb

      ppb := 0

      I2CKey := DspKey1 := DspKey2 := 0

      StartFreqError(@ppb, 0, 0)




      DspKey1 := DSP1.StartDspVGA(Locknew+1, 32, 15 )

      DSP2.ClearStr(string("DEBUG"))

      DSP1.XyStr(1,3,string("Starting I2C"))

      I2CKey  := Start(Locknew+1,0)  'Starts I2C Bus, must be before I2C Display
      DspKey2 := DSP2.StartDspI2C(I2CKey, 16, 2 )

      'DSP1.ClearStr(string("DEBUG"))

      PauseMS(500)

      DSP1.Lock
        DSP1.ClearStr(string("RTC:"))
      DSP1.UnLock

      DSP2.Lock
        DSP2.ClearStr(string("RTC:"))
      DSP2.UnLock

      PauseSec(2)

      if True
        pauseSec(1)
        DSP1.lock
          DSP1.ClearStr(string("RTC:"))
          DSP1.XyStr(1,5,string("LK="))    'Local Key
          DSP1.Dec(GetLockNum)
          DSP1.space
          DSP1.Str(string("DK1="))         'Display Key
          DSP1.Dec(DSP1.GetLockNum)
          DSP1.space
          DSP1.Str(string("DT1="))         'Display Type
          DSP1.Dec(DSP1.GetDSPLType)
          DSP1.space
          DSP1.Str(string("DK2="))         'Display Key
          DSP1.Dec(DSP2.GetLockNum)
          DSP1.space
          DSP1.Str(string("DT2="))         'Display Type
          DSP1.Dec(DSP2.GetDSPLType)
        DSP1.Unlock
      else

      Csync := cnt
      repeat 'Repeat the Rest of the Method Once a Second

        DSP1.Unlock
           DSP1.XyRjDec(17,1, i//1000, 4, " ")  'Does not show on 16x2 LCD
           DSP1.Space
           DSP1.Dec(Samples)
           DSP1.Space
           DSP1.Dec(DeltaC)
        DSP1.Unlock

        'Display The Time of Day
        if CLKFREQ <  cnt - Csync 'Update only Once Each Second
           Csync += CLKFREQ

           hour   := GetHour
           minute := GetMin
           sec    := GetSec
           tempC  := GetTempC
           tempF  := GetTempF

            DSP1.Lock
              DSP1.MoveTo(7,1)
              DSP1.RjDecSufx(hour, 2,"0", string(":"))
              DSP1.RjDecSufx(minute, 2,"0", string(":"))
              DSP1.RjDecSufx(sec, 2,"0", string("z"))

              DSP1.XyStr(1,2,string("CLK Er="))
              DSP1.DecSufx(ppb,string("ppb,Temp="))
              'DSP1.DecSufx(tempC,string("C"))
              DSP1.DecSufx(tempF,string("F"))
            DSP1.UnLock

            DSP2.Lock
              DSP2.MoveTo(7,1)
              DSP2.RjDecSufx(hour, 2,"0", string(":"))
              DSP2.RjDecSufx(minute, 2,"0", string(":"))
              DSP2.RjDecSufx(sec, 2,"0", string("z"))

              DSP2.XyDecSufx(1,2,ppb,string("ppb,T="))
              'DSP2.DecSufx(tempC,string("C"))
              DSP2.DecSufx(tempF,string("F"))
            DSP2.UnLock
        'ifend
        i++

'}
DAT
VAR 'STARTS
PUB Start(key, addr) | okay
      Startx(key, addr, 0, 0)

PUB Startx(key, addr, scl, sda) | okay
      ifnot (scl or sda)
        I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)
      else
        I2C.Init(scl, sda)

      RESULT := StartLock(key)
      StartRTC(addr)

DAT

VAR 'REALTIME CLOCK
PUB StartRTC(addr) 'Init for RTC

      RTCAddr := DEF_RTCaddr
      if addr <> 0
          RTCAddr := DEF_RTCaddr

      'putbyte($0E, 0)
      SetInteruptOnSec
      return

DAT
CON
    DEF_AvgCount = 100
    DEF_PulseHzPin = 9
VAR 'Static Varaibles
    Long cog, cogStack[64]
PUB StartFreqError(pPPB, pin, AvgCount) | okay
' The first Argument is pointers (p) to variable (counter) within the calling APP
' A typical APP will check this Counter and adjust the Freq of the Synth as necessary

    StopFreqError

    long[pPPB] := 0
    okay := cog := (cognew(FreqError(pPPB, pin, AvgCount), @cogStack) +1)

    return cog
DAT
PUB StopFreqError
{{Stop; frees a cog.}}

  if cog
    cogstop(cog~ - 1)

DAT
   Samples Long 0
   DeltaC  Long 0
   Average Long 0

PRI FreqError(pPPB, pin, AvgCount)| pins, mask, i, C, PrevC

  'Provides current Error Clock Freq Error in PPB via Passed Parameter
  'Pin to watch
  'SamplesCount is the sample width

    if pin == 0
      pin := DEF_PulseHzPin

    if AvgCount == 0
      AvgCount := DEF_AvgCount
    AvgCount := AvgCount #> 2 <#1000

    pins := 1<<pin
    mask := pins

    dira[pins]~    'Set for Input, and Float high via user supplied Pullup 10K Resistors

    Samples := 0
    Average := 0
    PrevC := 0

    repeat 'Loop Forever
      waitpne(mask, pins, 0) ' waiting for pin to be low
      waitpeq(mask, pins, 0) ' waiting for pin to go High
      C := cnt
      if PrevC
        Samples := Samples + 1 <# AvgCount
        DeltaC := (C - PrevC - CLKFREQ)
        Average := (Average * (Samples - 1) + DeltaC) / Samples
        if Samples > 2
          long[pPPB] := -(Average * 1_000) / (CLKFREQ / 1_000_000)
      PrevC := C

DAT
VAR 'Clock Routines
PUB SetSec(arg) ' Real Time Clock (RTC) Control
      return SetRTC(cSS, arg)

PUB SetMin(arg) ' Real Time Clock (RTC) Control
      return SetRTC(cMM, arg)

PUB SetHour(arg) ' Real Time Clock (RTC) Control
      return SetRTC(cHH, arg)

PUB SetDay(arg) ' Real Time Clock (RTC) Control
      return SetRTC(cDD, arg)

PUB SetMonth(arg) ' Real Time Clock (RTC) Control
      return SetRTC(cLL, arg)

PUB SetYear(arg) ' Real Time Clock (RTC) Control
      return putbyte(cYY, arg)

pri SetRTC(reg,arg) ' Real Time Clock (RTC) Control
      return putbyte(reg, (arg/10)<<4 + (arg // 10))

DAT
PUB GetSec ' Real Time Clock (RTC) Query
      return GetRTC(cSS)

PUB GetMin ' Real Time Clock (RTC) Query
      return GetRTC(cMM)

PUB GetHour ' Real Time Clock (RTC) Query
      return GetRTC(cHH)

PUB GetDay ' Real Time Clock (RTC) Query
      return GetRTC(cDD)

PUB GetMonth ' Real Time Clock (RTC) Query
      return GetRTC(cLL)

PUB GetYear ' Real Time Clock (RTC) Query
      return getbyte(cYY)

PUB GetTempC ' Real Time Clock (RTC) Query
      return getbyte(iTEMP) * 100 + 25 * (getbyte(iTEMP+1)>>6)

PUB GetTempF
      return (GetTempC * 9 / 5) + 3200

pri GetRTC(reg)
      RESULT := GetByte(reg)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)
      return
DAT
PUB SetInteruptOnSec ' Real Time Clock (RTC) 1Hz Control
      return putbyte(CTL, 0)

VAR 'LOW LEVEL I2C TRANSFERS
PUB getbyte(reg) 'Low Level I2C Data Transfer
    Lock
      RESULT := I2C.getbyte(RtcAddr, reg)
    UnLock
    return

DAT
PUB putbyte(reg, val) 'Low Level I2C Data Transfer

    Lock
      RESULT := I2C.putbyte(RtcAddr, reg, val)
    UnLock
    return

VAR 'Simple LOCK SMITH
PRI StartLock(num)
      'Processor provided Lock 'num' (1 - 8) to use if sharing resources.
      'Use -1 to request a new lock number.
      'This Lock is used to prevent multiple COGs from mangling resources.

     return SMITH.StartLock(num)

PRI Lock
     return SMITH.Lock

PRI UnLock
     return SMITH.UnLock

PUB GetLockNum
     return SMITH.GetLockNum

VAR 'Simple DEBUG Return Value
PUB DeBug
     return SMITH.Debug   'Change this to anything of DEBUG interest !

VAR 'PAUSE
PRI PauseSec(sec)
      PauseMS(1000 * sec)

PRI PauseMS(ms)
      waitcnt(((clkfreq / 1_000 * ms - 3932) #> WMin) + cnt)

VAR 'END
