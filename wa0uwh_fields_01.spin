CON
{{
    This is not working, it is just an Idea
}}

CON

   #0, FieldId, Type, Col, Row, Width, FillChar, Value, Sufix, Element
   @0, Dec, RjDec, Hex, RjHex, Bin, Str
   #0. Establish, Display

   MaxFields = 10

Var
   Long MaxID
   Byte Byte Buf[81]
   D[MaxFields * Elements]

PRI ExstablishField(_Type, _Col, _Row, _Width, _FillChar, _Value, _Sufix)
     RESULT := D[FieldID] := MaxID++
     D[Type]  := _Type
     D[Col]   := _Col
     D[Row]   := _Row
     D[Width] := _Width
     D[Field] := _FillChar
     D[Value] := _Value
     D[Sufix] := _Sufix

PRI DisplayField(D)
{{

}}

     DSPL.MoveTo(D[Col],D[Row])
     case Data[Type]
       Dec:   DSPL.Dec(D[Value])
       RjDec: DSPL.RjDec(D[Value], D[Width]. D[FillChar])
       Hex:   DSPL.Hex(D[Value], D[Width])
       RjHex: DSPL.RjHex(D[Value], D[Width], D[FillChar])
       Bin:   DSPL.Bin(D[Value], D[Width])
       Str:   DSPL.Str(D[Value])
     {case end}
     DSPL.Str(D[Sufix]) 'Null Terminated String
  {case end}


