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

    SpkrPin = 20
    'SpkrPin = 5

CON
    'Display Types and Sets Maximum Lock Types
    #0, NULL_Type, I2C_Type, PAR_Type, VGA_Type, MAX_Lock_Types

OBJ
     LCD    : "ko7mLCD_EldonFixRmd"
     VGA    : "vga_text"
     LIO    : "wa0uwh_Lock_01"
     LOBJ   : "wa0uwh_Lock_01"

VAR
     Long DSPL_Enabled
     Long DSPL_Type

DAT 'DEMO
'{' To Run Demo, Comment this line out with a single quote

    ProgName BYTE "Clock", 0

PUB demo | dspKey, okay, i, t
     t := i := 0

     'dspKey := StartDspVGA(locknew+1, 32, 15)
     dspKey := StartDspI2C(locknew+1, 16, 2)

    lock
       ClearStr(string("Dsp Init:"))
       XyStr(1,2,string("LK=")) 'A Local Lock
       Dec(getLockNum)
       Space
       Str(string("DK="))  'A Display Lock
       Dec(dspKey)
    UnLock

    repeat
      i++
      lock
         XyRjDec(11,1, i//1000, 4, " ")
         XyStr(11,2,string("DB="))  'A Display Debug Info
         't := LCD.GetLockStat
         t := LCD.DeBug
         Dec(t)
         PauseMS(200)
       UnLock


'}
VAR 'START DISPALYs
PUB StartDspI2C(key, cols, lines)
      DSPL_Enabled := True
      DSPL_Type := I2C_Type
      RESULT := LIO.StartLock(key)
      'LCD.begin(LCD#driverModeI2C, key, cols, lines)
      LCD.begin(LCD#driverModeI2C, key, cols, lines)
      return

PUB StartDspPAR(key, cols, lines)
      DSPL_Enabled := True
      DSPL_Type := PAR_Type
      RESULT := LIO.StartLock(key)
      'LCD.begin(LCD#driverModeParallel, key, cols, lines)
      LCD.begin(LCD#driverModeParallel, key, cols, lines)
      return

PUB StartDspVGA(key, cols, lines)
      DSPL_Enabled := True
      DSPL_Type := VGA_Type
      RESULT := LIO.StartLock(key)
      VGA.start(16)
      return

PUB StartDspNull
      DSPL_Enabled := False
      DSPL_Type := NULL_Type
      return 0

PUB StartxJm
      'LCD.Startx(LCD_BL, LCD_E, LCD_RW, LCD_RS ,LCD_DB4, LCD_COLS, LCD_ROWS)

VAR 'DISPLAY OPS
PUB Clear
     if DSPL_Enabled
        case DSPL_Type
          I2C_Type, PAR_Type:
            LCD.Clear
          VGA_Type:
            VGA.Out($00)

PUB Clear2LinEnd(x,y)
     if DSPL_Enabled
        MoveTo(x,y)
        case DSPL_Type
          I2C_Type, PAR_Type:
            repeat 16 - x
              LCD.Out(" ")
          VGA_Type:
            repeat 32 - x
              VGA.Out(" ")
        MoveTo(x,y)

PUB Out(data)
     if DSPL_Enabled
        case DSPL_Type
          I2C_Type, PAR_Type:
            LCD.Out(data)
          VGA_Type:
            VGA.Out(data)

PUB Cursor(mode)
     if DSPL_Enabled
        case DSPL_Type
          I2C_Type, PAR_Type:
            LCD.cursor(mode)
          VGA_Type:

PUB Comma
     out(",")

PUB Space
     out(" ")

PUB CommaSpace
      Comma
      Space

PUB Newline
     if DSPL_Enabled
        case DSPL_Type
          I2C_Type, PAR_Type:
          VGA_Type:
            VGA.Out($0D)

PUB MoveTo(x,y)
     if DSPL_Enabled
        case DSPL_Type
          I2C_Type, PAR_Type: ' Base 1
            LCD.MoveTo(x,y)
          VGA_Type: ' Convert Base1 to Base0, as needed for VGA
            VGA.Out($0A)
            VGA.Out(x - 1)
            VGA.Out($0B)
            VGA.Out(y - 1)

PUB BlOn
     if DSPL_Enabled
        case DSPL_Type
          I2C_Type, PAR_Type:
            LCD.BlOn
          VGA_Type:


PUB BlOff
     if DSPL_Enabled
        case DSPL_Type
          I2C_Type, PAR_Type:
            LCD.BlOff
          VGA_Type:

VAR 'BIN Formats
PUB Bin(value, digits)
     if DSPL_Enabled
        case DSPL_Type
          I2C_Type, PAR_Type:
            LCD.bin(value, digits)
          VGA_Type:
            VGA.bin(value, digits)

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
      if DSPL_Enabled
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
     if DSPL_Enabled
        case DSPL_Type
          I2C_Type, PAR_Type:
            LCD.hex(val, digits)
          VGA_Type:
            VGA.hex(val, digits)

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
      if DSPL_Enabled
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
     if DSPL_Enabled
        case DSPL_Type
          I2C_Type, PAR_Type:
            LCD.Str(pstr)
          VGA_Type:
            VGA.Str(pstr)

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
PUB Dec(val)
     if DSPL_Enabled
        case DSPL_Type
          I2C_Type, PAR_Type:
            LCD.Dec(val)
          VGA_Type:
             VGA.Dec(val)

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
      if DSPL_Enabled
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

VAR 'Simple LOCK THIS
PUB StartLock(num)
      'Processor provided Lock 'num' (1 - 8) to use if sharing resources.
      'Use -1 to request a new lock number.
      'This Lock is used to prevent multiple COGs from mangling resources.
     return LOBJ.StartLock(num)

PUB Lock
     return LOBJ.Lock

PUB UnLock
     return LOBJ.UnLock

PUB GetLockStat
     return LOBJ.GetLockStat

PUB GetLockNum
     return LOBJ.GetLockNum

PUB GetDsplType
      return DSPL_Type

VAR 'Simple DEBUG Return Value
PUB DeBug
     return LCD.Debug   'Change this to anything of DEBUG interest !

VAR 'PAUSE
PRI PauseSec(sec)
      PauseMS(1000 * sec)

PUB PauseMS(ms)
      waitcnt(((clkfreq / 1_000 * ms - 3932) #> WMin) + cnt)

VAR 'END
