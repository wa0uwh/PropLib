CON
{{
     WA0UWH - MCP4018  - A Single POT

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
    'Max of One MCP4018 POT / I2C Bus
    DEF_Addr0    = $2F << 1
    DEF_PotValue = $3F

OBJ
      I2C     : "jm_i2c"
      LIO     : "wa0uwh_Lock_01"
      LOBJ    : "wa0uwh_Lock_01"

VAR
     Long PotAddr

DAT 'DEMO
'{' To Run Demo, Comment this line out with a single quote

OBJ 'DEMO, Needed for DEMO only
      DSP1  : "wa0uwh_DSPL_01"
      DSP2  : "wa0uwh_DSPL_01"

VAR 'DEMO, Needed for DEMO only
PUB Demo | okay, I2CKey, DspKey1, DspKey2, i, j, k, Value

      I2CKey := DspKey1 := DspKey2 := 0

      I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)

      I2CKey  := Start(locknew+1, 0)              'Must be before other I2C commands

      DspKey1 := DSP1.StartDspVGA(locknew+1, 32, 15)

      DspKey2 := DSP2.StartDspI2C(I2CKey, 16, 2)

      i := j := k := -1       'Loop Counters

      DSP1.ClearStr(string("DEBUG"))

      DSP1.Lock
        DSP1.ClearStr(string("POT Demo:"))
      DSP1.unLock

      DSP2.Lock
        DSP2.ClearStr(string("POT Demo:"))
      DSP2.unLock


      PauseSec(2)
      DSP1.Lock
        DSP1.ClearStr(string("Start POT Lk:"))
        DSP1.RjDec(I2CKey, 2, " ")
      DSP1.unLock

      DSP2.Lock
        DSP2.ClearStr(string("Start POT Lk:"))
        DSP2.RjDec(I2CKey, 2, " ")
      DSP2.unLock

      repeat
        i++

        Value := i//128
        setWiper(Value)

        DSP1.Lock
          DSP1.XyStr(1,2, string("W="))
          DSP1.RjDec(Value, 4, " ")

          DSP1.XyStr(8,2, string("R="))
          DSP1.RjDec(getbyte, 4, " ")
        DSP1.UnLock

        DSP2.Lock
          DSP2.XyStr(1,2, string("W="))
          DSP2.RjDec(Value, 4, " ")

          DSP2.XyStr(8,2, string("R="))
          DSP2.RjDec(getbyte, 4, " ")
        DSP2.UnLock
      'Loop


'}
DAT
VAR 'STARTS
PUB Start(key, addr) | okay

      I2C.Init(I2C#BOOT_SCL, I2C#BOOT_SDA)

      ifnot addr
        addr := DEF_Addr0
      PotAddr :=  addr

      RESULT := LIO.StartLock(key)
      StartLock(0)

DAT

VAR 'SET POT WIPER For MCP4018
PUB setWiper(value) 'POT Wiper Control
      return putbyte(value)

PUB getWiper 'POT Wiper Control
      return  getbyte

VAR 'LOW LEVEL I2C ROUTINES
PUB putbyte(value) | ackbit

'' Write byte to device, Immediate (no reg address)
'' --   id : device slave id

  ackbit := putpage(PotAddr, 1, @value)

  return ackbit



Pri putpage(id,  n, src) | ackbit

'' Write n bytes from src to device without reg addressing
'' --   id : device slave id
'' --    n : bytes to write
'' --  src : pointer to source valuee
''
'' Be mindful of address/page size in device to prevent page wrap-around
  'LIO.Lock
    I2C.wait(id)
    ackbit := I2C#ACK                                             ' assume okay
    repeat n
      ackbit |= I2C.write(byte[src++])                            ' write a byte
    I2C.stop
 ' LIO.UnLock

  return ackbit



PUB getbyte | value

'' Read byte from device without reg addressing
'' --   id : device slave id

  getpage(PotAddr, 1, @value)

  return value & $0000_00FF



PRI getpage(id, n, dest)

'' Read n bytes from device, Immediate with no reg Address; output to dest
'' --   id : device slave id (e.g., $A0 for EEPROM)
'' --    n : bytes to read
'' -- dest : pointer to the destination
''
'' Be mindful of address/page size in device to prevent page wrap-around
  'LIO.Lock
    I2C.wait(id)
    I2C.start                                                         ' restart for read
    I2C.write(id | $01)                                               ' device read
    repeat while (n > 1)
      byte[dest++] := I2C.read(I2C#ACK)
      --n
    byte[dest] := I2C.read(I2C#NAK)                                   ' last byte gets NAK
    I2C.stop
  'LIO.UnLock


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
     return LOBJ.Debug   'Change this to anything of DEBUG interest !

VAR 'PAUSE
PRI pauseSec(sec)
      pause(1000 * sec)

PRI pause(ms)
      waitcnt(((clkfreq / 1_000 * ms - 3932) #> WMin) + cnt)

VAR 'END
