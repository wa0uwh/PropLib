CON
{{
     This Object Provides LEDs, using
     WA0UWH's - Propeller USB ProtoBoard UI and Supporting Objects

     FileName: wa0uwh_LED_01.spin
     Author:   Eldon R. Brown - WA0UWH
     Date:     Jun 11, 2011
     Rev:      0.01

     The UI contains the following peripherals
     1. Eight LEDs for user feedback)

}}

CON
    WMin = 381

    CLKSRC = 1 '*2    'Comment out the "*2" for 5MHz Cystal, UnComment for 10MHz TCVCXO
    _CLKMODE = XTAL1 * CLKSRC * CLKSRC + PLL16X / CLKSRC
    _XINFREQ = 5_000_000 * CLKSRC

CON
    'LED's Driven by Expander
    #0, RedR, BluR,   RedL, BluL, GrnR, YelR, GrnL, YelL
    RedS = 1<<RedL | 1<<RedR
    BluS = 1<<BluL | 1<<BluR
    GrnS = 1<<GrnL | 1<<GrnR
    YelS = 1<<YelL | 1<<YelR

    DEF_WinkDur = 10

OBJ
      I2C     : "jm_i2c"
      EXP0    : "wa0uwh_MCP230XX_01"
      LIO     : "wa0uwh_Lock_01"
      LOBJ    : "wa0uwh_Lock_01"

VAR
     Long LioKey, Exp0Key

DAT 'DEMO
{' To Run Demo, Comment this line out with a single quote as the First Character

OBJ
     DSP1    : "wa0uwh_DSPL_01"
     DSP2    : "wa0uwh_DSPL_01"

PUB Demo |  Csync, i, j, k

      j := i := -1       'Loop Counters

      LioKey := Exp0Key := 0

      LioKey  := Start(Locknew+1, 0)  'Starts I2C Bus, must be before I2C Display

      DSP1.StartDspVGA(locknew+1, 32,15)
      DSP1.ClearStr(string("LED Demo:"))

      'DSP2.StartDspI2C(locknew+1, 32,15)
      DSP2.StartDspBiZ(locknew+1, 32,15)
      DSP2.ClearStr(string("LED Demo:"))


      Csync := cnt
      repeat 'Repeat the Rest of the Method Once a Second

        if CLKFREQ <  cnt - Csync 'Update only Once Each Second
          Csync += CLKFREQ
          j := 0

        i++
        ifnot i//10
          DSP1.XyRjDec(13,1,i//1000, 4, " ")
          DSP2.XyRjDec(13,1,i//1000, 4, " ")
        else

        'Busy Task, Blink LED's
        case j++
            k:=0: WinkOn(GrnL)
            k+=5: WinkOn(GrnR)
            k+=5: WinkOn(YelL)
            k+=5: WinkOn(YelR)

            k+=5: WinkOn(RedL)
            k+=5: WinkOn(RedR)
            k+=5: WinkOn(BluL)
            k+=5: WinkOn(BluR)
            k+=5: WinkOn(BluL)
            k+=5: WinkOn(BluR)
       'case_end
       'Loop

'}
DAT
VAR 'STARTS
PUB Start(key, addr)

      RESULT := StartI2C(key)

      StartEXP0(key, addr)

      StartLock(0)
      return

PUB StartI2C(key) | okay

      I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)

      RESULT := LIO.StartLock(key)
      return


PUB StartEXP0(key, addr)

      'Expander #0
      ifnot addr
        addr := EXP0#DEF_Addr0

      RESULT := EXP0.Start(key, addr)

      EXP0.putbyte(EXP0#IOCON, $80)    'Set for Dual Bank(1) Mode

      'Connected to the LEDs
      EXP0.putbyte(EXP0#IODIRB,$00)    'Set for Output
      EXP0.putbyte(EXP0#OLATB,!$00)    'Clear Output Latch (neg true logic)

      return

VAR 'LED CONTROL VIA EXPANDER
PUB On(ExpPin) 'LED Control via Dual I/O Expander
      return OnMask(1<<ExpPin)

PUB Off(ExpPin) 'LED Control via Dual I/O Expander
      return OffMask(1<<ExpPin)

DAT
PUB BlinkOn(pin, dur) 'LED Control via Dual I/O Expander
      On(pin)
      pauseMS(dur)
      Off(pin)

PUB BlinkOff(pin, dur) 'LED Control via Dual I/O Expander
      Off(pin)
      pauseMS(dur)
      On(pin)

DAT
PUB WinkOn(pin) 'LED Control via Dual I/O Expander
      BlinkOn(pin, DEF_WinkDur)

PUB WinkOff(pin) 'LED Control via Dual I/O Expander
      BlinkOff(pin, DEF_WinkDur)

DAT
PUB AllOn 'LED Control via Dual I/O Expander
      return OnMask($FF)

PUB AllOff 'LED Control via Dual I/O Expander
      return OffMask($FF)

DAT
PUB OnMask(mask) | Latched
        EXP0.putbyte(EXP0#IODIRB, 0)
        Latched := EXP0.getbyte(EXP0#OLATB) & ! mask
        RESULT := EXP0.putbyte(EXP0#OLATB, Latched)
      return

PUB OffMask(mask) : stat | Latched
        Latched := EXP0.getbyte(EXP0#OLATB) | mask
        RESULT := EXP0.putbyte(EXP0#OLATB, Latched)
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
