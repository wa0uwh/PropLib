CON
{{
   This Object Suports the NHD‐C0220BiZ I2C LCD

   FileName: wa0uwh_NHD_C0220BiZ_LCD
   Author:   Eldon Brown - WA0UWH
   Date:     Jun 26, 2012
   REV:      0.01
}}

CON
   WMin     =       381        'WAITCNT-expression-overhead Minimum

   CLKSRC = 1 '*2    'Comment out the "*2" for 5MHz Cystal, UnComment for 10MHz TCVCXO
   _CLKMODE = XTAL1 * CLKSRC * CLKSRC + PLL16X / CLKSRC
   _XINFREQ = 5_000_000 * CLKSRC

CON

    DEF_NHD_C0220BiZ_Addr = $3C << 1
    DEF_COLS    = 20
    DEF_LINES   = 2
    DSPL_Type   = 4

    CMD_REG     = $80
    DAT_REG     = $40

    CMD_CLEAR   = $01
    CMD_HOME    = $02
    DSP_OFF     = $08
    DSP_ON      = $08 | $04
    DSP_CUR_OFF = DSP_ON
    INSERT_MODE = $04

OBJ
     I2C     : "jm_I2c"
     LSTDO   : "wa0uwh_Lock_01" 'Lock Standard Out
     LSTDI   : "wa0uwh_Lock_01" 'Lock Standard In

VAR
     Long NHD_C0220_Addr
     Long COLS, LINES

DAT 'DEMO
{   To Run Demo, Comment this line out with a single quote as the first character

PUB demo | dspKey, okay, i

    i := 0

    Startx3(locknew+1, 32 ,15)

    Str(string("DEBUG"))

    dspKey := Start(locknew+1)

    Cursor(2)
    Clear
    repeat
       i++
       Lock
         Home
         Str(string("START"))
         Out("-")
         Dec(i)
         Out("-")
         Str(string("END"))
         PauseMS(50)
       UnLock

'}
VAR 'START DISPALYs
PUB Start(key) | okay
{{
    Simple Start: with; will use Defaults except for Locking Key
}}
      Startx6(key, 0, 0, 0, 0, 0)

PUB Startx3(key, _cols, _lines) | okay
{{
    Simple Start: with; Key, Cols, and Lines,  will use Defaults for Others
}}
      Startx6(key, _cols, _lines, 0, 0, 0)


PUB Startx6(key, _cols, _lines, _addr, _scl, _sda) | okay
{{
    Full Start: Fully Qualified
}}
      ifnot _cols
        _cols := DEF_COLS
      COLS := _cols

      ifnot _lines
        _lines := DEF_LINES
      LINES := _lines

      ifnot _addr
        _addr := DEF_NHD_C0220BiZ_Addr
      NHD_C0220_Addr := _addr

      ifnot _scl and _sda
        I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)
      else
        I2C.Init(_scl,_sda)


      RESULT := LSTDO.StartLock(key)

      StartLock(0)

      InitDisplay

      return

PRI InitDisplay
{{
    Init The Display
    Power On Restart, may still be necessary if mangled :-(
}}

       CMD($38)
       PauseMS(10)
       CMD($39)
       PauseMS(10)
       CMD($14)
       CMD($78)
       CMD($5E)
       CMD($6D)
       CMD($0C)
       CMD($01)
       CMD($06)
       PauseMS(10)

     return Clear

VAR 'I2C OPS - Designed to Use as Few I/O Functions as Possible
PUB OutBuf(reg, len, data)
        LSTDO.Lock  'Lock Standard Output
          RESULT := I2C.putpage(NHD_C0220_Addr, reg, len, data)
        LSTDO.unLock

PUB CMD(data)
        return OutBuf(CMD_REG, 1, @data)

PUB Out(data)
        return OutBuf(DAT_REG, 1, @data)

VAR 'DISPLAY OPS - Designed to Use as Few Display Functions as Possible
PUB Clear
        return CMD(CMD_CLEAR) 'Home and Clear

PUB Home
        return CMD(CMD_HOME)

PUB Cursor(mode)
{{
    0 = OFF, 1 = Block, 2 = Underline, 3 = Both
}}
      return CMD(DSP_CUR_OFF + (||mode #> 0 <# 3) )

PUB Insert(mode)
{{
    ########### NOT WORKING YET ################
    0 = OVERSTRIKE, 1 = ???, 2 = ???, 3 = ???
}}
      return CMD(INSERT_MODE + (||mode #> 0 <# 3) )

PUB MoveTo(x, y)
{{
    Using Base 1, Home = 1,1
}}
      return CMD($80 | ((x-1) + (y-1) * $40))


PUB BlOn  'A NoOp, The Back Light Function must be supported with other Hardware

PUB BlOff 'A NoOp

VAR 'STRING Format, for Zero Terminated Strings
PUB Str(pstr)
      return OutBuf(DAT_REG, strsize(pstr), pstr)

VAR 'BIN Formats
PUB Bin(val, digits)
      val <<= (32 - digits)
      repeat digits
        Out((val <-= 1) & 1 + "0")

DAT
PUB RjBin(val, width, digits, padchar)
      if digits => 0 and (width => digits)
         repeat (width - digits)
           Out(padchar)
         Bin(val, digits)
      else
         repeat width
           Out("*")

VAR 'HEX Formats
PUB Hex(val, digits)
      val <<= (8 - digits) << 2
      repeat digits
        Out(lookupz((val <-= 4) & $F : "0".."9", "A".."F"))

DAT
PUB RjHex(val, width, digits, padchar)
      if digits => 0 and (width => digits)
         repeat (width - digits)
           Out(padchar)
         Hex(val, digits)
      else
         repeat width
           Out("*")

VAR 'DEC Formats
PUB Dec(val) | i, x
      x := val == negx
      if val < 0
        val := ||(val+x)
        Out("-")

      i := 1_000_000_000

      repeat 10
        if val => i
          Out(val / i + "0" + x*(i == 1))
          val //= i
          result~~
        elseif result or (i == 1)
          Out("0")
        i /= 10

DAT
PUB RjDec(val, width, padchar) | L
      L := 1
      repeat width
        L *= 10
      if val => -(L/10-1) AND val =< L-1
         RjDec_aux(val, width, padchar)
      else
         repeat width
           Out("*")

PRI RjDec_aux(val, width, padchar) | tmpval, pad
{{
      Print right-justified decimal value
      -- val is value to print
      -- width is width of (padded) field for value

      Original code by Dave Hein

      Use: RjDec(x, 3, "0") --> "001"
           RjDec(x, 3, " ") --> "  1"
}}
      if val => 0
        tmpval := val
        pad := width - 1
      else
        tmpval := -val
        pad := width - 2

      repeat while (tmpval => 10)
        pad--
        tmpval /= 10

      repeat pad
        Out(padchar)

      Dec(val)

VAR 'Simple LOCK LOBJ
PUB StartLock(num)
{{
      Processor provided Lock 'num' (1 - 8) to use if sharing resources.
      Use -1 to request a new lock number.
      Use 0 to not use Locks
      This Lock is used to prevent multiple COGs from mangling resources.
}}
     return LSTDI.StartLock(num)

PUB Lock
     return LSTDI.Lock

PUB UnLock
     return LSTDI.UnLock

PUB GetLockStat
     return LSTDI.GetLockStat

PUB GetLockNum
     return LSTDI.GetLockNum

PUB GetDsplType
      return DSPL_Type

VAR 'Simple DEBUG Return Value
PUB DeBug
     return COLS   'Change this to anything of DEBUG interest !

VAR 'PAUSE
PRI PauseSec(sec)
      PauseMS(1000 * sec)

PRI PauseMS(ms)
      waitcnt(((clkfreq / 1_000 * ms - 3932) #> WMin) + cnt)

VAR 'END
