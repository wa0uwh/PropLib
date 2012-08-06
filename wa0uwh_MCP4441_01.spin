CON
{{
     WA0UWH - MCP4441  - A Quad POT

     FileName: wa0uwh_MCP4441_01.spin
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
    'Max of four MCP4441 Quad POTs / I2C Bus
    DEF_Addr0  = ($2C + 0) << 1
    DEF_Addr1  = ($2C + 1) << 1
    DEF_Addr3  = ($2C + 2) << 1
    DEF_Addr4  = ($2C + 3) << 1

    WIPER0    = $00 << 4
    WIPER1    = $01 << 4
    WIPER2    = $06 << 4
    WIPER3    = $07 << 4

    STATUS    = $50
    TCON0     = $40
    TCON1     = $A0

OBJ
      I2C     : "jm_i2c"
      LIO     : "wa0uwh_Lock_01"
      LOBJ    : "wa0uwh_Lock_01"

VAR
     Long QPotAddr

DAT 'DEMO
{' To Run Demo, Comment this line out with a single quote

OBJ 'DEMO, Needed for DEMO only
      DSP1  : "wa0uwh_DSPL_01"
      DSP2  : "wa0uwh_DSPL_01"

VAR 'DEMO, Needed for DEMO only
     Long Contrast, BackLight, SpkrVol

PUB Demo | okay,LIOKey, DspKey1, DspKey2, i, j, k, Pot0, Pot1, Pot2, Pot3

      Contrast  := 10  'Set Default Contrast
      Backlight := 92  'Set Default Backlight
      SpkrVol   := 32  'Set Default Speaker Volume

      LioKey := DspKey1 := DspKey2 := 0
      'locknew

      I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)

      DspKey1 := DSP1.StartDspVGA(locknew+1, 32, 15)

      DspKey2 := DSP2.StartDspI2C(locknew+1, 16, 2)

      i := j := k := -1       'Loop Counters

      DSP1.ClearStr(string("DEBUG"))

      DSP1.Lock
        DSP1.ClearStr(string("POT Demo:"))
      DSP1.unLock

      DSP2.Lock
        DSP2.ClearStr(string("POT Demo:"))
      DSP2.unLock

      LioKey  := Start(locknew+1, 0)

      PauseSec(2)
      DSP1.Lock
        DSP1.ClearStr(string("Start POT Devs:"))
      DSP1.unLock

      if True
        pauseSec(1)
        DSP1.lock
          DSP1.ClearStr(string("POT:"))
          DSP1.XyStr(1,4,string("LK="))   'Local Key
          DSP1.Dec(GetLockNum)
          DSP1.newline
          DSP1.Str(string("DspKey1="))         'Display Key
          DSP1.Dec(DspKey1)
          DSP1.Space
          DSP1.Str(string("DspLobj1="))         'Display Key
          DSP1.Dec(DSP1.GetLockNum)
          DSP1.space
          DSP1.Str(string("DspType1="))         'Display Type
          DSP1.Dec(DSP1.GetDSPLType)

          DSP1.newline
          DSP1.Str(string("DspKey2="))         'Display Key
          DSP1.Dec(DspKey2)
          DSP1.space
          DSP1.Str(string("DspLobj2="))         'Display Type
          DSP1.Dec(DSP2.GetLockNum)
          DSP1.space
          DSP1.Str(string("DspType2="))         'Display Type
          DSP1.Dec(DSP2.GetDSPLType)
        DSP1.unlock

        DSP2.lock
          DSP2.ClearStr(string("POT:"))
        DSP2.unlock


        repeat
          i++
          'get POT Wiper Values
          ifnot i//10 - 5
             Pot0 := getWiper(WIPER0)
             Pot1 := getWiper(WIPER1)
             Pot2 := getWiper(WIPER2)
             Pot3 := getWiper(WIPER3)
          else


          'DEBUG
          ifnot i//10 - 6
             'Display Knobs and Button Counters
              DSP1.Lock
                DSP1.XyRjDec(10,1, i//1000, 4, " ")
                DSP1.moveto(1,2)
                DSP1.str(string("BKL="))
                DSP1.rjdec(BackLight,3," ")
                DSP1.str(string(", CONT="))
                DSP1.rjdec(Contrast,3," ")
                DSP1.str(string(", VOL="))
                DSP1.rjdec(SpkrVol,3," ")
              DSP1.UnLock

              DSP2.Lock
                DSP2.XyRjDec(10,1, i//1000, 4, " ")
                DSP2.moveto(1,2)
                DSP2.str(string("B"))
                DSP2.rjdec(BackLight,3," ")
                DSP2.str(string(",C"))
                DSP2.rjdec(Contrast,3," ")
                DSP2.str(string(",V"))
                DSP2.rjdec(SpkrVol,3," ")
              DSP2.UnLock
        'Loop


'}
DAT
VAR 'STARTS
PUB Start(key, addr) | okay
      Startx(key, addr, 0 ,0)

PUB Startx(key, addr, scl, sda) | okay

      ifnot (scl or sda)
        I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)
      else
        I2C.Init(scl, sda)

      RESULT := LIO.StartLock(key)
      StartLock(0)
      StartQPot(addr)

DAT
PUB StartQPot(addr)

      ifnot addr
         addr := DEF_Addr0
      QPotAddr :=  addr

      '$FF = All POT Ports On
      putbyte(TCON0, $FF)
      putbyte(TCON1, $FF)

DAT
VAR 'SET POT WIPER For MCP4441 Quad Devices,
PUB setWiper(reg, val) 'Quad POT Wiper Control
      return putbyte(reg, val #>0 <#128)

PUB getWiper(reg) | tmp 'Quad POT Wiper Control
      return getword(reg | $0C) >> 8

VAR 'LOW LEVEL I2C TRANSFERS
PUB getbyte(reg) 'Low Level I2C Data Transfer
    LIO.Lock
      RESULT := I2C.getbyte(QPotAddr, reg)
    LIO.unLock
    return

DAT
PUB putbyte(reg, val) 'Low Level I2C Data Transfer
    LIO.Lock
      RESULT := I2C.putbyte(QPotAddr, reg, val)
    LIO.unLock
    return

DAT
PUB getword(reg) 'Low Level I2C Data Transfer
    LIO.Lock
      RESULT := I2C.getword(QPotAddr, reg)
    LIO.unLock
    return

DAT
PUB putword(reg, val) 'Low Level I2C Data Transfer
    LIO.Lock
      RESULT := I2C.putword(QPotAddr, reg, val)
    LIO.unLock
    return

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

PUB getLockNum
     return LOBJ.getLockNum

VAR 'Simple DEBUG Return Value
PUB DeBug
     return LIO.GetLockNum   'Change this to anything of DEBUG interest !

VAR 'PAUSE
PRI pauseSec(sec)
      pause(1000 * sec)

PRI pause(ms)
      waitcnt(((clkfreq / 1_000 * ms - 3932) #> WMin) + cnt)

VAR 'END
