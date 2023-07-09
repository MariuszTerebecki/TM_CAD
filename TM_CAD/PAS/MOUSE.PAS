
{ Obsˆuga myszy dla programu TM-CAD }

unit Mouse;

interface

{ Inicjacja sterownika myszy }
function InitMouse: Boolean;
{ Deinicjacja sterownika myszy }
procedure DoneMouse;
{ Wy˜wietlenie kursora myszy }
procedure ShowMouse;
{ Schoweanie kursora myszy }
procedure HideMouse;
{ Schowanie kursora myszy w przypadku, gdy znajduje si© }
{ on w prostok¥tnym obszarze ekranu o wsp¢ˆrz©dnych     }
{ przekazanych w parametrach procedury                  }
procedure HideInMouse(X1, Y1, X2, Y2: Integer);
{ Cofni©cie dziaˆania procedury HideInMouse }
procedure ShowInMouse;
{ Pobranie stanu klawiszy oraz pozycji kurzsora myszy }
procedure ReadMouse;
{ Ustalenie ksztaˆtu kursora myszy }
procedure SetMouseCursor(CursorNumber: Byte);
{ Ustalenie granic "wybiegu" dla kursora myszy }
procedure MouseArea(X1, Y1, X2, Y2: Integer);
{ True, je˜li kursor myszy znajduje si© w obszarze ekranu }
{  ograniczonym wsp¢ˆrz©dnymi przekazanymi w parametrach  }
function MouseIn(X1, Y1, X2, Y2: Integer; D: Integer): Boolean;
{ True, je˜li punkt ( X, Y ) znajduje si© w obszarze ekranu }
{ ograniczonym wsp¢ˆrz©dnymi przekazanymi w parametrach     }
function PointerIn(X, Y, X1, Y1, X2, Y2: Integer; D: Integer): Boolean;
{ Przesuni©cie kursora myszy do punktu o wsp¢ˆrz©dnych X, Y }
procedure GoToMouse(X, Y: Integer);

{ Blokada myszy }
procedure DisableMouse;
{ Odblokowanie myszy }
procedure EnableMouse;

{ Procedura pomocnicza zamieniaj¥ca kolejno˜ci¥ warto˜ci }
{ zmiennych A i B                                        }
procedure SwapInteger(var A, B: Integer);

{ Najwa¾niejsze parametry myszy }
var
  MouseX, MouseY, MouseButtons, AreaX1, AreaY1, AreaX2, AreaY2: Integer;
  MouseCursor: Byte;

{ Staˆe u¾yte dla zwi©kszenia czytelno˜ci zapisu programu }
const
  MouseLeftButton   = 1;
  MouseRightButton  = 2;
  MouseCenterButton = 4;

  { Staˆe kuror¢w myszki }

  MouseStandard     = 1;   { Standardowy         }
  MouseUpArrow      = 2;   { Strzaˆka w g¢r©     }
  MouseDownArrow    = 3;   { Strzaˆka w d¢ˆ      }
  MouseLeftArrow    = 4;   { Strzaˆka w lewo     }
  MouseRightArrow   = 5;   { Strzaˆka w prawo    }
  MouseCheckMark    = 6;   { "Fajka"             }
  MouseUpHand       = 7;   { Dˆoä w g¢r©         }
  MouseDownHand     = 8;   { Dˆoä w d¢ˆ          }
  MouseLeftHand     = 9;   { Dˆoä w lewo         }
  MouseRightHand    = 10;  { Dˆoä w prawo        }
  MouseStopHand     = 11;  { Dˆoä otwarta        }
  MouseHourGlass    = 12;  { Zegarek             }
  MouseDiagCross    = 13;  { Krzy¾yk             }
  MouseRectCross    = 14;  { Krzy¾yk prostok¥tny }
  MouseRectBox      = 15;  { Prostok¥t           }
  MouseTargetCross  = 16;  { Celownik kwadratowy }
  MouseTargetCircle = 17;  { Celownik okr¥gˆy    }
  MouseTargetBox    = 18;  { Prostok¥t           }
  MouseQuestionMark = 19;  { Znak zapytania      }
  MaxMouseMask      = MouseQuestionMark;

  MouseMovement        = 1;
  LeftButtonPressed    = 2;
  LeftButtonReleased   = 4;
  RightButtonPressed   = 8;
  RightButtonReleased  = 16;
  CenterButtonPressed  = 32;
  CenterButtonReleased = 64;

implementation

uses
  DOS, Graph;

const
  Yes = True;
  No  = False;

  ANDPut = Yes;
  XORPut = No;

type
  TMaskType =
    record
      Def: array[Boolean, 0..15] of Word;
      HotX, HotY: ShortInt;
    end{TMaskType};
  TMaskArray = array[MouseStandard..MouseQuestionMark] of TMaskType;

  TCursorType = array[1..67] of Integer;
  TCursorArray = array[MouseStandard..MouseQuestionMark] of TCursorType;

const
  MaskArray: TMaskArray =

{ Standard }
 ((Def: (($3FFF,$1FFF,$0FFF,$07FF,$03FF,$01FF,$00FF,$007F,
          $003F,$001F,$01FF,$10FF,$30FF,$F87F,$F87F,$FC7F),
         ($0000,$4000,$6000,$7000,$7800,$7C00,$7E00,$7F00,
          $7F80,$7C00,$6C00,$4600,$0600,$0300,$0300,$0000));
         HotX: -1; HotY: -1),

{ UpArrow }
  (Def: (($F9FF,$F0FF,$E07F,$E07F,$C03F,$C03F,$801F,$801F,
          $000F,$000F,$F0FF,$F0FF,$F0FF,$F0FF,$F0FF,$F0FF),
         ($0000,$0600,$0F00,$0F00,$1F80,$1F80,$3FC0,$3FC0,
          $7FE0,$0600,$0600,$0600,$0600,$0600,$0600,$0000));
         HotX: 5; HotY: 0),

{ DownArrow }
  (Def: (($F0FF,$F0FF,$F0FF,$F0FF,$F0FF,$F0FF,$000F,$000F,
          $801F,$801F,$C03F,$C03F,$E07F,$E07F,$F0FF,$F9FF),
         ($0000,$0600,$0600,$0600,$0600,$0600,$0600,$7FE0,
          $3FC0,$3FC0,$1F80,$1F80,$0F00,$0F00,$0600,$0000));
         HotX: 5; HotY: 15),

{ LeftArrow }
  (Def: (($FE1F,$F01F,$0000,$0000,$0000,$F01F,$FE1F,$FFFF,
          $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF),
         ($0000,$00C0,$07C0,$7FFE,$07C0,$00C0,$0000,$0000,
          $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000));
         HotX: 0; HotY: 3),

{ RightArrow }
  (Def: (($F87F,$F80F,$0000,$0000,$0000,$F80F,$F87F,$FFFF,
          $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF),
         ($0000,$0300,$03E0,$7FFE,$03E0,$0300,$0000,$0000,
          $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000));
         HotX: 15; HotY: 3),

{ CheckMark }
  (Def: (($FFF8,$FFF0,$FFE1,$FFC3,$FF87,$FF0F,$0E1F,$043F,
          $807F,$E0FF,$F1FF,$FBFF,$FFFF,$FFFF,$FFFF,$FFFF),
         ($0000,$0006,$000C,$0018,$0030,$0060,$00C0,$7180,
          $1B00,$0E00,$0400,$0000,$0000,$0000,$0000,$0000));
         HotX: 5; HotY: 11),

{ UpHand }
  (Def: (($E1FF,$E1FF,$E1FF,$E1FF,$E000,$E000,$E000,$0000,
          $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000),
         ($1E00,$1200,$1200,$1200,$13FF,$1249,$1249,$F249,
          $9001,$9001,$9001,$8001,$8001,$8001,$8001,$FFFF));
         HotX: 5; HotY: 0),

{ DownHand }
  (Def: (($0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
          $0000,$E000,$E000,$E000,$E1FF,$E1FF,$E1FF,$E1FF),
         ($FFFF,$8001,$8001,$8001,$8001,$9001,$9001,$9001,
          $F249,$1249,$1249,$13FF,$1200,$1200,$1200,$1E00));
         HotX: 5; HotY: 15),

{ LeftHand }
  (Def: (($FFFF,$FF8F,$FF07,$FF03,$FF81,$8000,$0000,$0000,
          $0000,$8000,$F000,$F800,$F800,$FC00,$FC01,$FC03),
         ($0000,$0000,$0070,$0048,$0024,$0032,$7FF2,$800A,
          $7FF6,$0412,$07F2,$0212,$03F2,$0116,$01FC,$0000));
         HotX: 0; HotY: 7),

{ RightHand }
  (Def: (($FFFF,$F1FF,$E0FF,$C0FF,$81FF,$0001,$0000,$0000,
          $0000,$0001,$000F,$001F,$001F,$003F,$803F,$C03F),
         ($0000,$0000,$0E00,$1200,$2400,$4C00,$4FFE,$5001,
          $6FFE,$4820,$4FE0,$4840,$4FC0,$6880,$3F80,$0000));
         HotX: 15; HotY: 7),

{ StopHand }
  (Def: (($FE3F,$F80F,$F007,$F003,$F001,$F001,$0001,$0001,
          $0001,$0001,$8001,$C001,$C001,$E003,$F007,$F80F),
         ($0000,$01C0,$0770,$0550,$055C,$0554,$0554,$7554,
          $5554,$4FFC,$2804,$1004,$180C,$0C18,$07F0,$0000));
         HotX: 7; HotY: 7),

{ HourGlass }
  (Def: (($0000,$0000,$0000,$0000,$8001,$C003,$E007,$F00F,
          $E007,$C003,$8001,$0000,$0000,$0000,$0000,$FFFF),
         ($0000,$7FFE,$6006,$300C,$1818,$0C30,$0660,$03C0,
          $0660,$0C30,$1998,$33CC,$67E6,$7FFE,$0000,$0000));
         HotX: 7; HotY: 7),

{ DiagCross }
  (Def: (($07E0,$0180,$0000,$C003,$F00F,$C003,$0000,$0180,
          $07E0,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF),
         ($0000,$700E,$1C38,$0660,$03C0,$0660,$1C38,$700E,
          $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000));
         HotX: 7; HotY: 4),

{ RectCross }
  (Def: (($FC3F,$FC3F,$FC3F,$0000,$0000,$0000,$FC3F,$FC3F,
          $FC3F,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF),
         ($0000,$0180,$0180,$0180,$7FFE,$0180,$0180,$0180,
          $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000));
         HotX: 7; HotY: 4),

{ RectBox }
  (Def: (($FFFF,$FFFF,$0000,$0000,$0000,$1FF8,$1FF8,$1FF8,
          $1FF8,$1FF8,$1FF8,$1FF8,$0000,$0000,$0000,$FFFF),
         ($0000,$0000,$0000,$7FFE,$4002,$4002,$4002,$4002,
          $4002,$4002,$4002,$4002,$4002,$7FFE,$0000,$0000));
         HotX: 7; HotY: 8),

{ TargetCross }
  (Def: (($FFFF,$FFFF,$FC7F,$FC7F,$FC7F,$FC7F,$FC7F,$06C1,
          $0101,$06C1,$FC7F,$FC7F,$FC7F,$FC7F,$FC7F,$FFFF),
         ($0000,$0000,$0000,$0100,$0100,$0100,$0100,$0000,
          $783C,$0000,$0100,$0100,$0100,$0100,$0000,$0000));
         HotX: 7; HotY: 8),

{ TargetCircle }
  (Def: (($FFFF,$FFFF,$F01F,$C007,$8003,$0441,$0C61,$06C1,
          $0101,$06C1,$0C61,$0441,$8003,$C007,$F01F,$FFFF),
         ($0000,$0000,$0000,$07C0,$1930,$3118,$610C,$600C,
          $783C,$600C,$610C,$3118,$1930,$07C0,$0000,$0000));
         HotX: 7; HotY: 8),

{ TargetBox }
  (Def: (($FFFF,$FFFF,$0001,$0001,$0001,$1C71,$1C71,$06C1,
          $0101,$06C1,$1C71,$1C71,$0001,$0001,$0001,$FFFF),
         ($0000,$0000,$0000,$7FFC,$4104,$4104,$4104,$4004,
          $783C,$4004,$4104,$4104,$4104,$7FFC,$0000,$0000));
         HotX: 7; HotY: 8),

{ QuestionMark }
  (Def: (($FFFF,$E00F,$C007,$8003,$0001,$0001,$0001,$0001,
          $0001,$0001,$0001,$0001,$0001,$8003,$C007,$E00F),
         ($0000,$0000,$1FF0,$3FF8,$783C,$739C,$739C,$7F3C,
          $7E7C,$7E7C,$7FFC,$7E7C,$7E7C,$3FF8,$1FF0,$0000));
         HotX: 7; HotY: 7));

  MouseIntr = $33;

var
  CursorArray: TCursorArray;
  Regs: Registers;
  OldImageX, OldImageY: Integer;
  OldMask, SegOldHandler, OfsOldHandler: Integer;
  MouseView, FirstStart, Visible, Busy, YesMouse: Boolean;

procedure Handler
  (Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP : Integer); interrupt;
begin
  if YesMouse then
    ReadMouse;
  asm
    MOV SP, BP
    POP BP
    POP ES
    POP DS
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RETF
  end{asm};
end {Handler};

function InitMouse;
var
  I, X, Y: Byte;
begin
  EnableMouse;
  Busy := No;
  Visible := No;
  MouseView := No;
  with Regs do
    begin
      InitMouse := No;
      AX := 0;
      Intr(mouseIntr, Regs);
      if (AX and BX = 0) then
        Exit;
      InitMouse := Yes;
    end{begin};
  MouseCursor := MouseStandard;
  if FirstStart then
    begin
      for I := MouseStandard to MouseQuestionMark do
        with MaskArray[I] do
          begin
            for Y := 0 to 15 do
              begin
                for X := 0 to 15 do
                  begin
                    if ((Def[ANDPut][Y] shl X) and $8000 = 0) and
                       ((Def[XORPut][Y] shl X) and $8000 = 0) then
                      PutPixel(X, Y, 15) else
                      PutPixel(X, Y, 0);
                  end{begin};
              end{begin};
            GetImage(0, 0, 15, 15, CursorArray[I]);
          end{begin};
    end{begin};
  with Regs do
    begin
      CX := MouseMovement or
            LeftButtonPressed or
            LeftButtonReleased or
            RightButtonPressed or
            RightButtonReleased or
            CenterButtonPressed or
            CenterButtonReleased;
      ES := Seg(Handler);
      DX := Ofs(Handler);
      AX := 20;
      Intr($33, Regs);
      OldMask := CX;
      SegOldHandler := ES;
      OfsOldHandler := DX;
    end{begin};
  ReadMouse;
  FirstStart := No;
  MouseArea(24, 24, 1000, 744);
end{InitMouse};

procedure DoneMouse;
begin
  HideMouse;
  with Regs do
    begin
      CX := OldMask;
      ES := SegOldHandler;
      DX := OfsOldHandler;
      AX := 12;
      Intr($33, Regs);
    end{begin};
end{DoneMouse};

procedure HideBGIMouse;
begin
  if Visible then
    PutImage(OldImageX, OldImageY, CursorArray[MouseCursor], Graph.XORPut);
  Visible := No;
end{HideBGIMouse};

procedure ShowBGIMouse;
var
  I, J: Byte;
  ImageX, ImageY: Integer;
  MyImage: TCursorType;
begin
  if Busy or not MouseView then
    Exit;
  Busy := Yes;
  with MaskArray[MouseCursor] do
    begin
      ImageX := MouseX - HotX;
      ImageY := MouseY - HotY;
    end{begin};
  HideBGIMouse;
  PutImage(ImageX, ImageY, CursorArray[MouseCursor], Graph.XORPut);
  EnableMouse;
  OldImageX := ImageX;
  OldImageY := ImageY;
  Visible := Yes;
  Busy := No;
end{ShowBGIMouse};

procedure ShowMouse;
begin
  MouseView := Yes;
  ShowBGIMouse;
end{ShowMouse};

procedure HideMouse;
begin
  MouseView := No;
  HideBGIMouse;
end{HideMouse};

procedure HideInMouse(X1, Y1, X2, Y2: Integer);
begin
  DisableMouse;
  if MouseIn(X1, Y1, X2, Y2, 15) then
    HideMouse;
end{HideInMouse};

procedure ShowInMouse;
begin
  ShowMouse;
  EnableMouse;
end{ShowInMouse};

procedure ReadMouse;
begin
  with Regs do
    begin
      AX := 3;
      Intr($33, Regs);
      MouseButtons := BX;
      MouseX := CX shr 2;
      MouseY := DX shr 2;
    end{begin};
  ShowBGIMouse;
end{ReadMouse};

procedure SetMouseCursor;
begin
  if MouseCursor = CursorNumber then
    Exit;
  HideMouse;
  MouseCursor := CursorNumber;
  ReadMouse;
  ShowMouse;
end{SetMouseCursor};

procedure MouseArea;
begin
  AreaX1 := X1 shl 2;
  AreaX2 := X2 shl 2;
  AreaY1 := Y1 shl 2;
  AreaY2 := Y2 shl 2;
  HideMouse;
  with Regs do
    begin
      AX := 7;
      CX := AreaX1;
      DX := AreaX2;
      Intr($33, Regs);
      AX := 8;
      CX := AreaY1;
      DX := AreaY2;
      Intr($33, Regs);
    end{begin};
  ReadMouse;
  ShowMouse;
end{MouseArea};

function MouseIn;
begin
  MouseIn := PointerIn(MouseX, MouseY, X1, Y1, X2, Y2, D);
end{MouseIn};

function PointerIn;
begin
  if (X1>X2) then
    SwapInteger(X1, X2);
  if (Y1>Y2) then
    SwapInteger(Y1, Y2);
  PointerIn := (X>=X1-D) and (X<=X2+D) and (Y>=Y1-D) and (Y<=Y2+D);
end{PointerIn};

procedure GoToMouse;
begin
  if YesMouse then
    with Regs do
      begin
        AX := $4;
        CX := X;
        DX := Y;
      end{begin};
  Intr($33, Regs);
  ReadMouse;
end{GoToMouse};

procedure SwapInteger;
begin
  A := A xor B;
  B := A xor B;
  A := A xor B;
end{SwapInteger};

procedure EnableMouse;
begin
  YesMouse := Yes;
  ReadMouse;
end{EnableMouse};

procedure DisableMouse;
begin
  YesMouse := No;
end{DisableMouse};

begin
  FirstStart := Yes;
end{Mouse}.