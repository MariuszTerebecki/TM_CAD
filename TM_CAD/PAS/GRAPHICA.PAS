
{ Moduà odpowiedzialny za grafik© wektorow• uæyt• w programie }

unit GraphicalObjects;

interface

uses
  Objects, Dos;

const
  grNone        = 0;
  grPoint       = 1;
  grLine        = 2;
  grRectangle   = 3;
  grCircle      = 4;
  grEllipse     = 5;
  grArc         = 6;
  grString      = 7;
  grCounter     = grString;

{ Obiekty graficzne sàuæ•ce do operacji na grafice wektorowej }

type
  PGraphObject = ^TGraphObject;
  TGraphObject = object(TObject)
    grNumber: Byte;
    X, Y: Integer;
    constructor Init(NewX, NewY: Integer);
    procedure Draw; virtual;
    constructor Load(var Stream: TStream);
    procedure Store(var Stream: TStream); virtual;
  end{TGraphObject};

  PGraphPoint = ^TGraphPoint;
  TGraphPoint = object(TGraphObject)
    constructor Init(NewX, NewY: Integer);
    procedure Draw; virtual;
  end{TGraphPoint};

  PGraphLine = ^TGraphLine;
  TGraphLine = object(TGraphObject)
    Xe, Ye: Integer;
    LineStyle, LineThick: Word;
    constructor Init(NewX, NewY, NewXe, NewYe: Integer; NewLineThick, NewLineStyle: Word);
    procedure Draw; virtual;
    constructor Load(var Stream: TStream);
    procedure Store(var Stream: TStream); virtual;
  end{TGraphLine};

  PGraphRectangle = ^TGraphRectangle;
  TGraphRectangle = object(TGraphLine)
    constructor Init(NewX, NewY, NewXe, NewYe: Integer; NewLineThick, NewLineStyle: Word);
    procedure Draw; virtual;
  end{TGraphRectangle};

  PGraphCircle = ^TGraphCircle;
  TGraphCircle = object(TGraphObject)
    Radius, LineThick: Word;
    constructor Init(NewX, NewY: Integer; NewRadius, NewLineThick: Word);
    procedure Draw; virtual;
    constructor Load(var Stream: TStream);
    procedure Store(var Stream: TStream); virtual;
  end{TGraphCircle};

  PGraphEllipse = ^TGraphEllipse;
  TGraphEllipse = object(TGraphObject)
    RadiusA, RadiusB: Word;
    LineThick: Word;
    constructor Init(NewX, NewY: Integer; NewRadiusA, NewRadiusB, NewLineThick: Word);
    procedure Draw; virtual;
    constructor Load(var Stream: TStream);
    procedure Store(var Stream: TStream); virtual;
  end{TGraphEllipse};

  PGraphArc = ^TGraphArc;
  TGraphArc = object(TGraphCircle)
    StAngle, EndAngle: Word;
    constructor Init(NewX, NewY: Integer; NewRadius, NewLineThick, NewStAngle, NewEndAngle: Word);
    procedure Draw; virtual;
    constructor Load(var Stream: TStream);
    procedure Store(var Stream: TStream); virtual;
  end{TGraphEllipse};

  PGraphString = ^TGraphString;
  TGraphString = object(TGraphObject)
    CharSize, LineStyle, LineThick, Direction: Word;
    Txt: string;
    constructor Init(NewX, NewY: Integer; NewCharSize, NewDirection: Word; NewTxt: string);
    procedure Draw; virtual;
    constructor Load(var Stream: TStream);
    procedure Store(var Stream: TStream); virtual;
  end{TGraphEllipse};

function NumberOfGraphType(GraphObject: PGraphObject): Byte;
function SaveTxt(GraphCollection: PCollection; FileName: PathStr): Integer;
function LoadTxt(var GraphCollection: PCollection; FileName: PathStr): Integer;

function Distanse(X1, Y1, X2, Y2: Integer): Word;
function VirtualX(X: Integer): Integer;
function VirtualY(Y: Integer): Integer;
function VirtualDistanse(Distanse: Integer): Integer;
function GetX(X: Integer): Integer;
function GetY(Y: Integer): Integer;
function GetDistanse(Distanse: Integer): Integer;

implementation

uses
  Graph;

constructor TGraphObject.Init;
begin
  grNumber := grNone;
  X := VirtualX(NewX);
  Y := VirtualY(NewY);
end{TGraphObject.Init};

procedure TGraphObject.Draw;
begin
  Abstract;
end{TGraphObject.Draw};

constructor TGraphObject.Load;
begin
  with Stream do
    begin
      Read(grNumber, SizeOf(grNumber));
      Read(X, SizeOf(X));
      Read(Y, SizeOf(Y));
    end{begin};
end{TGraphObject.Load};

procedure TGraphObject.Store;
begin
  with Stream do
    begin
      Write(grNumber, SizeOf(grNumber));
      Write(X, SizeOf(X));
      Write(Y, SizeOf(Y));
    end{begin};
end{TGraphObject.Store};

constructor TGraphPoint.Init;
begin
  inherited Init(NewX, NewY);
  grNumber := grPoint;
end{TGraphPoint.Init};

procedure TGraphPoint.Draw;
begin
  PutPixel(GetX(X), GetY(Y), GetColor);
end{TGraphPoint.Draw};

constructor TGraphLine.Init;
begin
  inherited Init(NewX, NewY);
  LineStyle := NewLineStyle;
  LineThick := NewLineThick;
  Xe := VirtualX(NewXe);
  Ye := VirtualY(NewYe);
  grNumber := grLine;
end{TGraphLine.Init};

procedure TGraphLine.Draw;
begin
  SetLineStyle(LineStyle, $FF, LineThick);
  Line(GetX(X), GetY(Y), GetX(Xe), GetY(Ye));
end{TGraphLine.Draw};

constructor TGraphLine.Load;
begin
  inherited Load(Stream);
  with Stream do
    begin
      Read(Xe, SizeOf(Xe));
      Read(Ye, SizeOf(Ye));
      Read(LineStyle, SizeOf(LineStyle));
      Read(LineThick, SizeOf(LineThick));
    end{begin};
end{TGraphLine.Load};

procedure TGraphLine.Store;
begin
  inherited Store(Stream);
  with Stream do
    begin
      Write(Xe, SizeOf(Xe));
      Write(Ye, SizeOf(Ye));
      Write(LineStyle, SizeOf(LineStyle));
      Write(LineThick, SizeOf(LineThick));
    end{begin};
end{TGraphLine.Store};

constructor TGraphRectangle.Init;
begin
  inherited Init(NewX, NewY, NewXe, NewYe, NewLineThick, NewLineStyle);
  grNumber := grRectangle;
end{TGraphRectangle.Init};

procedure TGraphRectangle.Draw;
begin
  SetLineStyle(LineStyle, $FF, LineThick);
  Rectangle(GetX(X), GetY(Y), GetX(Xe), GetY(Ye));
end{TGraphRectangle.Draw};

constructor TGraphCircle.Init;
begin
  inherited Init(NewX, NewY);
  LineThick := NewLineThick;
  Radius := VirtualDistanse(NewRadius);
  grNumber := grCircle;
end{TGraphCircle.Init};

procedure TGraphCircle.Draw;
begin
  SetLineStyle(0, $FF, LineThick);
  Circle(GetX(X), GetY(Y), GetDistanse(Radius));
end{TGraphCircle.Draw};

constructor TGraphCircle.Load;
begin
  inherited Load(Stream);
  with Stream do
    begin
      Read(Radius, SizeOf(Radius));
      Read(LineThick, SizeOf(LineThick));
    end{begin};
end{TGraphCircle.Load};

procedure TGraphCircle.Store;
begin
  inherited Store(Stream);
  with Stream do
    begin
      Write(Radius, SizeOf(Radius));
      Write(LineThick, SizeOf(LineThick));
    end{begin};
end{TGraphCircle.Store};

constructor TGraphEllipse.Init;
begin
  inherited Init(NewX, NewY);
  LineThick := NewLineThick;
  RadiusA := VirtualDistanse(NewRadiusA);
  RadiusB := VirtualDistanse(NewRadiusB);
  grNumber := grEllipse;
end{TGraphEllipse.Init};

procedure TGraphEllipse.Draw;
begin
  SetLineStyle(0, $FF, LineThick);
  Ellipse(GetX(X), GetY(Y), 0, 360,
          GetDistanse(RadiusA), GetDistanse(RadiusB));
end{TGraphEllipse.Draw};

constructor TGraphEllipse.Load;
begin
  inherited Load(Stream);
  with Stream do
    begin
      Read(RadiusA, SizeOf(RadiusA));
      Read(RadiusB, SizeOf(RadiusB));
      Read(LineThick, SizeOf(LineThick));
    end{begin};
end{TGraphEllipse.Load};

procedure TGraphEllipse.Store;
begin
  inherited Store(Stream);
  with Stream do
    begin
      Write(RadiusA, SizeOf(RadiusA));
      Write(RadiusB, SizeOf(RadiusB));
      Write(LineThick, SizeOf(LineThick));
    end{begin};
end{TGraphEllipse.Store};

constructor TGraphArc.Init;
begin
  inherited Init(NewX, NewY, NewRadius, NewLineThick);
  StAngle := NewStAngle;
  EndAngle := NewEndAngle;
  grNumber := grArc;
end{TGraphArc.Init};

procedure TGraphArc.Draw;
begin
  SetLineStyle(0, $FF, LineThick);
  Arc(GetX(X), GetY(Y), StAngle, EndAngle, GetDistanse(Radius));
end{TGraphArc.Draw};

constructor TGraphArc.Load;
begin
  inherited Load(Stream);
  with Stream do
    begin
      Read(StAngle, SizeOf(StAngle));
      Read(EndAngle, SizeOf(EndAngle));
    end{begin};
end{TGraphArc.Load};

procedure TGraphArc.Store;
begin
  inherited Store(Stream);
  with Stream do
    begin
      Write(StAngle, SizeOf(StAngle));
      Write(EndAngle, SizeOf(EndAngle));
    end{begin};
end{TGraphArc.Store};

constructor TGraphString.Init;
begin
  inherited Init(NewX, NewY);
  Direction := NewDirection;
  Txt := NewTxt;
  CharSize := NewCharSize;
  grNumber := grString;
end{TGraphString.Init};

procedure TGraphString.Draw;
begin
  SetTextStyle(SmallFont, Direction, CharSize);
  SetTextJustify(LeftText, TopText);
  OutTextXY(GetX(X), GetY(Y), Txt);
end{TGraphLine.Draw};

constructor TGraphString.Load;
begin
  inherited Load(Stream);
  with Stream do
    begin
      Read(CharSize, SizeOf(CharSize));
      Read(Direction, SizeOf(Direction));
      Read(Txt[0], 1);
      Read(Txt[1], Byte(Txt[0]));
    end{begin};
end{TGraphString.Load};

procedure TGraphString.Store;
begin
  inherited Store(Stream);
  with Stream do
    begin
      Write(CharSize, SizeOf(CharSize));
      Write(Direction, SizeOf(Direction));
      Write(Txt[0], Succ(Byte(Txt[0])));
    end{begin};
end{TGraphString.Store};

{******************************************}
{* Numer obiektu graficynego GraphObject  *}
{******************************************}

function NumberOfGraphType;
begin
  with GraphObject^ do
    NumberOfGraphType := grNumber;
end{NumberOfGraphType};

type
  TString = string[10];

const
  LineStyles: array[1..4] of TString = { Style linii rysunkowych        }
    ( 'Ci•gàa',
      'Kropkowana',
      'Symetrii',
      'Przerywana' );

  LineThicks: array[1..2] of TString = { Gruboòci linii rysunkowych      }
    ( 'Cienka',
      'Gruba' );

  Directions: array[1..2] of TString = { Kierunek rysowania tekstu       }
    ( 'Poziomy',
      'Pionowy' );

  FigureNames: array[grPoint..grString] of TString =
    ( 'Punkt',
      'Odcinek',
      'Prostok•t',
      'Okr•g',
      'Elipsa',
      'ùuk',
      'Napis' );

{******************************************}
{*     Zapisanie kolekcji graficznej      *}
{******************************************}

function SaveTxt;
var
  TxtFile: Text;
  SR: SearchRec;

{******************************************}
{*     Zapisanie obiektu graficznego      *}
{******************************************}

procedure WriteGraphObject(GraphObject: PGraphObject
                          ); far;
begin
  case NumberOfGraphType(GraphObject) of
    grPoint     : with PGraphPoint(GraphObject)^ do
      WriteLn(TxtFile, 'Punkt', #9, X, #9, Y);
    grLine      : with PGraphLine(GraphObject)^ do
      WriteLn(TxtFile, 'Odcinek', #9, X, #9, Y, #9, Xe, #9, Ye, #9,
              LineThicks[Succ(LineThick shr 1 and 1)], #9, LineStyles[Succ(LineStyle)]);
    grRectangle : with PGraphRectangle(GraphObject)^ do
      WriteLn(TxtFile, 'Prostok•t', #9, X, #9, Y, #9, Xe, #9, Ye, #9,
              LineThicks[Succ(LineThick shr 1 and 1)], #9, LineStyles[Succ(LineStyle)]);
    grCircle    : with PGraphCircle(GraphObject)^ do
      WriteLn(TxtFile, 'Okr•g', #9, X, #9, Y, #9, Radius, #9, LineThicks[Succ(LineThick shr 1 and 1)]);
    grEllipse   : with PGraphEllipse(GraphObject)^ do
      WriteLn(TxtFile, 'Elipsa', #9, X, #9, Y, #9, RadiusA, #9, RadiusB, #9, LineThicks[Succ(LineThick shr 1 and 1)]);
    grArc       : with PGraphArc(GraphObject)^ do
      WriteLn(TxtFile, 'ùuk', #9, X, #9, Y, #9, Radius, #9, LineThicks[Succ(LineThick shr 1 and 1)],
             #9, StAngle, #9, EndAngle);
    grString    : with PGraphString(GraphObject)^ do
      WriteLn(TxtFile, 'Napis', #9, X, #9, Y, #9, CharSize, #9, Directions[Succ(Direction)], #9, Txt);
  end{case};
end{SaveGraphCollection.WriteGraphObject};

begin
  {$I-}
  Assign(TxtFile, FileName);
  FindFirst(FileName, $FF, SR);
  if SR.Size = 0 then
    Append(TxtFile) else
    Rewrite(TxtFile);
  with GraphCollection^ do
    ForEach(Addr(WriteGraphObject));
  Close(TxtFile);
  {$I+}
  SaveTxt := IOResult;
end{SaveTxt};

{******************************************}
{*     Wczytanie kolekcji graficznej      *}
{******************************************}

function LoadTxt;
var
  TxtFile: Text;
  GraphObject: PGraphObject;

function ReadTxt: string;
var
  Str: string;
begin
  repeat
    Str := '';
    repeat
      Inc(Str[0]);
      Read(TxtFile, Str[Length(Str)]);
    until Eof(TxtFile) or (Str[Length(Str)] in [#9, #10, #13, #26]);
    if Str[Length(Str)] in [#9, #10, #13, #26] then
      Delete(Str, Length(Str), 1);
  until (Str <> '') or Eof(TxtFile);
  ReadTxt := Str;
end{LoadGraphCollection.ReadTxt};

function ReadInteger: Integer;
var
  I, V: Integer;
begin
  Val(ReadTxt, I, V);
  ReadInteger := I;
end{LoadGraphCollection.Str2Int};

const
  TableStyle     = 1;
  TableThick     = 2;
  TableDirection = 3;
  TableFigure    = 4;

function Position(Str: string; Table: Byte): Integer;
var
  I: Byte;
begin
  if Str = '' then
    begin
      Position := grNone;
      Exit;
    end{begin};
  I := 1;
  case Table of
    TableStyle:
      while LineStyles[I] <> Str do
        Inc(I);
    TableThick:
      while LineThicks[I] <> Str do
        Inc(I);
    TableDirection:
      while Directions[I] <> Str do
        Inc(I);
    TableFigure:
      while FigureNames[I] <> Str do
        Inc(I);
  end{case};
  Position := I;
end{LoadGraphCollection.Position};

function LStyle: Integer;
begin
  LStyle := Pred(Position(ReadTxt, TableStyle));
end{LoadGraphColleaction.LStyle};

function LThick: Integer;
begin
  LThick := Pred(Position(ReadTxt, TableThick)) shl 1+1;
end{LoadGraphCollection.LThick};

function Direct: Integer;
begin
  Direct := Pred(Position(ReadTxt, TableDirection));
end{LoadGraph.Direct};

function FigureNumber: Byte;
begin
  FigureNumber := Position(ReadTxt, TableFigure);
end{LoadGraphCollection.FigureNumber};

{******************************************}
{*     Wczytanie obiektu graficznego      *}
{******************************************}

function LoadGraphObject: Boolean;
begin
  LoadGraphObject := True;
  case FigureNumber of
    grPoint     :
      New(PGraphPoint(GraphObject), Init(GetX(ReadInteger), GetY(ReadInteger)));
    grLine      :
      New(PGraphLine(GraphObject), Init(GetX(ReadInteger), GetY(ReadInteger),
                                        GetX(ReadInteger), GetY(ReadInteger),
                                        LThick, LStyle));
    grRectangle :
      New(PGraphRectangle(GraphObject), Init(GetX(ReadInteger), GetY(ReadInteger),
                                             GetX(ReadInteger), GetY(ReadInteger),
                                             LThick, LStyle));
    grCircle    :
      New(PGraphCircle(GraphObject), Init(GetX(ReadInteger), GetY(ReadInteger),
                                          GetDistanse(ReadInteger), LThick));
    grEllipse   :
      New(PGraphEllipse(GraphObject), Init(GetX(ReadInteger), GetY(ReadInteger),
                                           GetDistanse(ReadInteger),
                                           GetDistanse(ReadInteger), LThick));
    grArc       :
      New(PGraphArc(GraphObject), Init(GetX(ReadInteger), GetY(ReadInteger),
                                       GetDistanse(ReadInteger), LThick,
                                       ReadInteger, ReadInteger));
    grString    :
      New(PGraphString(GraphObject), Init(GetX(ReadInteger), GetY(ReadInteger),
                                          ReadInteger, Direct, ReadTxt));
    else LoadGraphObject := False;
  end{case};
end{LoadGraphCollection.LoadGraphObject};

var
  S: string;

begin
  if GraphCollection <> nil then
    Dispose(GraphCollection, Done);
  GraphCollection := New(PCollection, Init(100, 50));
  {$I-}
  Assign(TxtFile, FileName);
  if FSearch(FileName, '') = '' then
    Exit;
  Reset(TxtFile);
  while LoadGraphObject do
    with GraphCollection^ do
      Insert(GraphObject);
  Close(TxtFile);
  {$I+}
  LoadTxt := IOResult;
end{LoadTxt};

{******************************************}
{*   OdlegàoòÜ mi©dzy podanymi punktami   *}
{******************************************}

function Distanse;
begin
  Distanse := Pred(Round(Sqrt(Succ(Sqr(Word(Abs(X2-X1)))+
                                   Sqr(Word(Abs(Y2-Y1)))))));
end{Distanse};

{******************************************}
{*   Konwersja wsp¢àrz©dnej X na wàasn•   *}
{******************************************}

function VirtualX;
begin
  VirtualX := (X div 3) - 8;
end{VirtualX};

{******************************************}
{*   Konwersja wsp¢àrz©dnej Y na wàasn•   *}
{******************************************}

function VirtualY;
begin
  VirtualY := 218 - (Y div 3);
end{VirtualY};

{******************************************}
{*     Konwersja odlegàoòci na wàasn•     *}
{******************************************}

function VirtualDistanse;
begin
  VirtualDistanse := Distanse div 3;
end{VirtualDistanse};

{******************************************}
{*  Konwersja wsp¢àrz©dnej X na ekranow•  *}
{******************************************}

function GetX;
begin
  GetX := (X + 8) * 3;
end{GetX};

{******************************************}
{*  Konwersja wsp¢àrz©dnej X na ekranow•  *}
{******************************************}

function GetY;
begin
  GetY := (218 - Y) * 3;
end{GetY};

{******************************************}
{*    Konwersja odlegàoòci na ekranow•    *}
{******************************************}

function GetDistanse;
begin
  GetDistanse := Distanse * 3;
end{GetDistanse};

const
  RGraphPoint     : TStreamRec = (
    ObjType : 150;
    VmtLink : Ofs(TypeOf(TGraphPoint)^);
    Load    : @TGraphPoint.Load;
    Store   : @TGraphPoint.Store);

  RGraphLine      : TStreamRec = (
    ObjType : 151;
    VmtLink : Ofs(TypeOf(TGraphLine)^);
    Load    : @TGraphLine.Load;
    Store   : @TGraphLine.Store);

  RGraphRectangle : TStreamRec = (
    ObjType : 152;
    VmtLink : Ofs(TypeOf(TGraphRectangle)^);
    Load    : @TGraphRectangle.Load;
    Store   : @TGraphRectangle.Store);

  RGraphCircle    : TStreamRec = (
    ObjType : 153;
    VmtLink : Ofs(TypeOf(TGraphCircle)^);
    Load    : @TGraphCircle.Load;
    Store   : @TGraphCircle.Store);

  RGraphEllipse   : TStreamRec = (
    ObjType : 154;
    VmtLink : Ofs(TypeOf(TGraphEllipse)^);
    Load    : @TGraphEllipse.Load;
    Store   : @TGraphEllipse.Store);

  RGraphArc       : TStreamRec = (
    ObjType : 155;
    VmtLink : Ofs(TypeOf(TGraphArc)^);
    Load    : @TGraphArc.Load;
    Store   : @TGraphArc.Store);

  RGraphString    : TStreamRec = (
    ObjType : 156;
    VmtLink : Ofs(TypeOf(TGraphString)^);
    Load    : @TGraphString.Load;
    Store   : @TGraphString.Store);

{******************************************}
{*  Rejestracja obiekt¢w dla strumienia   *}
{******************************************}

procedure StreamRegistration;
begin
  RegisterType(RCollection);
  RegisterType(RGraphPoint);
  RegisterType(RGraphLine);
  RegisterType(RGraphRectangle);
  RegisterType(RGraphCircle);
  RegisterType(RGraphEllipse);
  RegisterType(RGraphArc);
  RegisterType(RGraphString);
end{StreamRegistration};

{******************************************}
{*         Inicjalizacja moduàu           *}
{******************************************}

begin
  StreamRegistration;
end{GraphicalObjects}.