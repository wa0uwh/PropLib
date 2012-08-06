CON
{{
     WA0UWH - Lock Object

     FileName: wa0uwh_Lock_01.spin
     Author:   Eldon R. Brown - WA0UWH
     Date:     Jun 11, 2011
     Rev:      0.01

}}

CON
    WMin = 381

    CLKSRC = 1 *2    'Comment out the "*2" for 5MHz Cystal, UnComment for 10MHz TCVCXO
    _CLKMODE = XTAL1 * CLKSRC * CLKSRC + PLL16X / CLKSRC
    _XINFREQ = 5_000_000 * CLKSRC


CON

    #16, LCD_RS, LCD_RW, LCD_E, LCD_BL
    #12, LCD_DB4, LCD_DB5, LCD_DB6, LCD_DB7
    #16, LCD_COLS
    #2,  LCD_ROWS

CON
    #(-1), LNEW, LCLR, LSET, LSTP, LCHK

CON
DAT 'DEMO
{' To Run Demo, Comment this line out with a single quote

OBJ 'DEMO, Needed for DEMO only
     'DSP1  : "wa0uwh_DSPL_01" 'Can NOT be used as it would be recursive
     DSP1   : "jm_lcd4_ez"

PUB Demo | LocKey, DspKey, i, j, k

      DspKey := 0
      DspKey := StartLock(locknew+1)

      'DspKey := DSP1.StartPAR(locknew+1, 16, 2 )
      DspKey := DSP1.Startx(LCD_BL,LCD_E,LCD_RW,LCD_RS,LCD_DB4,LCD_COLS,LCD_ROWS)
      DSP1.Cmd(DSP1#CLS)
      DSP1.BLon

      j := i := -1       'Loop Counters

      DSP1.Cmd(DSP1#CLS)
      DSP1.Str(string("DEBUG"))

      Lock)
        DSP1.Cmd(DSP1#CLS)
        DSP1.Str(string("Lock Demo:"))
      Unlock

      if True
        pauseSec(1)
        'lock
        Lock
          DSP1.moveto(1,2)
          DSP1.Str(string("DK="))
          DSP1.Dec(DspKey)
          DSP1.Str(string(", "))
          DSP1.Str(string("LK="))
          'DSP1.Dec(GetLockNum)
          DSP1.Dec(LockCheck)
        Unlock

        'Hang
        repeat
          waitcnt(cnt)


'}
DAT
'{
PUB LCMD(mode)   'A new Idea for locks
    case mode
      LNEW: return LockNum := locknew + 1
      LCLR: return unLock
      LSET: return Lock
      LSTP: return Stop
      LCHK: return GetLockStat
'}
VAR 'LOCKS
     Long LockNum, LockOwner 'Static Variable
PUB StartLock(num) | okay
{{
      Initialize LOCKs,
      Processor provided Lock 'num' (1 - 8) to be use for sharing resources.
      This Lock is used to prevent multiple COGs from mangling resources
      Use -1 to request a new lock number.
}}
       LockNum := num
       if LockNum < 0
          LockNum := locknew + 1
          if lockNum > 0
             LockOwner := True
       return LockNum

PUB Stop
      if LockNum > 0
        if LockOwner
          lockret(LockNum - 1)
          LockNum := -1
      return LockNum

DAT
PUB Lock 'Lock for I2C Bus
      if LockNum > 0
         repeat while RESULT := lockset(LockNum - 1)
      return

PUB UnLock
      if LockNum > 0
         RESULT := lockclr(LockNum - 1)
      return

PUB GetLockStat
{{
     THIS MAY NOT WORK AS PLANNED - MORE WORK NEEDED
     Returns:
       -1 == Lock does not exist
        0 == Lock is Clear
        1 == Lock is Set
}}
      RESULT := -1
      if LockNum > 0
        if RESULT := ||lockset(LockNum - 1)
           Lockclr(LockNum - 1)
      return

PUB GetLockNum
      return LockNum

VAR 'Simple DEBUG Return Value
PUB DeBug
     return LockNum   'Change this to anything of DEBUG interest !

VAR 'PAUSE
Pri PauseSec(sec)
      PauseMS(1000 * sec)

Pri PauseMS(ms)
      waitcnt(((clkfreq / 1_000 * ms - 3932) #> WMin) + cnt)

VAR 'END
