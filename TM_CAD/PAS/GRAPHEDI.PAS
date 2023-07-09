unit GraphEdit;

{{$DEFINE BMP}

interface

uses
  Graph,            { Obsàuga grafiki                                      }
  Mouse,            { Obsàuga myszki w trybie graficznym BGI               }
  Crt,              { Obsàuga konsoli                                      }
  GraphicalObjects, { Obiekty graficzne programu                           }
  Objects,
  Dos
  {$IFDEF BMP}
  ,BMP
  {$ENDIF}
  ;


function EditGraph(var Collection : PCollection; { Przetwarzany rysunek }
                   var Ok         : Boolean      { Czy poprawny start ?    }
                   )              : Boolean;     { Czy edytowano rysunek ? }

function LoadGraph(FileName            : string;     { Nazwa rysunku       }
                   var GraphCollection : PCollection { Wska´nik rysunku }
                   )                   : Integer;    { Numer bà©du odczytu }
function SaveGraph(FileName        : string;         { Nazwa rysunku       }
                   GraphCollection : PCollection     { Wska´nik rysunku    }
                   )               : Integer;        { Numer bà©du zapisu  }


procedure PrintHPLaserJet(Collection: PCollection    { Drukowany rysunek   }
                          );

implementation

type
  { Kontur wykorzystywany przy rysowaniu okienek i przycisk¢w              }
  PContour = ^TContour;
  TContour =
    record
      A, B: PointType; { Przeciwlegàe rogi konturu                         }
    end{TContour};

  { Typ wykorzystywany przy rysowaniu przycisk¢w i okienek                 }
  PWindows = ^TWindows;
  TWindows =
    record
      Contour      : TContour; { Kontur okna                               }
      Fill         : Byte;     { Kolor wypeànienia                         }
      CursorNumber : array[Boolean] of Integer;
                               { Ksztaàt przyporz•dkowanego kursora myszki }
    end{TWindows};

const
  Yes = True;    { Staàe wykorzystywane do czytelniejszego zapisu          }
  No  = False;

  MouseButtonPressed  = Yes;
  MouseButtonReleased = No;

  SmallButtonsTextSize  = 5; { WielkoòÜ tekstu na maàych przyciskach       }
  BigButtonsTextSize    = 7; { WielkoòÜ tekstu na duæych przyciskach       }
  FramesTextSize        = 4; { WielkoòÜ tekstu na duæych przyciskach       }

  ResetHelpContext      = 255; { Pocz•tkowy numer pomocy kontekstowej      }

  ResetXCoordinate      = 0; { Pocz•tkowa wartoòÜ wsp¢àrz©dnej X           }
  ResetYCoordinate      = 0; { Pocz•tkowa wartoòÜ wsp¢àrz©dnej Y           }

  kbUp    = 72;
  kbDown  = 80;
  kbLeft  = 75;
  kbRight = 77;

  wnEdit        = 1; { Numer okna edycji                                   }
  wnStatus      = 2; { Numer okna statusu                                  }
  wnTools       = 3; { Numer okna narz©dzi                                 }
  wnHelp        = 4; { Numer okienka niewykorzystanego                     }

  WindowsCount = wnHelp; { Liczba okien                                    }

  Windows: array[wnEdit..WindowsCount] of TWindows =  { Cz©òci ekranu      }

    ( ( Contour      : ( A: ( X: 0    ; Y: 0   );   { Pole edycji          }
                         B: ( X: 939  ; Y: 678 ) );
        Fill         : White;
        CursorNumber : ( MouseTargetCross, MouseDiagCross ) ),
      ( Contour      : ( A: ( X: 939  ; Y: 767 );   { Pole statusu         }
                         B: ( X: 0    ; Y: 679 ) );
        Fill         : LightGray;
        CursorNumber : ( MouseStandard, MouseStandard ) ),
      ( Contour      : ( A: ( X: 1023 ; Y: 678 );   { Pole narz©dzi        }
                         B: ( X: 940  ; Y: 0   ) );
        Fill         : LightGray;
        CursorNumber : ( MouseUpHand, MouseCheckMark ) ),
      ( Contour      : ( A: ( X: 940  ; Y: 679 );   { Pole dodatkowe       }
                         B: ( X: 1023 ; Y: 767 ) );
        Fill         : LightGray;
        CursorNumber : ( MouseQuestionMark, MouseQuestionMark ) ) );

  LineStyles: array[0..3] of string[10] = { Style linii rysunkowych        }
    ( 'Ci•gàa',
      'Kropkowana',
      'Symetrii',
      'Przerywana' );

  LineThicks: array[0..3] of string[9] = { Gruboòci linii rysunkowych      }
    ( 'Cienka',
      'Gruba',
      'Zatwierd´',
      'Anuluj' );

  { Numery przycisk¢w narz©dzi                                             }

  btNone        = grNone;       { Brak przycisku                           }
  btPoint       = grPoint;      { Przycisk rysowania punktu                }
  btLine        = grLine;       { Przycisk rysowania odcinka               }
  btRectangle   = grRectangle;  { Przycisk rysowania prostok•ta            }
  btCircle      = grCircle;     { Przycisk rysowania okr©gu                }
  btEllipse     = grEllipse;    { Przycisk rysowania elipsy                }
  btArc         = grArc;        { Przycisk rysowania àuku                  }
  btString      = grString;     { Przycisk rysowania napisu                }
  btClear       = 8;            { Przycisk czyszczenia rysunku             }
  btErase       = 9;            { Przycisk usuwania elemet¢w rysunku       }
  btMove        = 10;           { Przycisk przesuwania element¢w rysunku   }
  btCopy        = 11;           { Przycisk kopiowania elemet¢w rysunku     }
  btRedraw      = 12;           { Przycisk odtwarzania rysunku             }
  btCoordinates = 13;           { Przycisk pobierania danych               }
  btChange      = 14;           { Przycisk zmiany paramatr¢w               }
  btLines       = 15;           { Przycisk zmiany linii rysunkowych        }
  btExit        = 16;           { Przycisk opuszczenia edycji rysunku      }

  ButtonsCount  = btExit;

  { Napisy na przyciskach narz©dzi                                         }

  Buttons: array[btPoint..ButtonsCount] of string[8] =
    ( 'Punkt',
      'Odcinek',
      'Postok•t',
      'Okr•g',
      'Elipsa',
      'ùuk',
      'Napis',
      'WyczyòÜ',
      'Usu‰',
      'Przesu‰',
      'Kopiuj',
      'Odtw¢rz',
      'Dane',
      'Zmie‰',
      'Linie',
      'Wyjòcie' );

var
  {$IFDEF BMP}
  Number               : Integer;      { Numer aktualnego zrzutu ekranu    }
  {$ENDIF}
  Printing, OldIsEdit  : Boolean;      { Czy trwa drukowanie ?             }
  Figure,                              { Numer aktualnie edytowanej figuru }
  ActualHelpContext    : Byte;         { Numer pomocy kontekstowej         }
  LineStyle, LineThick : Word;         { Styl i gruboòÜ linii rysunkowej   }
  OldX, OldY           : Integer;      { Stare wsp¢àrz©dne kursora myszy   }
  GraphCollection      : PCollection;  { Edytowany rysunek              }
  GraphObject          : PGraphObject; { Aktualny obiekt graficzny         }

{******************************************}
{* Konwersja liczby caàkowitej na àa‰cuch *}
{******************************************}

function Str(Value : Integer { Konwertowana liczba caàkowita               }
             )     : string; { WartoòÜ przekonwertowana na àa‰cuch         }
var
  StrValue: string;
begin
  System.Str(Value, StrValue);
  Str := StrValue;
end{Str};

{******************************************}
{*   Wyznaczenie k•ta mi©dzy osi• OX a    *}
{*   odciniem o podanych wsp¢àrz©dnych    *}
{******************************************}

function Deg(X1, Y1, X2, Y2 : Integer
             )              : Integer;
var
  D: LongInt;
begin
  D := Round(ArcTan((X2-X1)/((Y2-Y1)+Byte(Y2=Y1)*1E-30))*(180/Pi))
  - Byte(Y1<=Y2)*90
  + Byte(Y1>Y2)*90;
  while D<0 do Inc(D, 360);
  while D>360 do Dec(D, 360);
  Deg := D;
end{Deg};

{******************************************}
{*    Sprawdzenie stanu klawiszy Alt      *}
{******************************************}

function AltPressed: Boolean; assembler;
asm
  MOV AH, 12H
  INT 16H
  AND AL, 00001000B
  SHR AL, 1
  SHR AL, 1
  SHR AL, 1
end {asm};

{******************************************}
{*    Sprawdzenie stanu klawiszy Ctrl     *}
{******************************************}

function CtrlPressed: Boolean; assembler;
asm
  MOV AH, 12H
  INT 16H
  AND AL, 00000100B
  SHR AL, 1
  SHR AL, 1
end {asm};

procedure Shadow;
var
  I: Integer;
begin
  SetWriteMode(XORPut);
  SetColor(DarkGray);
  for I := 724 to 733 do
    Line(I, 310, I, 400);
  for I := 401 to 410 do
    Line(310, I, 733, I);
  SetWriteMode(NormalPut);
end{DialogWindow.Shadow};

{******************************************}
{*      Rysowanie okienka na ekranie      *}
{******************************************}

procedure DrawWindow(X1, Y1, X2, Y2 : Integer;
                     FillColor      : Byte
                     );
begin
  HideInMouse(X1, Y1, X2, Y2);
  SetColor(White);
  Line(X1, Y1, X1, Y2);
  Line(X1, Y1, X2, Y1);
  SetColor(Black);
  Line(X2, Y2, X1, Y2);
  Line(X2, Y2, X2, Y1);
  SetFillStyle(SolidFill, FillColor);
  if X1>X2 then
    SwapInteger(X1, X2);
  if Y1>Y2 then
    SwapInteger(Y1, Y2);
  Bar(Succ(X1), Succ(Y1), Pred(X2), Pred(Y2));
  ShowInMouse;
end{DrawWindow};

{******************************************}
{*    Stworzenie przycisku na ekranie     *}
{******************************************}

procedure MakeButton(X1, Y1, X2, Y2 : Integer;
                     TSize, TColor  : Byte;
                     Pressed        : Boolean;
                     Name           : string
                     );
begin
  if Pressed then
    DrawWindow(X2, Y2, X1, Y1, LightGray) else
    DrawWindow(X1, Y1, X2, Y2, LightGray);
  SetTextStyle(SmallFont, HorizDir, TSize);
  SetTextJustify(CenterText, CenterText);
  X1 := X1+(X2-X1) div 2;
  Y1 := Y1+Abs(Y2-Y1) div 2-2;
  if Pressed then
    begin
      Inc(X1, 2);
      Inc(Y1, 2);
    end{begin};
  SetColor(TColor);
  HideInMouse(X1, Y1, X2, Y2);
  OutTextXY(X1, Y1, Name);
  ShowInMouse;
end{MakeButton};

{******************************************}
{*    Narysowanie przycisku na ekranie    *}
{******************************************}

procedure DrawButton(Number  : Byte;
                     Pressed : Boolean
                     );
begin
  if Number <> btNone then
    MakeButton(945, Number*30-20, 1015, Number*30, SmallButtonsTextSize,
               Black, Pressed, Buttons[Number]);
end{DrawButton};

{******************************************}
{*    Narysowanie ramki wkoào rysunku     *}
{******************************************}

procedure DrawFrame;
begin
  HideMouse;

  SetFillStyle(SolidFill, White);
  Bar(Succ(GetX(0-8)), Pred(GetY(0-8)), GetX(0+5), Succ(GetY(210+8)));
  Bar(Succ(GetX(0-8)), Pred(GetY(0-8)), Pred(GetX(297+8)), GetY(0+5));
  Bar(Succ(GetX(0-8)), Succ(GetY(210+8)), Pred(GetX(297+8)), GetY(210-5));
  Bar(Pred(GetX(297+8)), Pred(GetY(0-8)), GetX(297-5), Succ(GetY(210+8)));
  Bar(GetX(297-145), GetY(0+5), GetX(297-5), GetY(0+45));

  SetColor(Black);
  SetLineStyle(SolidLn, $FF, ThickWidth);
  Rectangle(GetX(0), GetY(0), GetX(297), GetY(210));
  Line(GetX(297-140), GetY(0), GetX(297-140), GetY(40));
  Line(GetX(297-140), GetY(40), GetX(297), GetY(40));

  SetLineStyle(SolidLn, $FF, NormWidth);
  Line(GetX(297-140), GetY(20), GetX(297), GetY(20));
  Line(GetX(297-120), GetY(10), GetX(297-20), GetY(10));
  Line(GetX(297-120), GetY(0), GetX(297-120), GetY(40));
  Line(GetX(297-20), GetY(0), GetX(297-20), GetY(40));
  Line(GetX(297-100), GetY(0), GetX(297-100), GetY(20));
  Line(GetX(297-40), GetY(0), GetX(297-40), GetY(20));

  ShowMouse;
end{DrawFrame};

{******************************************}
{*   Odtworzenie i narysowanie ekranu     *}
{******************************************}

procedure DrawScreen;
var
  I: Byte;
begin
  HideMouse;
  ClearDevice;
  ShowMouse;
  SetLineStyle(SolidLn, $FF, NormWidth);
  for I := 1 to WindowsCount do
    with Windows[I], Contour do
      DrawWindow(A.X, A.Y, B.X, B.Y, Fill);
  for I := 1 to ButtonsCount do
    DrawButton(I, No);
end{DrawScreen};

{******************************************}
{*  Pobranie numeru okienka, w kt¢rym     *}
{*      znajduje si© kursor myszy         *}
{******************************************}

function GetWindowNumber: Byte;
var
  I: Byte;
begin
  GetWindowNumber := WindowsCount;
  for I := wnEdit to WindowsCount do
    with Windows[I], Contour do
      if MouseIn(A.X, A.Y, B.X, B.Y, 0) then
        begin
          GetWindowNumber := I;
          I := WindowsCount;
        end{begin};
end{GetWindowNumber};

{******************************************}
{*  Pobranie numeru przycisku, na kt¢rym  *}
{*      znajduje si© kursor myszy         *}
{******************************************}

function GetButtonNumber: Byte;
var
  I: Byte;
begin
  for I := btPoint to ButtonsCount do
    if MouseIn(945, I*30-20, 1015, I*30, 0) then
      begin
        GetButtonNumber := I;
        Exit;
      end{begin};
  GetButtonNumber := btNone;
end{GetButtonNumber};

{******************************************}
{*  Zmiana ksztaàtu kursora zaleænie od   *}
{*         poàoæenia na ekranie           *}
{******************************************}

procedure ChangeCursor(DialogCursor: Boolean
                       );
begin
  with Windows[GetWindowNumber] do
    if DialogCursor and MouseIn(300, 300, 723, 400, 0) then
      SetMouseCursor(MouseLeftHand) else
      SetMouseCursor(CursorNumber[MouseButtons = MouseLeftButton]);
end{ChangeCursor};

{******************************************}
{*  Wyòwietlanie wsp¢àrz©dnych kursora w  *}
{*              polu edycji               *}
{******************************************}

procedure DrawCoordinates;
var
  X, Y   : Integer;
  IsEdit : Boolean;
begin
  X := VirtualX(MouseX);
  Y := VirtualY(MouseY);
  IsEdit := (GetWindowNumber = wnEdit);
  if ((X<>OldX) or (Y<>OldY)) and IsEdit then
    MakeButton(5, 684, 205, 709, BigButtonsTextSize, Black, No,
               Concat('X: ', Str(X), ' Y: ', Str(Y))) else
    if IsEdit <> OldIsEdit then
      MakeButton(5, 684, 205, 709, SmallButtonsTextSize, Black, No,
                 'Poza polem edycji');
  OldIsEdit := IsEdit;
  OldX := X;
  OldY := Y;
end{DrawCoordinates};

{******************************************}
{*     Wyòwietlanie parametr¢w figury     *}
{*   aktualnie znalezionej w polu edycji  *}
{******************************************}

procedure ShowInfo(NewGraphObject : PGraphObject;
                   NewShowInfo    : Boolean
                   );
const
  TextDirections: array[0..1] of string[7] =
    ( 'Poziomy', 'Pionowy' );
var
  S, L: string;
begin
  if (GraphObject <> NewGraphObject) or NewShowInfo then
    begin
      GraphObject := NewGraphObject;
      if GraphObject <> nil then
        begin
          SetMouseCursor(MouseRectBox);
          case NumberOfGraphType(GraphObject) of
            grPoint     :
              with PGraphPoint(GraphObject)^ do
                S := Concat('Punkt : X=', Str(X), ' Y=', Str(Y));
            grLine      :
              with PGraphRectangle(GraphObject)^ do
                S := Concat('Odcinek : X1=', Str(X), ' Y1=', Str(Y),
                            ' X2=', Str(XE), ' Y2=', Str(YE));
            grRectangle :
              with PGraphRectangle(GraphObject)^ do
                S := Concat('Prostok•t : X1=', Str(X), ' Y1=', Str(Y),
                            ' X2=', Str(XE), ' Y2=', Str(YE));
            grCircle    :
              with PGraphCircle(GraphObject)^ do
                S := Concat('Okr•g : X=', Str(X), ' Y=', Str(Y),
                            ' R=', Str(Radius));
            grEllipse   :
              with PGraphEllipse(GraphObject)^ do
                S := Concat('Elipsa : X=', Str(X), ' Y=', Str(Y),
                            ' RA=', Str(RadiusA), ' RB=', Str(RadiusB));
            grArc       :
              with PGraphArc(GraphObject)^ do
                S := Concat('ùuk : X=', Str(X), ' Y=', Str(Y),
                            ' R=', Str(Radius), ' A=', Str(StAngle),
                            ' B=', Str(EndAngle));
            grString    :
              with PGraphString(GraphObject)^ do
                S := Concat('Napis : X=', Str(X), ' Y=', Str(Y), ' S=',
                            Str(CharSize), ' D=', TextDirections[Direction]);
          end{case};
          L := 'Linia : ';
          case NumberOfGraphType(GraphObject) of
            grLine, grRectangle :
              with PGraphRectangle(GraphObject)^ do
                L := Concat(L, LineStyles[LineStyle], ' ',
                            LineThicks[(LineThick shr 1) and 1]);
            grCircle            :
              with PGraphCircle(GraphObject)^ do
                L := Concat(L, LineThicks[LineThick shr 1]);
            grEllipse           :
              with PGraphEllipse(GraphObject)^ do
                L := Concat(L, LineThicks[LineThick shr 1]);
            grArc               :
              with PGraphArc(GraphObject)^ do
                L := Concat(L, LineThicks[LineThick shr 1]);
            else L := '';
          end{case};
        end{begin} else
          begin
            S := '';
            L := '';
          end{begin};
      MakeButton(5, 714, 505, 739, BigButtonsTextSize, Black, No, S);
      MakeButton(510, 714, 934, 739, BigButtonsTextSize, Black, No, L);
    end{begin};
end{ShowInfo};

{******************************************}
{*  Procedura wywoàywana w chwilach, gdy  *}
{* nie jest wykonywany æaden inny proces  *}
{******************************************}

procedure Idle(DialogCursor: Boolean
               );
var
  GraphObject: PGraphObject;

{******************************************}
{*    Wyszukiwanie figur w polu edycji    *}
{******************************************}

function Finds(GraphObject : PGraphObject
               )           : Boolean;
               far;
var
  MX, MY : Integer;
  D      : Word;

begin
  MX := VirtualX(MouseX);
  MY := VirtualY(MouseY);
  Finds := False;
  if MouseIn(GetX(5), GetY(5), GetX(297-5), GetY(210-5), 0) then
    case NumberOfGraphType(GraphObject) of
      grPoint     :
        with PGraphPoint(GraphObject)^ do
          Finds := (X=MX) and (Y=MY);
      grLine      :
        with PGraphLine(GraphObject)^ do
          Finds := PointerIn(MX, MY, X, Y, Xe, Ye, 0) and
                            (((MY-Y)*(Xe-X)) shr 6 = ((Ye-Y)*(MX-X)) shr 6);
      grRectangle :
        with PGraphRectangle(GraphObject)^ do
          Finds := (((X=MX) or (XE=MX)) or ((Y=MY) or (YE=MY))) and
                   PointerIn(MX, MY, X, Y, Xe, Ye, 0);
      grCircle    :
        with PGraphCircle(GraphObject)^ do
          Finds := (Pred(Radius) = Distanse(X, Y, MX, MY));
      grEllipse   :
        with PGraphEllipse(GraphObject)^ do
          Finds := ( Round(Sqr(MX-X)/Sqr(RadiusA+Byte(RadiusA=0)) * 10 +
                           Sqr(MY-Y)/Sqr(RadiusB+Byte(RadiusB=0)) * 10) = 10 );
      grArc       :
        with PGraphArc(GraphObject)^ do
          begin
            D := Deg(GetX(X), GetY(Y), GetX(MX), GetY(MY));
            D := D+Byte(D<StAngle)*360;
            Finds := (Pred(Radius) = Distanse(X, Y, MX, MY)) and
              ((D>=StAngle) and (D<=EndAngle+Byte(EndAngle<StAngle)*360));
          end{begin};
    end;
  if MouseIn(GetX(5), GetY(5), GetX(297-5), GetY(210-5), 0) or
     MouseIn(GetX(297-140), GetY(0+40), GetX(297), GetY(0), 0) then
    case NumberOfGraphType(GraphObject) of
      grString    :
        with PGraphString(GraphObject)^ do
          begin
            SetTextStyle(SmallFont, Direction, CharSize);
            Finds := PointerIn(MX, MY, X, Y,
              X+(Direction xor 1)*VirtualDistanse(TextWidth(Txt))+
              Direction*VirtualDistanse(TextHeight(Txt)),
              Y-(Direction xor 1)*VirtualDistanse(TextHeight(Txt)) -
              Direction*VirtualDistanse(TextWidth(Txt)), 0);
          end{begin};
    end{case};
end{Idle.Finds};

{******************************************}
{*   Wyòwietlanie pomocy kontekstowych    *}
{******************************************}

procedure DrawHelpContext;

{******************************************}
{*    Numer wskazywanej cz©òci ekranu     *}
{******************************************}

function GetHelpContext: Byte;

{******************************************}
{* Numer wskazywanej cz©òci pola statusu  *}
{******************************************}

function GetStatus: Byte;
const
  SW: array[1..5, 1..2] of PointType =
    ( ( ( X:   5; Y: 684), (X: 205; Y: 709) ),
      ( ( X: 210; Y: 684), (X: 505; Y: 709) ),
      ( ( X:   5; Y: 714), (X: 505; Y: 739) ),
      ( ( X: 510; Y: 714), (X: 934; Y: 739) ),
      ( ( X: 510; Y: 684), (X: 934; Y: 709) ) );
var
  I: Byte;
begin
  GetStatus := 0;
  for I := 1 to 5 do
    if MouseIn(SW[I][1].X, SW[I][1].Y, SW[I][2].X, SW[I][2].Y, 0) then
      GetStatus := I;
end{Idle.GetHelpNumber.GetStatus};

begin
  case GetWindowNumber of
    wnEdit   :
      GetHelpContext := 0;
    wnStatus :
      GetHelpContext := 1 + GetStatus;
    wnTools  :
      GetHelpContext := 7 + GetButtonNumber;
    wnHelp   :
      GetHelpContext := 24;
  end{case};
end{Idle.DrawHelpContext};

const
  HelpString: array[0..24] of string[118] =
  ( 'Pole edycji rysunku symuluj•ce kartk© formatu A4, na kt¢rej wykonujemy wszystkie dost©pne operacje edytorskie',
    'Pole statusu zawieraj•ce najwaæniejsze informacje dotycz•ce edycji rysunku oraz pomoc kontekstow•',
    'Wsp¢àrz©dne kursora myszki w symulowanym przez pole edycji ukàadzie wsp¢àrz©dnych o skoku 1 milimetr',
    'Nazwa aktualnie edytowanej figury lub opcji dost©pnej w czasie edycji wybranej w polu narz©dzi',
    'Nazwa aktualnej figury znalezionej w polu edycji przez kursor myszki oraz jej podstawowe parametry',
    'Staàe rodzaju i gruboòci linii aktualnej figury znalezionej w polu edycji przez mysz',
    'Staàe rodzaju i gruboòci linii rysowanych figur ustawione przy pomocy opcji LINIE w polu narz©dzi',
    'Pole narz©dzi zawieraj•ce przyciski uruchamiaj•ce wszystkie opcje dost©pne w cz©òci graficznej',
    'Punkt - stawiamy go naciskaj•c przycisk myszki i zwalniaj•c w punkcie docelowym',
    'Odcinek - rysujemy go przyciskaj•c przycisk myszy na punkcie pocz•tkowym i zwalniaj•c na ko‰cowym',
    'Prostok•t - rysujemy go przyciskaj•c lewy przycisk myszy w jednym z wierzchoàk¢w i zwalniaj•c na przeciwlegàym',
    'Okr•g - rysujemy go przyciskaj•c przycisk myszy w òrodku i zwalniaj•c na linii obwodu',
    'Elipsa - rysujemy j• przyciskaj•c przycisk myszy w òrodku i zwalniaj•c w punkcie Xòr+-A Yòr+-B',
    'ùuk - rysujemy go przyciskaj•c przycisk myszy w òrodku i kolejno zwalniaj•c i przyciskaj•c w pocz•tku i ko‰cu àuku',
    'Napis - rysujemy go wciskaj•c przycisk myszy i odpowiednio wypeàniaj•c okienko dialogowe pokazane na ekranie',
    'Po wybraniu opcji na ekranie ukaæe si© okienko potwierdzenia, w kt¢rym przycisk TAK zmaæe rysunek, a NIE anuluje opcj©',
    'Opcja udost©pnia usuwanie element¢w rysunku poprzez ich wyb¢r mysz• w polu edycji i zatwierdzenie przyciskiem',
    'Opcja pozwala przesuwaÜ elementy rysunku mysz• metod•: znajd´ mysz•, przytrzymaj przyciskiem, przesu‰, zwolnij przycisk',
    'Opcja pozwala skopiowaÜ elementy rysunku metod• uæyt• w przesuwaniu, lecz na ekranie zostaje element ´r¢dàowy',
    'Opcja pozwala na odtworzenie rysunku w sytuacji, gdy operacje edytorskie spowoduj• jego nieczytelnoòÜ',
    'Opcja pozwala na narysowanie aktualnej figury poprzez podanie jej parametr¢w w oknie dialogowym',
    'Opcja pozwala na zmian© parametr¢w figury znalezionej mysz• poprzez podanie jej parametr¢w w oknie dialogowym',
    'Opcja pozwala na zmian© rodzaju i gruboòci wykorzystywanej linii przez wybranie jej parametr¢w w oknie dialogowym',
    'Opcja powoduje opuszczenie edycji rysunku po wybraniu przycisku TAK w oknie wyboru',
    'POLE BEZ PRZYDZIELONEJ FUNKCJI');

var
  HelpContext: Byte;

begin
  HelpContext := getHelpContext;
  if ActualHelpContext <> HelpContext then
    begin
      ActualHelpContext := HelpContext;
      MakeButton(5, 745, 934, 763, SmallButtonsTextSize, Black, No,
                 HelpString[HelpContext]);
    end{begin};
end{Idle.Finds};

{******************************************}
{*          Obsàuga klawiatury            *}
{******************************************}

procedure ReadKeyboard;
var
  MX, MY: Integer;
  Ch, Add: Byte;
begin
  MX := MouseX;
  MY := MouseY;
  Add := Byte(CtrlPressed)*12+3;
  case Port[$60] of
    kbUp    :
      if MY > Add then
        Dec(MY, Add);
    kbDown  :
      if MY < GetMaxY - Add then
        Inc(MY, Add);
    kbRight :
      if MX < GetMaxX - Add then
        Inc(MX, Add);
    kbLeft  :
      if MX > Add then
        Dec(MX, Add);
    else Exit;
  end{case};
  asm
    MOV AX, 0C00H
    INT 21H
  end {asm};
  GoToMouse(MX, MY);
end{Idle.ReadKeyboard};

begin
  {$IFDEF BMP}
  if (MouseButtons = MouseRightButton) then
    begin
      DisableMouse;
      with Windows[wnEdit], Contour do
        SaveScreen('Zrzut'+Str(Number)+'.BMP');
      EnableMouse;
      Inc(Number);
    end{begin};
  {$ENDIF}
  ReadKeyboard;
  DrawCoordinates;
  with GraphCollection^ do
    if DialogCursor and MouseIn(300, 300, 723, 400, 0) then
      GraphObject := nil else
      GraphObject := LastThat(Addr(Finds));
  ShowInfo(GraphObject, No);
  if GraphObject = nil then
    ChangeCursor(DialogCursor);
  DrawHelpContext;
end{Idle};

{******************************************}
{*           Okienko dialogu              *}
{******************************************}

function DialogWindow(Question : string
                      )        : Boolean;
var
  OldButton, Button : Byte;
  Size              : Word;
  Image             : Pointer;
begin
  Size := ImageSize(300, 300, 723, 400);
  Button := 0;
  HideMouse;
  GetMem(Image, Size);
  GetImage(300, 300, 723, 400, Image^);
  Shadow;
  DrawWindow(300, 300, 723, 400, Cyan);
  MakeButton(310, 350, 506, 390, BigButtonsTextSize, Red, No, 'TAK');
  MakeButton(516, 350, 713, 390, BigButtonsTextSize, Blue, No, 'NIE');
  SetTextStyle(SmallFont, HorizDir, BigButtonsTextSize);
  SetColor(Black);
  HideMouse;
  OutTextXY(511, 323, Question);
  ShowMouse;
  while (Button = 0) or (MouseButtons = MouseLeftButton) or AltPressed do
    begin
      Idle(Yes);
      OldButton := Button;
      if (MouseButtons = MouseLeftButton) or AltPressed then
        Button := Byte(MouseIn(310, 350, 506, 390, 0)) or
                  Byte(MouseIn(516, 350, 713, 390, 0)) shl 1;
      if Button <> OldButton then
        begin
          MakeButton(310, 350, 506, 390, BigButtonsTextSize,
                     Red, Button = 1, 'TAK');
          MakeButton(516, 350, 713, 390, BigButtonsTextSize,
                     Blue, Button = 2, 'NIE');
        end{begin};
    end{begin};
  MakeButton(310, 350, 506, 390, BigButtonsTextSize, Red, No, 'TAK');
  MakeButton(516, 350, 713, 390, BigButtonsTextSize, Blue, No, 'NIE');
  HideMouse;
  Shadow;
  PutImage(300, 300, Image^, NormalPut);
  FreeMem(Image, Size);
  ShowMouse;
  DialogWindow := (Button = 1);
end{DialogWindow};

{******************************************}
{*    Narysowanie obiektu graficznego     *}
{******************************************}

procedure DrawGraphObject(GraphObject: PGraphObject
                          ); far;
begin
  with Windows[wnEdit], Contour do
    SetViewPort(A.X, A.Y, B.X, B.Y, ClipOn);
  with GraphObject^ do
    Draw;
  SetLineStyle(SolidLn, $FF, NormWidth);
  SetViewPort(0, 0, GetMaxX, GetMaxY, ClipOn);
end{DrawGraphObject};

{******************************************}
{*   Okienko staàych linii rysunkowych    *}
{******************************************}

procedure LinesWindow(var LineStyle, LineThick : Word;
                      DrawSettings             : Boolean
                      );
const
  OkButton      = 6;
  CancelButton  = 7;

var
  LStyle, LThick: Word;

{******************************************}
{*    Rysowanie przycisk¢w w okienku      *}
{******************************************}

procedure MakeButtons;
var
  I: Byte;
begin
  for I := 0 to 3 do
    begin
      if LStyle <> 255 then
        MakeButton(310+I*102, 345, 305+Succ(I)*102, 365,
                   SmallButtonsTextSize, Black, LStyle=I, LineStyles[I]);
      MakeButton(310+I*102, 370, 305+Succ(I)*102, 390,
                   SmallButtonsTextSize, Black, (LThick shr 1)=I,
                   LineThicks[I]);
    end{begin};
end{LinesWindow.MakeButtons};

{******************************************}
{*  Numer wskazanego przycisku w okienku  *}
{******************************************}

function GetLinesButton: Byte;
var
  I, Button, OldButton: Byte;
begin
  Button := 255;
  OldButton := Button;
  if (MouseButtons = MouseLeftButton) or AltPressed then
    repeat
      for I := 0 to 3 do
        begin
          if LStyle <> 255 then
            if MouseIn(310+I*102, 345, 305+Succ(I)*102, 365, 0) then
              Button := I;
            if MouseIn(310+I*102, 370, 305+Succ(I)*102, 390, 0) then
              Button := I + 4;
        end{begin};
      if Button <> OldButton then
        begin
          case Button of
            0..3 : MakeButton(310+Button*102, 345, 305+Succ(Button)*102,
                              365, SmallButtonsTextSize, Black, Yes,
                              LineStyles[Button]);
            4..7 : MakeButton(310+(Button-4)*102, 370, 305+Succ(Button-4)*
                              102, 390, SmallButtonsTextSize, Black,
                              Yes, LineThicks[Button-4]);
          end{case};
          case OldButton of
            0..3 : MakeButton(310+OldButton*102, 345, 305+Succ(OldButton)*
                              102, 365, SmallButtonsTextSize, Black, No,
                              LineStyles[OldButton]);
            4..7 : MakeButton(310+(OldButton-4)*102, 370,
                              305+Succ(OldButton-4)*102, 390,
                              SmallButtonsTextSize, Black, No,
                              LineThicks[OldButton-4]);
          end{case};
          OldButton := Button;
        end{begin};
    until (MouseButtons <> MouseLeftButton);
  while AltPressed do
    Idle(Yes);
  GetLinesButton := Button;
end{LinesWindow.GetLinesButton};

var
  Button, OldButton : Byte;
  Size              : Word;
  Image             : Pointer;
begin
  if LineStyle and LineThick = 255 then
    Exit;
  Size := ImageSize(300, 300, 723, 400);
  LStyle := LineStyle;
  LThick := LineThick;
  HideMouse;
  GetMem(Image, Size);
  GetImage(300, 300, 723, 400, Image^);
  Shadow;
  DrawWindow(300, 300, 723, 400, Cyan);
  MakeButtons;
  SetTextStyle(SmallFont, HorizDir, BigButtonsTextSize);
  SetColor(Black);
  HideMouse;
  OutTextXY(511, 320, 'Staàe linii');
  ShowMouse;
  OldButton := 255;
  repeat
    Idle(Yes);
    Button := GetLinesButton;
    if (OldButton <> Button) and (Button <> 255) then
      begin
        case Button of
          0..3 :
            begin
              if Button <> LStyle then
                MakeButton(310+LStyle*102, 345, 305+Succ(LStyle)*102, 365,
                           SmallButtonsTextSize, Black, No,
                           LineStyles[LStyle]);
                LStyle := Button;
            end{begin};
          4..5:
            begin
              if Button <> (LThick shr 1) + 4 then
                MakeButton(310+(LThick shr 1)*102, 370,
                           305+Succ(LThick shr 1)*102, 390,
                           SmallButtonsTextSize, Black, No,
                           LineThicks[LThick shr 1]);
              LThick := ((Button-4) shl 1)+1;
            end{begin};
        end{case};
        OldButton := Button;
      end{begin};
  until Button in [OkButton, CancelButton];
  HideMouse;
  PutImage(300, 300, Image^, NormalPut);
  Shadow;
  FreeMem(Image, Size);
  if ((LStyle <> LineStyle) or (LThick <> LineThick)) and
     (Button = OkButton) then
    begin
      LineStyle := LStyle;
      LineThick := LThick;
      if DrawSettings and (Button = OkButton) then
        MakeButton(510, 684, 934, 709, BigButtonsTextSize, Black, No,
                   Concat('Rodzaj linii : ', LineStyles[LineStyle], ' ',
                   LineThicks[LineThick shr 1]));
    end{begin};
  ShowMouse;
end{LinesWindow};

{******************************************}
{*  Okienko wczytywania danych obiekt¢w   *}
{*             graficznych                *}
{******************************************}

function DataWindow(NewObject: Boolean
                    ): Boolean;
type
  PDataLine = ^TDataLine;
  TDataLine = record
                Name  : Char;
                Value : string[3];
              end{TDataLine};
  PDataInput = ^TDataInput;
  TDataInput = record
                 Lines   : array[1..5] of TDataLine;
                 Counter : Byte;
               end{TDataInput};

const
  DataInputs: array[grPoint..grString] of TDataInput =
    ( ( Lines: ( ( Name:  'X'; Value:  '0' ), ( Name:  'Y'; Value: '0' ),
                 ( Name:  ' '; Value:   '' ), ( Name:  ' '; Value: ' ' ),
                 ( Name:  ' '; Value:   '' ) ); Counter: 2 ),
      ( Lines: ( ( Name:  'x'; Value:  '0' ), ( Name:  'y'; Value: '0' ),
                 ( Name:  'X'; Value:  '0' ), ( Name:  'Y'; Value: '0' ),
                 ( Name:  ' '; Value:   '' ) ); Counter: 4 ),
      ( Lines: ( ( Name:  'x'; Value:  '0' ), ( Name:  'y'; Value: '0' ),
                 ( Name:  'X'; Value:  '0' ), ( Name:  'Y'; Value: '0' ),
                 ( Name:  ' '; Value:   '' ) ); Counter: 4 ),
      ( Lines: ( ( Name:  'X'; Value:  '0' ), ( Name:  'Y'; Value: '0' ),
                 ( Name:  'R'; Value:  '0' ), ( Name:  ' '; Value:  '' ),
                 ( Name:  ' '; Value:   '' ) ); Counter: 3 ),
      ( Lines: ( ( Name:  'X'; Value:  '0' ), ( Name:  'Y'; Value: '0' ),
                 ( Name:  'A'; Value:  '0' ), ( Name:  'B'; Value: '0' ),
                 ( Name:  ' '; Value:   '' ) ); Counter: 4 ),
      ( Lines: ( ( Name:  'X'; Value:  '0' ), ( Name:  'Y'; Value: '0' ),
                 ( Name:  'R'; Value:  '0' ), ( Name:  'A'; Value: '0' ),
                 ( Name:  'B'; Value:  '0' ) ); Counter: 5 ),
      ( Lines: ( ( Name:  'X'; Value:  '0' ), ( Name:  'Y'; Value: '0' ),
                 ( Name:  'S'; Value:  '5' ), ( Name:  'D'; Value: '0' ),
                 ( Name:  ' '; Value:  'TXT' ) ); Counter: 5 ) );

  MaxValue: array[grPoint..grString] of array[1..5] of Integer =
    ( ( 297, 210,   0,   0,   0 ),
      ( 297, 210, 297, 210,   0 ),
      ( 297, 210, 297, 210,   0 ),
      ( 297, 210, 297,   0,   0 ),
      ( 297, 210, 297, 210,   0 ),
      ( 297, 210, 297, 360, 360 ),
      ( 297, 210,  10,   1,   0 ) );

  OkButton      = 8;
  CancelButton  = 16;
  LinesButton   = 32;

var
  Figure: Byte;

{******************************************}
{* Zamiana staàej tekstowej na caàkowit•  *}
{******************************************}

function IntegerValue(Value: string
                      )    : Integer;
var
  Spr, IntValue: Integer;
begin
  Val(Value, IntValue, Spr);
  IntegerValue := IntValue;
end{DataWindow.IntegerValue};

{******************************************}
{*     Pobranie odpowiedniej danej        *}
{******************************************}

procedure GetData(Input   : Byte;
                  var Str : string
                  );
var
  Ch : Char;
  S  : Word;
  P  : Pointer;
begin
  asm
    MOV AX, 0C00H
    INT 21H
  end {asm};
  if Input > 0 then
    if Input = 255 then
      begin
        S := ImageSize(310, 340, 713, 360);
        GetMem(P, S);
        HideMouse;
        GetImage(310, 340, 703, 360, P^);
        MakeButton(310, 340, 713, 360, SmallButtonsTextSize, Black, Yes, Str);
        repeat
          Idle(Yes);
          if KeyPressed then
            begin
              Ch := ReadKey;
              case Ch of
                #8 :
                  Delete(Str, Length(Str), 1);
                else if (TextWidth(Concat(Str, Ch))<(703-310)) then
                       Str := Concat(Str, Ch);
              end{case};
              MakeButton(310, 340, 713, 360, SmallButtonsTextSize,
                         Black, Yes, Str);
            end{begin};
        until ((MouseButtons = MouseLeftButton) or (Ch = #13));
        MakeButton(310, 340, 713, 360, SmallButtonsTextSize,
                   Black, No, Str);
        HideMouse;
        PutImage(310, 340, P^, NormalPut);
        ShowMouse;
        MakeButton(570, 340, 610, 360, BigButtonsTextSize,
                   Black, No, 'TXT');
      end{begin} else
      with DataInputs[Figure], Lines[Input] do
        begin
          MakeButton(270+Input*60, 340, 250+Succ(Input)*60, 360,
                     BigButtonsTextSize, Black, Yes, Value);
          repeat
            Idle(Yes);
            if KeyPressed then
              begin
                Ch := ReadKey;
                case Ch of
                  '0'..'9' :
                    if (Length(Value)<3) and
                      (IntegerValue(Concat(Value, Ch))<=
                       MaxValue[Figure][Input]) then
                     Value := Concat(Value, Ch);
                  #8       :
                    Delete(Value, Length(Value), 1);
                end{case};
                MakeButton(270+Input*60, 340, 250+Succ(Input)*60, 360,
                           BigButtonsTextSize, Black, Yes, Value);
              end{begin};
          until ((MouseButtons = MouseLeftButton) or (Ch = #13));
          MakeButton(270+Input*60, 340, 250+Succ(Input)*60, 360,
                     BigButtonsTextSize, Black, No, Value);
        end{begin};
end{DataWindow.GetData};

{******************************************}
{*   Numer wskazanego przycisku okienka   *}
{******************************************}

function GetInput: Byte;
var
  I, OldInput, Input: Byte;
begin
  OldInput := 0;
  with DataInputs[Figure] do
    begin
      repeat
        Input := 0;
        for I := 1 to Counter do
          if MouseIn(270+I*60, 340, 250+Succ(I)*60, 360, 0) then
            begin
              Input := I;
              I := Counter;
            end{begin};
        if Input <> OldInput then
          begin
            if OldInput > 0 then
              MakeButton(270+OldInput*60, 340, 250+Succ(OldInput)*60, 360,
                         BigButtonsTextSize, Black, No,
                         Lines[OldInput].Value);
            if Input > 0 then
              MakeButton(270+Input*60, 340, 250+Succ(Input)*60, 360,
                         BigButtonsTextSize, Black, Yes, Lines[Input].Value);
            OldInput := Input;
          end{begin};
      until (MouseButtons <> MouseLeftButton) or
             MouseIn(310, 370, 507, 390, 0) or MouseIn(517, 370, 713, 390, 0) or
             MouseIn(260+Succ(Counter)*60, 340, 713, 360, 0);
      while AltPressed do
        Idle(Yes);
      if Input = 0 then
        GetInput := (Byte(MouseIn(310, 370, 507, 390, 0))*OkButton) or
                    (Byte(MouseIn(517, 370, 713, 390, 0))*CancelButton) or
                    (Byte(MouseIn(260+Succ(Counter)*60, 340, 713, 360, 0))*
                     LinesButton) else
        GetInput := Input;
    end{begin};
end{DataWindow.GetInput};

{******************************************}
{*   Sprawdzenie poprawnoòci wczytanych   *}
{*                 danych                 *}
{******************************************}

function Getting: Boolean;
var
  I: Byte;
begin
  Getting := No;
  with DataInputs[Figure] do
    for I := 1 to Counter-(Byte(Figure in [grArc, grString])*2) do
      with Lines[I] do
        if (IntegerValue(Value) = 0) then
          Exit;
  Getting := Yes;
end{DataWindow.Getting};

var
  Button, I      : Byte;
  Size, LSt, LTh : Word;
  NTxt           : string;
  GraphObject    : PGraphObject;
  Image          : Pointer;
  IV             : array[1..5] of Integer;
begin
  GraphObject := GraphEdit.GraphObject;
  if NewObject then
    Figure := GraphEdit.Figure else
    Figure := NumberOfGraphType(GraphObject);
  if (Figure in [grPoint..grCounter]) then
    begin
      Size := ImageSize(300, 300, 723, 400);
      Button := 0;
      HideMouse;
      GetMem(Image, Size);
      GetImage(300, 300, 723, 400, Image^);
      Shadow;
      DrawWindow(300, 300, 723, 400, Cyan);
      SetTextStyle(SmallFont, HorizDir, BigButtonsTextSize);
      SetTextJustify(CenterText, CenterText);
      HideMouse;
      OutTextXY(512, 320, 'Dane figury : ' + Buttons[Figure]);
      LSt := 255;
      LTh := 255;
      if NewObject then
        begin
          NTxt := '';
          case Figure of
            grLine, grRectangle:
              begin
                LSt := LineStyle;
                LTh := LineThick;
              end{begin};
            grCircle..grArc:
              LTh := LineThick;
            grString:
              if MouseIn(GetX(0), GetY(0), GetX(297), GetY(210), 0) then
                with DataInputs[grString] do
                  begin
                    Lines[1].Value := Str(VirtualX(MouseX));
                    Lines[2].Value := Str(VirtualY(MouseY));
                  end{begin};
          end{case};
        end{begin} else
        with DataInputs[Figure] do
          begin
            with GraphObject^ do
              begin
                Lines[1].Value := Str(X);
                Lines[2].Value := Str(Y);
              end{begin};
            case Figure of
              grLine, grRectangle :
                with PGraphLine(GraphObject)^ do
                  begin
                    Lines[3].Value := Str(Xe);
                    Lines[4].Value := Str(Ye);
                    LSt            := LineStyle;
                    LTh            := LineThick;
                  end{begin};
              grCircle            :
                with PGraphCircle(GraphObject)^ do
                  begin
                    Lines[3].Value := Str(Radius);
                    LTh            := LineThick;
                  end{begin};
              grEllipse           :
                with PGraphEllipse(GraphObject)^ do
                  begin
                    Lines[3].Value := Str(RadiusA);
                    Lines[4].Value := Str(RadiusB);
                    LTh            := LineThick;
                  end{begin};
              grArc               :
                with PGraphArc(GraphObject)^ do
                  begin
                    Lines[3].Value := Str(Radius);
                    Lines[4].Value := Str(StAngle);
                    Lines[5].Value := Str(EndAngle);
                    LTh            := LineThick;
                  end{begin};
              grString            :
                with PGraphString(GraphObject)^ do
                  begin
                    Lines[3].Value := Str(CharSize);
                    Lines[4].Value := Str(Direction);
                    NTxt           := Txt;
                  end{begin};
            end{case};
          end{begin};
      with DataInputs[Figure] do
        begin
          for I := 1 to Counter do
            begin
              MakeButton(270+I*60, 340, 250+Succ(I)*60, 360,
                         BigButtonsTextSize, Black, No, Lines[I].Value);
              HideMouse;
              SetTextJustify(RightText, TopText);
              OutTextXY(270+I*60, 340, Lines[I].Name);
            end{begin};
          MakeButton(260+Succ(Counter)*60, 340, 713, 360,
                     BigButtonsTextSize, Black, No, 'Linia');
        end{begin};
      MakeButton(310, 370, 507, 390, SmallButtonsTextSize,
                 Black, No, 'Zatwierd´');
      MakeButton(517, 370, 713, 390, SmallButtonsTextSize,
                 Black, No, 'Anuluj');
      repeat
        Idle(Yes);
        if (MouseButtons = MouseLeftButton) or AltPressed then
          begin
            Button := GetInput;
            if (Button = 5) and (Figure = grString) then
              GetData(255, NTxt) else
              if Button in [1..5] then
                GetData(Button, NTxt) else
                if Button = LinesButton then
                  with DataInputs[Figure] do
                    begin
                      MakeButton(260+Succ(Counter)*60, 340, 713, 360,
                                 BigButtonsTextSize, Black, Yes, 'Linia');
                      while (MouseButtons = MouseLeftButton) or
                            AltPressed do
                        Idle(Yes);
                      MakeButton(260+Succ(Counter)*60, 340, 713, 360,
                                 BigButtonsTextSize, Black, No, 'Linia');
                      LinesWindow(LSt, LTh, No);
                    end{begin};
          end{begin};
      until ((Button = OkButton) and Getting) or (Button = CancelButton);
      case Button of
        OkButton     :
          MakeButton(310, 370, 507, 390, SmallButtonsTextSize,
                     Black, Yes, 'Zatwierd´');
        CancelButton :
          MakeButton(517, 370, 713, 390, SmallButtonsTextSize,
                     Black, Yes, 'Anuluj');
      end{case};
      while (MouseButtons = MouseLeftButton) or AltPressed do
        Idle(Yes);
      case Button of
        OkButton     :
          MakeButton(310, 370, 507, 390, SmallButtonsTextSize,
                     Black, No, 'Zatwierd´');
        CancelButton :
          MakeButton(517, 370, 713, 390, SmallButtonsTextSize,
                     Black, No, 'Anuluj');
      end{case};
      HideMouse;
      PutImage(300, 300, Image^, NormalPut);
      Shadow;
      FreeMem(Image, Size);
      ShowMouse;
      while (MouseButtons = MouseLeftButton) or AltPressed do
        Idle(Yes);
      if Button = OkButton then
        begin
          with DataInputs[Figure] do
            for I := 1 to Counter do
          IV[I] := IntegerValue(Lines[I].Value);
          if NewObject then
            begin
              case Figure of
                grPoint         :
                  GraphObject := New(PGraphPoint, Init(GetX(IV[1]),
                                     GetY(IV[2])));
                grLine          :
                  GraphObject := New(PGraphLine, Init(GetX(IV[1]),
                                     GetY(IV[2]), GetX(IV[3]), GetY(IV[4]),
                                     LTh, LSt));
                grRectangle     :
                  GraphObject := New(PGraphRectangle, Init(GetX(IV[1]),
                                     GetY(IV[2]), GetX(IV[3]), GetY(IV[4]),
                                     LTh, LSt));
                grCircle        :
                  GraphObject := New(PGraphCircle, Init(GetX(IV[1]),
                                     GetY(IV[2]), GetDistanse(IV[3]), LTh));
                grEllipse       :
                  GraphObject := New(PGraphEllipse, Init(GetX(IV[1]),
                                     GetY(IV[2]), GetDistanse(IV[3]),
                                     GetDistanse(IV[4]), LTh));
                grArc           :
                  GraphObject := New(PGraphArc, Init(GetX(IV[1]),
                                     GetY(IV[2]), GetDistanse(IV[3]), Lth,
                                     GetDistanse(IV[4]), GetDistanse(IV[5])));
                grString        :
                  GraphObject := New(PGraphString, Init(GetX(IV[1]),
                                     GetY(IV[2]), IV[3], IV[4], NTxt));
              end{case};
              with GraphCollection^ do
                Insert(GraphObject);
            end{begin} else
            begin
              SetColor(White);
              HideMouse;
              DrawGraphObject(GraphObject);
              ShowMouse;
              SetColor(Black);
              with GraphObject^ do
                begin
                  X := IV[1];
                  Y := IV[2];
                end{begin};
              case Figure of
                grLine, grRectangle :
                  with PGraphLine(GraphObject)^ do
                    begin
                      Xe := IV[3];
                      Ye := IV[4];
                      LineStyle := LSt;
                      LineThick := LTh;
                    end{begin};
                grCircle            :
                  with PGraphCircle(GraphObject)^ do
                    begin
                      Radius := IV[3];
                      LineThick := LTh;
                    end{begin};
                grEllipse           :
                  with PGraphEllipse(GraphObject)^ do
                    begin
                      RadiusA := IV[3];
                      RadiusB := IV[4];
                      LineThick := LTh;
                    end{begin};
                grArc               :
                  with PGraphArc(GraphObject)^ do
                    begin
                      Radius := IV[3];
                      StAngle := IV[4];
                      EndAngle := IV[5];
                      LineThick := LTh;
                    end{begin};
                grString            :
                  with PGraphString(GraphObject)^ do
                    begin
                      Txt := NTxt;
                      CharSize := IV[3];
                      Direction := IV[4];
                    end{begin};
              end{case};
          end{begin};
        HideMouse;
        DrawGraphObject(GraphObject);
        ShowInfo(GraphObject, not NewObject);
        ShowMouse;
      end{begin};
    end{begin};
  DataWindow := (Button = OkButton);
end{DataWindow};

{******************************************}
{*   Odrysowanie rysunku w polu edycji    *}
{******************************************}

procedure DrawGraphCollection;

{******************************************}
{*    Narysowanie obiektu graficznego     *}
{******************************************}

procedure DrawGraphObject(GraphObject: PGraphObject
                          ); far;
begin
  with GraphObject^ do
    if (NumberOfGraphType(GraphObject) <> grString) or
       (not PointerIn(X, Y, 297-140, 0, 297, 40, 0)) then
      Draw;
end{DrawGraphCollection.DrawGraphObject};

{******************************************}
{*   Narysowanie obiekty typu grString    *}
{******************************************}

procedure DrawGraphString(GraphObject: PGraphObject
                          ); far;
begin
  with GraphObject^ do
    if (NumberOfGraphType(GraphObject) = grString) and
       PointerIn(X, Y, 297-140, 0, 297, 40, 0) then
      Draw;
end{DrawGraphCollection.DrawGraphObject};

begin
  with Windows[wnEdit], Contour do
    SetViewPort(A.X, A.Y, B.X, B.Y, ClipOn);
  SetColor(Black);
  with GraphCollection^, Windows[1] do
    begin
      with Contour do
        DrawWindow(A.X, A.Y, B.X, B.Y, Fill);
      HideMouse;
      ForEach(Addr(DrawGraphObject));
      DrawFrame;
      HideMouse;
      ForEach(Addr(DrawGraphString));
      ShowMouse;
    end{begin};
  SetLineStyle(SolidLn, $FF, NormWidth);
  SetViewPort(0, 0, GetMaxX, GetMaxY, ClipOn);
end{DrawGraphCollection};

{******************************************}
{*     Usuni©cie obiektu graficznego      *}
{******************************************}

procedure DeleteGraphObject;
begin
   with GraphCollection^ do
     begin
       if GraphObject <> nil then
         begin
           SetColor(White);
           HideMouse;
           DrawGraphObject(GraphObject);
           ShowMouse;
           Free(GraphObject);
           ShowInfo(nil, No);
           while MouseButtons = MouseLeftButton do
             Idle(No);
         end{begin};
     end{begin};
end{DeleteGraphObject};

{******************************************}
{*   Narysowanie linii " odtwarzalnej "   *}
{******************************************}

procedure DrawLine(X1, Y1, X2, Y2: Integer
                   );
begin
  SetWriteMode(XORPut);
  SetColor(LightGray);
  SetLineStyle(SolidLn, $FF, NormWidth);
  HideMouse;
  Line(X1, Y1, X2, Y2);
  ShowMouse;
  SetWriteMode(NormalPut);
end{DrawLine};

{******************************************}
{*   Przeniesienie obiektu graficznego    *}
{******************************************}

procedure MoveGraphObject(Copy: Boolean
                          );
var
  OX, OY, MX, MY               : Integer;
  GraphObject, CopyGraphObject : PGraphObject;
begin
  with GraphCollection^ do
    begin
      GraphObject := GraphEdit.GraphObject;
      if GraphObject <> nil then
        begin
          OX := VirtualX(MouseX);
          OY := VirtualY(MouseY);
          MX := VirtualX(MouseX);
          MY := VirtualY(MouseY);
          DrawLine(GetX(OX), GetY(OY), GetX(MX), GetY(MY));
          while (MouseButtons = MouseLeftButton) or AltPressed do
            begin
              if (MX<>VirtualX(MouseX)) or (MY <> VirtualY(MouseY)) then
                begin
                  DrawLine(GetX(OX), GetY(OY), GetX(MX), GetY(MY));
                  MX := VirtualX(MouseX);
                  MY := VirtualY(MouseY);
                  DrawLine(GetX(OX), GetY(OY), GetX(MX), GetY(MY));
                end{begin};
              Idle(No);
            end{begin};
          DrawLine(GetX(OX), GetY(OY), GetX(MX), GetY(MY));
          MX := VirtualX(MouseX);
          MY := VirtualY(MouseY);
          if Copy then
            begin
              case NumberOfGraphType(GraphObject) of
                grPoint             :
                  with PGraphPoint(GraphObject)^ do
                    CopyGraphObject := New(PGraphPoint, Init(GetX(X),
                                           GetY(Y)));
                grLine :
                  with PGraphLine(GraphObject)^ do
                    CopyGraphObject := New(PGraphLine, Init(GetX(X),
                                           GetY(Y), GetX(Xe), GetY(Ye),
                                           LineThick, LineStyle));
                grRectangle :
                  with PGraphRectangle(GraphObject)^ do
                    CopyGraphObject := New(PGraphRectangle, Init(GetX(X),
                                           GetY(Y), GetX(Xe), GetY(Ye),
                                           LineThick, LineStyle));
                grCircle            :
                  with PGraphCircle(GraphObject)^ do
                    CopyGraphObject := New(PGraphCircle, Init(GetX(X),
                                           GetY(Y), GetDistanse(Radius),
                                           LineThick));
                grEllipse           :
                  with PGraphEllipse(GraphObject)^ do
                    CopyGraphObject := New(PGraphEllipse, Init(GetX(X),
                                           GetY(Y), GetDistanse(RadiusA),
                                           GetDistanse(RadiusB), LineThick));
                grArc               :
                  with PGraphArc(GraphObject)^ do
                    CopyGraphObject := New(PGraphArc, Init(GetX(X), GetY(Y),
                                           GetDistanse(Radius), LineThick,
                                           StAngle, EndAngle));
                grString            :
                  with PGraphString(GraphObject)^ do
                    CopyGraphObject := New(PGraphString, Init(GetX(X),
                                           GetY(Y), CharSize, Direction,
                                           Txt));
              end{case};
              Insert(CopyGraphObject);
            end{begin} else
            begin
              SetColor(White);
              HideMouse;
              DrawGraphObject(GraphObject);
            end{bein};
          with GraphObject^ do
            begin
              X := X+MX-OX;
              Y := Y+MY-OY;
            end{begin};
          if NumberOfGraphType(GraphObject) in [grLine, grRectangle] then
            with PGraphLine(GraphObject)^ do
              begin
                Xe := Xe+MX-OX;
                Ye := Ye+MY-OY;
              end{begin};
          SetColor(Black);
          HideMouse;
          DrawGraphObject(GraphObject);
          ShowMouse;
          ShowInfo(GraphObject, No);
        end{begin};
    end{begin};
end{MoveGraphObject};

{******************************************}
{*          Wymazanie rysunku             *}
{******************************************}

procedure DeleteAllGraphObjects;
begin
  if DialogWindow('Zmaæ rysunek') then
    begin
      with GraphCollection^ do
        FreeAll;
      DrawGraphCollection;
    end{begin};
end{DeleteAllGraphObjects};

{******************************************}
{*             Edycja rysunku             *}
{******************************************}

function Edit: Boolean;
var
  ButtonNumber, OldButtonNumber : Byte;
  EndProgram                    : Boolean;
  GraphObject                   : PGraphObject;

{******************************************}
{*     Edycja poszczeg¢lnych figur        *}
{******************************************}

procedure FigureEdit;

{******************************************}
{* Stworzenie nowego obiektu graficznego  *}
{******************************************}

function NewGraphObject: PGraphObject;
var
  X, Y, Xe, Ye, Xee, Yee, D : Integer;
  GraphObject               : PGraphObject;
begin
  X := MouseX;
  Y := MouseY;
  case Figure of
    grString :
      begin
        if DataWindow(Yes) then
          with GraphCollection^ do
            begin
              GraphObject := At(Pred(Count));
              Delete(GraphObject);
            end{begin} else
        GraphObject := nil;
      end{begin};
    grPoint :
      begin
        while (MouseButtons = MouseLeftButton) or AltPressed do
          begin
            Idle(No);
            X := MouseX;
            Y := MouseY;
          end{begin};
        GraphObject := New(PGraphPoint, Init(X, Y));
      end{begin};
    grLine..grArc :
      begin
        Xe := X;
        Ye := Y;
        DrawLine(X, Y, Xe, Ye);
        while (MouseButtons = MouseLeftButton) or AltPressed or
              ((Figure in [grCircle, grEllipse]) and
              ((Xe-X=0) or (Ye-Y=0))) do
          begin
            Idle(No);
              if (Xe <> MouseX) or (Ye <> MouseY) then
                begin
                  DrawLine(X, Y, Xe, Ye);
                  Xe := MouseX;
                  Ye := MouseY;
                  DrawLine(X, Y, Xe, Ye);
                end{begin};
          end{begin};
        if Figure = grArc then
          begin
            Xee := Xe;
            Yee := Ye;
            DrawLine(X, Y, Xee, Yee);
            while (MouseButtons <> MouseLeftButton) and not AltPressed do
              begin
                Idle(No);
                if (Xee <> MouseX) or (Yee <> MouseY) then
                  begin
                    DrawLine(X, Y, Xee, Yee);
                    Xee := MouseX;
                    Yee := MouseY;
                    DrawLine(X, Y, Xee, Yee);
                  end{begin};
              end{begin};
            while (MouseButtons = MouseLeftButton) or AltPressed do
              Idle(No);
            DrawLine(X, Y, Xee, Yee);
          end{begin};
        DrawLine(X, Y, Xe, Ye);
        case Figure of
          grLine          :
            GraphObject := New(PGraphLine, Init(X, Y, Xe, Ye,
                               LineThick, LineStyle));
          grRectangle     :
            GraphObject := New(PGraphRectangle, Init(X, Y, Xe, Ye,
                               LineThick, LineStyle));
          grCircle        :
            GraphObject := New(PGraphCircle, Init(X, Y,
                               Distanse(X, Y, Xe, Ye), LineThick));
          grEllipse       :
            GraphObject := New(PGraphEllipse, Init(X, Y, Abs(Xe-X),
                               Abs(Ye-Y), LineThick));
          grArc           :
            GraphObject := New(PGraphArc, Init(X, Y, Distanse(X, Y, Xe, Ye),
                               LineThick, Deg(X, Y, Xe, Ye),
                               Deg(X, Y, Xee, Yee)));
        end{case};
      end{begin};
  end{case};
  NewGraphObject := GraphObject;
  if GraphObject <> nil then
    begin
      HideMouse;
      SetColor(Black);
      DrawGraphObject(GraphObject);
      ShowMouse;
    end{begin};
end{Edit.FigureEdit.NewGraphObject};

begin
  MouseArea(24, 24, 915, 654);
  case Figure of
    btErase     :
      DeleteGraphObject;
    btMove      :
      MoveGraphObject(No);
    btCopy      :
      MoveGraphObject(Yes);
    btChange    :
      DataWindow(No);
    else begin
           GraphObject := NewGraphObject;
           if GraphObject <> nil then
             with GraphCollection^ do
               Insert(GraphObject);
         end{begin};
  end{case};
  MouseArea(24, 24, 1000, 744);
end{Edit.FigureEdit};

{******************************************}
{* Wybranie figury lub opcji edytorskiej  *}
{******************************************}

procedure SetFigure(NewFigure: Byte
                    );
begin
  if Figure <> NewFigure then
    with Windows[wnStatus], Contour do
      begin
        Figure := NewFigure;
        MakeButton(210, 684, 505, 709, BigButtonsTextSize, Black, No,
                   Buttons[NewFigure]);
      end{begin};
end{Edit.SetFigure};

begin
  DrawGraphCollection;
  Edit := No;
  SetFigure(grPoint);
  EndProgram := No;
  repeat
    Idle(No);
    OldButtonNumber := btNone;
    if (MouseButtons = MouseLeftButton) or AltPressed then
      case GetWindowNumber of
        wnEdit     :
          FigureEdit;
        wnTools    :
          begin
            repeat
              Idle(No);
              ButtonNumber := GetButtonNumber;
              if ButtonNumber <> OldButtonNumber then
                begin
                  DrawButton(ButtonNumber, Yes);
                  DrawButton(OldButtonNumber, No);
                  OldButtonNumber := ButtonNumber;
                end{begin};
            until (MouseButtons <> MouseLeftButton) and not AltPressed;
            DrawButton(ButtonNumber, No);
            if ButtonNumber in [btPoint..btString, btErase..btCopy,
                                btChange, btCoordinates, btLines] then
              Edit := Yes;
            case ButtonNumber of
              btPoint..btString, btErase..btCopy, btChange :
                SetFigure(ButtonNumber);
              btClear                                      :
                DeleteAllGraphObjects;
              btRedraw                                     :
                DrawGraphCollection;
              btCoordinates                                :
                DataWindow(Yes);
              btLines                                      :
                LinesWindow(LineStyle, LineThick, Yes);
              btExit                                       :
                EndProgram := DialogWindow('Zako‰cz edycj©');
            end{case};
          end{begin};
      end{case};
  until EndProgram;
end{Edit};

{******************************************}
{*  Edycja rysunku - wàaòciwa procedura   *}
{******************************************}

function EditGraph;
begin
  GraphCollection := Collection;
  SetWriteMode(NormalPut);
  Ok := InitMouse;
  if Ok then
    begin
      Figure            := grNone;
      GraphObject       := Addr(EditGraph);
      ActualHelpContext := ResetHelpContext;
      OldX              := ResetXCoordinate;
      OldY              := ResetYCoordinate;
      LineStyle         := SolidLn;
      LineThick         := NormWidth;
      DrawScreen;
      MakeButton(510, 684, 934, 709, BigButtonsTextSize, Black, No,
                 Concat('Rodzaj linii: ', LineStyles[LineStyle], ' ',
                 LineThicks[LineThick shr 1]));
      EditGraph := Edit;
      DoneMouse;
    end{begin};
  Collection := GraphCollection;
end{EditGraph};

{******************************************}
{*       Wczytanie rysunku z dysku        *}
{******************************************}

function LoadGraph;
var
  Stream: TBufStream;
begin
  Dispose(GraphCollection, Done);
  with Stream do
    begin
      Init(FileName, stOpen, 1024);
      GraphCollection := PCollection(Get);
      Done;
      LoadGraph := Status;
    end{begin};
end{LoadGraph};

{******************************************}
{*       Zapisanie rysunku na dysk        *}
{******************************************}

function SaveGraph;
var
  Stream: TBufStream;
begin
  with Stream do
    begin
      Init(FileName, stCreate, 1024);
      Put(GraphCollection);
      Done;
      SaveGraph := Status;
    end{begin};
end{SaveGraph};

{******************************************}
{*   Wydruk rysunku na drukarce HP LJet   *}
{******************************************}

procedure PrintHPLaserJet;
var
  Linia_S: string[82];
  Linia: array[0..82] of Byte absolute Linia_S;
  I, J, K, L: Integer;
  C: Byte;

{******************************************}
{*          Komenda dla drukarki          *}
{******************************************}

procedure BiosPrint(S: string);
var
  I: Byte;
  Regs: Registers;
begin
  for I := 1 to Length(S) do
    with Regs do
      begin
        AH := 0;
        AL := Ord(S[I]);
        DX := 0;
        Intr($17, Regs);
      end{begin};
end{PrintHPLaserJet.BiosPrint};

begin
  if Printing then
    Exit;
  if Collection <> nil then
    begin
      GraphCollection := Collection;
      DrawGraphCollection;
    end{begin};
  HideMouse;
  Printing := Yes;
  BiosPrint(#27'*t100R'+#27'*r0A');
  for J := 921 downto 21 do
    begin
      FillChar(Linia, 83, 0);
      for I := 22 to 677 do
        begin
          C := GetPixel(J, I);
          if C = 0 then
            begin
              K := ((I-22) div 8) + 1;
              L := (I-22) mod 8;
              Linia[K] := Linia[K] or (128 shr L);
            end{begin};
        end{begin};
      PutPixel(J, 5, 0);
      Linia_S[0] := #82;
      BiosPrint(#27'*b82W'+Linia_S);
    end{begin};
  BiosPrint(#27'*rB'+#12);
  SetColor(15);
  Line(21, 5, 921, 5);
  ShowMouse;
  Printing := No;
end{PrintHPLaserJet};

{******************************************}
{*         Inicjalizacja moduàu           *}
{******************************************}

begin
  {$IFDEF BMP}
  Number := 0;
  {$ENDIF}
  Printing := No;
end{GraphEdit}.
