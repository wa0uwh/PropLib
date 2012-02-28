CON

CON

    _CLKMODE = XTAL1 + PLL16X
    _XINFREQ = 5_000_000

    CLK_FREQ = ((_clkmode-xtal1)>>6)*_xinfreq
    MS_001 = CLK_FREQ / 1_000


CON

    EXP1addr  = $20 <<1 ' I2C Expander # 1
    IODIR     = $00     ' 1=Input, 0=Output
    GPIO      = $09     ' General I/O registor
    OLAT      = $0A     ' Latched I/O registor

    #0, RedL, BluL,   RedR, BluR
    RedS = 1<<RedL | 1<<RedR
    BluS = 1<<BluL | 1<<BluR

CON
    RTCaddr = $68 << 1
    #0, cSS, cMM, cHH, cWW, cDD, cLL, cYY   'LL = Lunar (or Month)

OBJ
        I2C : "jm_i2c"

PUB Demo | okay, stat, L
      Start

      DemoLCD

      repeat
          repeat L from 0 to 3
              repeat 10
                 stat := on(L)
                 pause(50)
                 'stat := off(L)
                 pause(50)

          pauseSec(2)

OBJ

      LCD : "jm_lcd4_ez"  ' Rev 1.4

CON
    ' LCD Info
    #16, LCD_RS, LCD_RW, LCD_E, LCD_BL
    #12, LCD_DB4, LCD_DB5, LCD_DB6, LCD_DB7
    #16, LCD_COLS
    #2,  LCD_ROWS

VAR
	LONG RTC, EXP1

PUB DemoLCD | okay, Sec

      LCD.Startx(LCD_BL, LCD_E, LCD_RW, LCD_RS ,LCD_DB4, LCD_COLS, LCD_ROWS)
      LCD.cmd(LCD#CLS)
      LCD.blon
      LCD.str(string("I2C Dev Demo:"))

      pauseSec(4)
      LCD.cmd(LCD#CLS)
      LCD.str(string("Running"))

      on(RedL)
      on(RedR)
      pauseSec(1)

      repeat

        LCD.moveto(1,2)
        Sec := getSec
        LCD.rjdec(Sec,4," ")

        pause(100)
        winkon(RedL)
        pause(100)
        winkon(RedR)
        pause(100)
        winkon(BluL)
        pause(100)
        winkon(BluR)

        pause(100)


DAT
PUB Start | okay

      RTC := RTCaddr
      EXP1 := EXP1addr

      I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)

      I2C.putbyte(EXP1, IODIR, 0)
      I2C.putbyte(EXP1, OLAT, $FF)

DAT
PUB on(pin)

    return onmask(1<<pin)

PUB onmask(mask) | Latched
    I2C.putbyte(EXP1, IODIR, 0)
    Latched := I2C.getbyte(EXP1, OLAT) & ! mask
    return I2C.putbyte(EXP1, OLAT, Latched)

DAT
PUB off(pin)

    return offmask(1<<pin)

PUB offmask(mask) : stat | Latched

    Latched := I2C.getbyte(EXP1, OLAT) | mask
    return I2C.putbyte(EXP1, OLAT, Latched)

DAT
PUB blinkon(pin, dur)
     on(pin)
     pause(dur)
     off(pin)

PUB blinkoff(pin, dur)
     off(pin)
     pause(dur)
     on(pin)

DAT
PUB winkon(pin)
     blinkon(pin, 30)

PUB winkoff(pin)
     blinkoff(pin, 30)

DAT
PUB allLEDon
    return onmask($FF)

PUB allLEDoff
    return offmask($FF)

OBJ
PUB setSec(_sec)
      RESULT := I2C.putbyte(RTC, cSS, (_sec/10)<<4 + (_sec // 10))

PUB setMin(_min)
      RESULT := I2C.putbyte(RTC, cMM, (_min/10)<<4 + (_min // 10))

PUB setHour(_hour)
      RESULT := I2C.putbyte(RTC, cHH, (_hour/10)<<4 + (_hour // 10))

PUB getSec
      RESULT := I2C.getbyte(RTC, cSS)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

PUB getMin
      RESULT := I2C.getbyte(RTC, cMM)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

PUB getHour
      RESULT := I2C.getbyte(RTC, cHH)
      RESULT := (10 * RESULT>>4) + (RESULT & $0F)

PUB getbyte(addr, reg)
      RESULT := I2C.getbyte(addr, reg)

DAT
PRI pauseSec(sec)
    pause(1000 * sec)

PRI pause(ms)  | t
    t := cnt - 1088             ' 1088 is Published Time for Overhead at 80mHz
    repeat ms
       waitcnt(t += MS_001)

DAT
