CON
{{
     WA0UWH - I2C MCP23008/17 Expander Support Object

     FileName: wa0uwh_MCP230XX_01.spin
     Author:   Eldon R. Brown - wa0uwh
     Date:     Jun 11, 2012
     REV:      0.1
}}

CON
    WMin = 381

    CLKSRC = 1 '*2    'Comment out the "*2" for 5MHz Cystal, UnComment for 10MHz TCVCXO
    _CLKMODE = XTAL1 * CLKSRC * CLKSRC + PLL16X / CLKSRC
    _XINFREQ = 5_000_000 * CLKSRC


CON 'Address for MCP23017 Dual 8bit and MCP23008 Single 8 Bit Expanders
    'Max Eight / I2C Circuit

    DEF_Addr0  = ($20 +0) <<1
    DEF_Addr1  = ($20 +1) <<1
    DEF_Addr2  = ($20 +2) <<1
    DEF_Addr3  = ($20 +3) <<1
    DEF_Addr4  = ($20 +4) <<1
    DEF_Addr5  = ($20 +5) <<1
    DEF_Addr6  = ($20 +6) <<1
    DEF_Addr7  = ($20 +7) <<1

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

OBJ
      I2C     : "jm_i2c"
      LIO     : "wa0uwh_Lock_01"
      LOBJ    : "wa0uwh_Lock_01"

VAR
     Long ExpAddr

DAT 'DEMO
{' To Run Demo, Comment this line out with a single quote as the first character

OBJ 'DEMO, Needed for DEMO only
      DSP1  : "wa0uwh_DSPL_01"
      DSP2  : "wa0uwh_DSPL_01"

PUB Demo | IOKey, DspKey1, DspKey2, okay, i, t

      i := 0

      I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)

      IOKey := Start(locknew+1, DEF_Addr0)

      DspKey1 := DSP1.StartDspVGA(locknew+1, 32, 15 )

      'DspKey2 := DSP2.StartDspI2C(locknew+1, 16, 2)
      DspKey2 := DSP2.StartDspBiZ(locknew+1, 20, 2)

      DSP1.Lock
        DSP1.ClearStr(string("I2C Exp Demo:"))
      DSP1.UnLock

      PauseSec(1)
      DSP1.Lock
        DSP1.ClearStr(string("I2C:"))
        DSP1.XyStr(1,2,string("LK="))   'Local Key
        DSP1.Dec(GetLockNum)
        DSP1.space
        DSP1.Str(string("DK="))         'Display Key
        DSP1.Dec(DSP1.GetLockNum)
        DSP1.space
        DSP1.Str(string("DT="))         'Display Type
        DSP1.Dec(DSP1.GetDSPLType)
      DSP1.UnLock

      PauseSec(3)

      putbyte(IOCON,  $80)    'Set for Dual Bank(1) Mode
      putbyte(IOCONA, $80)    'Set for Dual Bank(1) Mode (same as previous line only using Bank Reg)
      putbyte(IODIRA, $00)    'Set for Output
      putbyte(GPPUA,  $FF)    'Set for Pullup 10K
      putbyte(OLATA,  $00)    'Clear Output Latch

      DSP1.Lock
        DSP1.ClearStr(string("I2C Exp Demo:"))
      DSP1.UnLock

      DSP2.Lock
        DSP2.ClearStr(string("I2C Exp Demo:"))
      DSP2.UnLock

      repeat
        i++
        DSP1.Lock
          DSP1.XyStr(1,2, string("W="))
          DSP1.RjDec(i//256, 4, " ")
          putbyte(GPIOA, i//256)

          DSP1.XyStr(8,2, string("R="))
          DSP1.RjDec(getbyte(GPIOA), 4, " ")
        DSP1.UnLock

        DSP2.Lock
          DSP2.XyStr(1,2, string("W="))
          DSP2.RjDec(i//256, 4, " ")
          putbyte(GPIOA, i//256)

          DSP2.XyStr(8,2, string("R="))
          DSP2.RjDec(getbyte(GPIOA), 4, " ")
        DSP2.UnLock

        'PauseMS(50)
      'Loop

'}
DAT
VAR 'STARTS
PUB Start(key, addr) | okay
      Startx(key, addr, 0, 0)

PUB Startx(key, addr, scl, sda) | okay

      ifnot addr
        addr := DEF_Addr0
      ExpAddr := addr

      ifnot (scl or sda)
        I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)
      else
        I2C.Init(scl, sda)

      RESULT := LIO.StartLock(key)

      StartLock(0)

      return

DAT
VAR 'LOW LEVEL I2C TRANSFERS
PUB getbyte(reg) 'Low Level I2C Data Transfer
    LIO.Lock
      RESULT := I2C.getbyte(ExpAddr, reg)
    LIO.UnLock
    return

DAT
PUB putbyte(reg, val) 'Low Level I2C Data Transfer
    LIO.Lock
      RESULT := I2C.putbyte(ExpAddr, reg, val)
    LIO.UnLock
    return

DAT
PUB getword(reg) 'Low Level I2C Data Transfer
    LIO.Lock
      RESULT := I2C.getword(ExpAddr, reg)
    LIO.UnLock
    return

DAT
PUB putword(reg, val) 'Low Level I2C Data Transfer
    LIO.Lock
      RESULT := I2C.putword(ExpAddr, reg, val)
    LIO.UnLock
    return

VAR 'Simple LOCK SMITH
PRI StartLock(num)
     return LOBJ.StartLock(num)

PRI Lock
     return LOBJ.Lock

PRI UnLock
     return LOBJ.UnLock

PUB GetLockStat
     return LOBJ.GetLockStat

PUB GetLockNum
     return LOBJ.GetLockNum

VAR 'Simple DEBUG Return Value
PUB DeBug
     return LOBJ.DeBug

VAR 'PAUSE
PRI PauseSec(sec)
      pauseMS(1000 * sec)

PRI PauseMS(ms)
      waitcnt(((clkfreq / 1_000 * ms - 3932) #> WMin) + cnt)

VAR 'END
