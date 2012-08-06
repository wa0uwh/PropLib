CON
{{
   This Object Provides Consistant Display Environment for User Prop Programs

   FileName: wa0uwh_dspl_01
   Author:   Eldon Brown - WA0UWH
   Date:     Jun 13, 2012
   REV:      0.01
}}

CON
   WMin     =       381        'WAITCNT-expression-overhead Minimum

   CLKSRC = 1 '*2    'Comment out the "*2" for 5MHz Cystal, UnComment for 10MHz TCVCXO
   _CLKMODE = XTAL1 * CLKSRC * CLKSRC + PLL16X / CLKSRC
   _XINFREQ = 5_000_000 * CLKSRC

CON
    'Display Types and Sets Maximum Lock Types
    #0, NULL_Type, PARLCD_Type, I2CLCD_Type,
        PAR_Type, VGA_Type, BiZ_Type, MAX_Lock_Types

CON
    ' PAR LCD Info
    #16, PARLCD_RS, PARLCD_RW, PARLCD_E, PARLCD_BL
    #12, PARLCD_DB4

OBJ
     'I2CLCD   : "ko7mLCD.orig"
     I2CLCD    : "ko7mLCD_LockMod"
     PARLCD    : "jm_LCD4_ez"
     BiZ       : "wa0uwh_NHD_C0220BiZ_LCD_01"
     VGA       : "vga_text"

     LSTDO     : "wa0uwh_Lock_01"    'Lock Standard Output
     LSTDI     : "wa0uwh_Lock_01"    'Lock Standard Input

VAR
     Long DSPL_Enabled
     Long DSPL_Type
     Byte LineBuf[81]

DAT 'DEMO
{ To Run Demo, Comment this line out with a single quote as the first character

    ProgName BYTE "DSPL", 0

PUB demo | dspKey, C, i, PrevI, okay

     PrevI := i := 0

     'dspKey := StartDspNUL(-1, 16, 2)
     'dspKey := StartDspPAR(-1, 16, 2)
     'dspKey := StartDspI2C(-1, 16, 2)
     'dspKey := StartDspVGA(-1, 16, 2)
     dspKey := StartDspBiZ(-1, 16, 2)

     Clear
     Color(0)
     C := cnt
     repeat
       i++
       XyRjDec(7,1, i//1000, 4, " ") ' Display Loop Counter
       Lock
         Home
         Str(@ProgName)
         Colon
         XyStr(1,2,string("LK=")) 'A Local Lock
         Dec(getLockNum)
         Space
         Str(string("DK="))  'A Display Lock
         Dec(dspKey)
         Space
         Str(string("CK="))  'A Display Lock Status
         Dec(GetLockStat)
         'Clear2LinEnd(8,2)
       UnLock

       'Compute and Display the Display Frame Rate
       if (cnt - C < CLKFREQ)
         C += CLKFREQ
         Lock
           XyRjDec(11,1, i - PrevI, 4, " ") ' Display Loop Counter Update Rate
           PrevI := i
         UnLock


'}
VAR 'START DISPALYs
PUB StartDspPAR(key, cols, lines)
      'Note: key is not used, it is just a place holder
      DSPL_Enabled := True
      DSPL_Type := PARLCD_Type
      RESULT := LSTDI.StartLock(-1)
      PARLCD.Startx(PARLCD_BL, PARLCD_E, PARLCD_RW, PARLCD_RS, PARLCD_DB4, cols, lines)
      return

PUB StartDspI2C(key, cols, lines)
      DSPL_Enabled := True
      DSPL_Type := I2CLCD_Type
      RESULT := LSTDI.StartLock(-1)
      I2CLCD.begin(I2CLCD#driverModeI2C, key, cols, lines)
      return

PUB StartDspVGA(key, cols, lines)
      'Note: key is not used, it is just a place holder
      DSPL_Enabled := True
      DSPL_Type := VGA_Type
      RESULT := LSTDI.StartLock(-1)
      VGA.Start(16)
      return

PUB StartDspBiZ(key, cols, lines)
      DSPL_Enabled := True
      DSPL_Type := BiZ_Type
      RESULT := LSTDI.StartLock(-1)
      BiZ.Start(key)
      return

PUB StartDspNUL(key, cols, lines)
      'Note: Args are not used, they are just place holders
      DSPL_Enabled := False
      DSPL_Type := NULL_Type
      return 0

VAR 'DISPLAY OPS - Using as Few Display Functions as Possible
PUB Clear
      ifnot DSPL_Enabled
        return
      case DSPL_Type
        PARLCD_Type:
          PARLCD.Out(PARLCD#CLS)
        I2CLCD_Type:
          I2CLCD.Clear
        BiZ_Type:
          BiZ.Clear
        VGA_Type:
          VGA.Out($00)

PUB Home
      ifnot DSPL_Enabled
        return
      case DSPL_Type
        PARLCD_Type:
          PARLCD.Out(PARLCD#CHOME)
        I2CLCD_Type:
          I2CLCD.Home
        BiZ_Type:
          BiZ.Home
        VGA_Type:
          VGA.Out($01)

PUB Color(data)
      ifnot DSPL_Enabled
        return
      case DSPL_Type
        PARLCD_Type: 'NoOp
        I2CLCD_Type: 'NoOp
        BiZ_Type:    'NoOp
        VGA_Type:
          VGA.Out($0C)
          VGA.Out(data)

PUB Out(data)
      ifnot DSPL_Enabled
        return
      case DSPL_Type
        PARLCD_Type:
          PARLCD.Out(data)
        I2CLCD_Type:
          I2CLCD.Out(data)
        BiZ_Type:
          BiZ.Out(data)
        VGA_Type:
          VGA.Out(data)

PUB Cursor(mode)
      ifnot DSPL_Enabled
        return
      case DSPL_Type
        PARLCD_Type:
          PARLCD.Out(mode)
        I2CLCD_Type:
          I2CLCD.Cursor(mode)
        BiZ_Type:
          BiZ.Cursor(mode)
        VGA_Type: 'NoOp

PUB MoveTo(x,y)
      ifnot DSPL_Enabled
        return
      case DSPL_Type
        PARLCD_Type: ' Base 1
          I2CLCD.MoveTo(x,y)
        I2CLCD_Type: ' Base 1
          I2CLCD.MoveTo(x,y)
        BiZ_Type: ' Base 1
          BiZ.MoveTo(x,y)
        VGA_Type: ' Convert Base1 to Base0, as needed for VGA
          VGA.Out($0A)
          VGA.Out(x - 1)
          VGA.Out($0B)
          VGA.Out(y - 1)

PUB BlOn
      ifnot DSPL_Enabled
        return
      case DSPL_Type
        PARLCD_Type:
          PARLCD.BlOn
        I2CLCD_Type:
          I2CLCD.BlOn
        BiZ_Type: 'NoOp
        VGA_Type: 'NoOp

PUB BlOff
      ifnot DSPL_Enabled
        return
      case DSPL_Type
        PARLCD_Type:
          PARLCD.BlOff
        I2CLCD_Type:
          I2CLCD.BlOff
        BiZ_Type: 'NoOp
        VGA_Type: 'NoOp

VAR 'FORMAT AIDS
PUB Clear2LinEnd(x,y)
      MoveTo(x,y)
      case DSPL_Type
        PARLCD_Type:
          repeat 16 - x + 1
            Out(" ")
        I2CLCD_Type:
          repeat 16 - x + 1
            Out(" ")
        BiZ_Type:
          repeat 20 - x + 1
            Out(" ")
        VGA_Type:
          repeat 32 - x + 1
            Out(" ")
      MoveTo(x,y)

PUB Comma
      Out(",")
PUB Colon
      Out(":")
PUB Slash
      Out("/")
PUB CommaSpace
      CSp
PUB CSp
      Comma
      Space
PUB Space
      SP
PUB SP
      Out(" ")
PUB Newline
      NL
PUB NL
     Out(13)

VAR 'BIN Formats
PUB Bin(val, digits)
      val <<= (32 - digits)
      repeat digits
        Out((val <-= 1) & 1 + "0")

PUB BinSufx(val, digits, psufx)
        Bin(val, digits)
        Str(psufx)

PUB XyBin(x, y, val, digits)
        MoveTo(x, y)
        Bin(val, digits)

PUB XyBinSufx(x, y, val, digits, psufx)
        XyBin(x, y, val, digits)
        Str(psufx)

PUB ClearXyBin(x, y, val, digits)
        Clear
        XyBin(x, y, val, digits)

PUB ClearXyBinSufx(x, y, val, digits, psufx)
        Clear
        XyBinSufx(x, y, val, digits, psufx)

DAT
PUB RjBin(val, width, digits, padchar)
      if digits => 0 and (width => digits)
         repeat (width - digits)
           Out(padchar)
         Bin(val, digits)
      else
         repeat width
           Out("*")

PUB RjBinSufx(val, width, digits, padchar, psufx)
        RjBin(val, width, digits, padchar)
        Str(psufx)

PUB ClearRjBinSufx(val, width, digits, padchar, psufx)
        Clear
        RjBinSufx(val, width, digits, padchar, psufx)

DAT
PUB XyRjBin(x, y, val, width, digits, padchar)
        MoveTo(x, y)
        RjBin(val, width, digits, padchar)

PUB XyRjBinSufx(x, y, val, width, digits, padchar, psufx)
        MoveTo(x, y)
        RjBinSufx(val, width, digits, padchar, psufx)

PUB ClearXyRjBin(x, y, val, width, digits, padchar)
        Clear
        XyRjBin(x, y, val, width, digits, padchar)

PUB ClearXyRjBinSufx(x, y, val, width, digits, padchar, psufx)
        Clear
        XyRjBinSufx(x, y, val, width, digits, padchar, psufx)

VAR 'HEX Formats
PUB Hex(val, digits)
      val <<= (8 - digits) << 2
      repeat digits
        Out(lookupz((val <-= 4) & $F : "0".."9", "A".."F"))

PUB HexSufx(val, digits, psufx)
        Hex(val, digits)
        Str(psufx)

PUB XyHex(x, y, val, digits)
        MoveTo(x, y)
        hex(val, digits)

PUB XyHexSufx(x, y, val, digits, psufx)
        XyHex(x, y, val, digits)
        Str(psufx)

PUB ClearXyHex(x, y, val, digits)
        Clear
        XyHex(x, y, val, digits)

PUB ClearXyHexSufx(x, y, val, digits, psufx)
        Clear
        XyHexSufx(x, y, val, digits, psufx)

DAT
PUB RjHex(val, width, digits, padchar)
{{
    By: Eldon Brown - WA0UWH
    Augmented to Provide Field With Over-run Protection
}}
      if digits => 0 and (width => digits)
         repeat (width - digits)
           Out(padchar)
         Hex(val, digits)
      else
         repeat width
           Out("*")

PUB RjHexSufx(val, width, digits, padchar, psufx)
        RjHex(val, width, digits, padchar)
        Str(psufx)

PUB ClearRjHexSufx(val, width, digits, padchar, psufx)
        Clear
        RjHexSufx(val, width, digits, padchar, psufx)

DAT
PUB XyRjHex(x, y, val, width, digits, padchar)
        MoveTo(x, y)
        RjHex(val, width, digits, padchar)

PUB XyRjHexSufx(x, y, val, width, digits, padchar, psufx)
        MoveTo(x, y)
        RjHexSufx(val, width, digits, padchar, psufx)

PUB ClearXyRjHex(x, y, val, width, digits, padchar)
        Clear
        XyRjHex(x, y, val, width, digits, padchar)

PUB ClearXyRjHexSufx(x, y, val, width, digits, padchar, psufx)
        Clear
        XyRjHexSufx(x, y, val, width, digits, padchar, psufx)

VAR 'STRING Formats
PUB Str(pstr)
      repeat strsize(pstr)
        Out(byte[pstr++])

PUB Str2(pstr1, pstr2)
        Str(pstr1)
        Str(pstr2)

PUB ClearStr(pstr)
        Clear
        Str(pstr)

PUB ClearStr2(pstr1, pstr2)
        Clear
        Str2(pstr1,pstr2)

DAT
PUB XyStr(x, y, pstr)
        MoveTo(x, y)
        Str(pstr)

PUB XyStr2(x, y, pstr1, pstr2)
        MoveTo(x, y)
        Str2(pstr1, pstr2)

PUB ClearXyStr(x, y, pstr)
        Clear
        XyStr(x, y, pstr)

PUB ClearXyStr2(x, y, pstr1, pstr2)
        Clear
        XyStr2(x, y, pstr1, pstr2)

VAR 'DEC Formats
PUB Dec(val) | i, x
      x := val == negx
      if val < 0
        val := ||(val+x)
        out("-")

      i := 1_000_000_000

      repeat 10
        if val => i
          Out(val / i + "0" + x*(i == 1))
          val //= i
          result~~
        elseif result or (i == 1)
          Out("0")
        i /= 10

PUB DecSufx(val, psufx)
        Dec(val)
        Str(psufx)

PUB XyDec(x, y, val)
        MoveTo(x, y)
        dec(val)

PUB XyDecSufx(x, y, val, psufx)
        XyDec(x, y, val)
        Str(psufx)

PUB ClearXyDec(x, y, val)
        Clear
        XyDec(x, y, val)

PUB ClearXyDecSufx(x, y, val, psufx)
        Clear
        XyDecSufx(x, y, val, psufx)

DAT
PUB RjDec(val, width, padchar) | L
{{
    By: Eldon Brown - WA0UWH
    Provide Field With Over-run Protection
}}
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

PUB RjDecSufx(val, width, padchar, psufx)
        RjDec(val, width, padchar)
        Str(psufx)

PUB ClearRjDecSufx(val, width, padchar, psufx)
        Clear
        RjDecSufx(val, width, padchar, psufx)

DAT
PUB XyRjDec(x, y, val, width, padchar)
        MoveTo(x, y)
        RjDec(val, width, padchar)

PUB XyRjDecSufx(x, y, val, width, padchar, psufx)
        MoveTo(x, y)
        RjDecSufx(val, width, padchar, psufx)

PUB ClearXyRjDec(x, y, val, width, padchar)
        Clear
        XyRjDec(x, y, val, width, padchar)

PUB ClearXyRjDecSufx(x, y, val, width, padchar, psufx)
        Clear
        XyRjDecSufx(x, y, val, width, padchar, psufx)
VAR 'Simple LOCK LSTDI
PUB StartLock(num)
{{
      Processor provided Lock 'num' (1 - 8) to use if sharing resources.
      Use -1 to request a new lock number.
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
     return LSTDI.DeBug   'Change this to anything of DEBUG interest !

VAR 'PAUSE
PRI PauseSec(sec)
      PauseMS(1000 * sec)

PUB PauseMS(ms)
      waitcnt(((clkfreq / 1_000 * ms - 3932) #> WMin) + cnt)

VAR 'END
