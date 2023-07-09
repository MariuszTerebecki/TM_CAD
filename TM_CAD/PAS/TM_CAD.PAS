{$DEFINE COMERCIAL}

{$IFDEF COMERCIAL}
{$DEFINE KONKURS}
{{$DEFINE INFORMATYCZNY}
{{$DEFINE PRàBA}
{$ENDIF}

program TM_CAD;

uses
  App,       { Obiekty przyspieszaj¥ce tworzenie aplikacji             }
  HelpFile,  { Obsˆuga pomocy                                          }
  Drivers,   { " Sterowniki " biblioteczne Turbo Vision                }
  Objects,   { Podstawowe obiekty biblioteki Turbo Vision              }
  Menus,     { Menu i linia statusu                                    }
  HelpCAD,   { Staˆe pomocy programu                                   }
  Views,     { Widoki i podwidoki biblioteczne Turbo Vision            }
  MsgBox,    { Gotowe okienka komunikat¢w                              }
  StdDlg,    { Operacje na plikach i katalogach                        }
  GraphEdit, { Edycja rysunku                                          }
  Gadgets,   { Gadget'y : zegarek + informacja o ilo˜ci wolnej pami©ci }
  Graph,     { Obsˆuga grafiki                                         }
  Memory,    { Obsˆuga pami©ci                                         }
  Dos,       { Obsˆuga plik¢w i operacji dyskowych                     }
  Dialogs,   { Okienka dialogowe                                       }
  GraphicalObjects; { Obiekty graficzne i operacje na nich             }

const
  Yes = True;
  No  = False;

  { Paleta kolor¢w cz©˜ci tekstowej programu }
  CCAD = #$17#$70#$78#$74#$1F#$47#$1E#$17#$1F#$1A#$17#$4F#$1E#$71#$00#$37 +
         #$3F#$3A#$13#$13#$3E#$21#$00#$70#$7F#$7A#$13#$13#$70#$1F#$00#$70 +
         #$7F#$7A#$17#$1F#$70#$70#$7E#$74#$60#$6B#$6F#$67#$6E#$70#$30#$3F +
         #$3E#$1F#$1B#$1A#$5F#$75#$17#$5F#$30#$2F#$2F#$31#$2F#$00#$00#$17 +
         #$1F#$1A#$71#$71#$1E#$17#$1F#$1E#$20#$2B#$2F#$78#$2E#$10#$30#$3F +
         #$3E#$70#$2F#$7A#$20#$12#$31#$31#$30#$2F#$3E#$31#$13#$38#$00#$37 +
         #$3F#$3A#$13#$13#$3E#$30#$3F#$3E#$20#$2B#$2F#$78#$2E#$30#$70#$7F +
         #$7E#$1F#$2F#$1A#$20#$32#$31#$71#$70#$2F#$7E#$71#$13#$38#$00;

  { Paleta kolor¢w okienek pomocy }
  CCADHelp = #$80#$81#$82#$83#$84#$85#$86#$87;

  { Staˆe komend }
  cmNone        = 255;
  cmAbout       = 100;
  cmEditGraph   = 101;
  cmPrint       = 102;
  {$IFDEF PRàBA}
  cmSaveTxt     = 103;
  cmLoadTxt     = 104;
  {$ENDIF}

  { Staˆe pomocy }
  hcHelpInHelp  = 0;

var
  GraphFileName: PathStr;

{$IFDEF COMERCIAL}
{$IFDEF KONKURS}
{$IFNDEF PRàBA}

function Konkurs: Boolean;
const
  Message: string[71] = ^C'Wersja przeznaczona wyˆ¥cznie na'#13 +
{$IFDEF INFORMATYCZNY}
                        ^C'III Wojew¢dzki Kokurs Informatyczny'#172;
{$ELSE}
                        ^C'Konkurs Mˆodych Mistrz¢w Techniki'#91;
{$ENDIF}
var
  I, J: Byte;
begin
  I := 0;
  for J := 1 to Length(Message) do
    I := I xor Byte(Message[J]);
  Message[0] := Char(Pred(Length(Message)));
  if I <> 0 then
    begin
      MessageBox(^C'Pr¢ba zmiany komunikatu', nil, mfError + mfOkButton);
      Konkurs := No;
    end{begin} else
    begin
      MessageBox(Message, nil, mfInformation + mfOkButton);
      Konkurs := Yes;
    end{begin};
end;

{$ENDIF}
{$ENDIF}
{$ENDIF}

{$IFNDEF COMERCIAL}

type
  PCADBackground = ^TCADBackground;
  TCADBackground =
    object(TBackground)
      Text: TTitleStr;
      constructor Init(var Bounds: TRect; AText: TTitleStr);
      procedure Draw; virtual;
    end{TCADBackground};

constructor TCADBackground.Init(var Bounds: TRect; AText: TTitleStr);
begin
  inherited Init(Bounds, ' ');
  Text := AText;
  while Length(Text) < SizeOf(TTitleStr) - 1 do
    Text := Concat(Text, AText);
end{TCADBackground.Init};

procedure TCADBackground.Draw;
var
  DrawBuffer: TDrawBuffer;
begin
  MoveStr(DrawBuffer, Text, GetColor(1));
  with Size do
    WriteLine(0, 0, X, Y, DrawBuffer);
end{TCADBackground.Draw};

type
  { Nowy "Desktop" z informacj¥ o demonstracyjnym przeznaczeniu programu }
  PCADDesktop = ^TCADDesktop;
  TCADDesktop =
    object(TDesktop)
      procedure InitBackground; virtual;
    end{TCADDesktop};

procedure TCADDesktop.InitBackground;
var
  Rect: TRect;
begin
  GetExtent(Rect);
  Background := New(PCADBackground, Init(Rect,
    '  Û  TM CAD - wersja demonstracyjna  Û  '));
end{TCADDesktop.InitBackground};

{$ENDIF}

type
  { Linia statusu z tekstem pomocy kontekstowych }
  PCADStatusLine = ^TCADStatusLine;
  TCADStatusLine =
    object(TStatusLine)
      function Hint(AHelpCtx: Word): string; virtual;
    end{TStatusLine};

{******************************************}
{*   Uaktualnianie tre˜ci wy˜wietlanej    *}
{*        w lini statusu pomocy           *}
{******************************************}

function TCADStatusLine.Hint;

{******************************************}
{*        Nazwa pliku bez ˜cie¾ki         *}
{******************************************}

function SomeFileName: PathStr;
var
  S: string;
begin
  S := GraphFileName;
  while (Pos('\', S) <> 0) do
    Delete(S, 1, 1);
  SomeFileName := S;
end{TStatusLine.Hint.SomeFileName};

begin
  case AHelpCtx of
    hcSystem    : Hint := 'Podstawowe operacje i informacje systemowe';
    hcAbout     : Hint := 'Informacje o autorze programu';
    hcDosShell  : Hint := 'Opuszczenie programu w celu wydania polecenia DOS-u';
    hcExit      : Hint := 'Wyj˜cie z programu';
    hcFiles     : Hint := 'Operacje zwi¥zane zachowywaniem i drukowaniem';
    hcOpen      : Hint := 'Wczytanie rysunku zapisanego na dysku';
    hcSave      : Hint := 'Zachowanie edytowanego rysunku na dysku';
    hcSaveAs    : Hint := 'Zachowanie rysunku na dysku pod zmienion¥ nazw¥';
    hcChangeDir : Hint := 'Zmiana aktualnego katalogu oraz dysku';
    hcPrint     : Hint := 'Wydrukowanie rysunku na drukarce HP Laser Jet';
    hcEdit      : Hint := 'Przeˆ¥czenie programu na edycj© rysunku';
    hcHelp      : Hint := 'Otworzenie okienka z dodatkowymi informacjami';
    else if GraphFileName <> '*.TMC' then
           Hint := 'Przetwarzany plik : ' + SomeFileName else
           Hint := 'Rysunek nie posiada nazwy';
  end{case};
end{TStatusLine.Hint};

type
  { Podstawowa aplikacja programu }
  PCADApplication  = ^TCADApplication;
  TCADApplication  =
    object(TApplication)
      Clock           : PClockView;
      Heap            : PHeapView;
      GraphCollection : PCollection;
      ChangePicture   : Boolean;
      constructor Init;
      destructor Done; virtual;
      function GetPalette: PPalette; virtual;
      procedure InitMenuBar; virtual;
      procedure InitStatusLine; virtual;
      procedure GetEvent(var Event: TEvent); virtual;
      procedure HandleEvent(var Event: TEvent); virtual;
      procedure WriteShellMsg; virtual;
      procedure Idle; virtual;
      {$IFNDEF COMERCIAL}
      procedure InitDesktop; virtual;
      {$ENDIF}
    end{TApplication};

{******************************************}
{*      Inicjacja gˆ¢wnego obiektu        *}
{******************************************}

constructor TCADApplication.Init;
var
  Rect: TRect;
begin
  ChangePicture := No;
  GraphFileName := '*.TMC';
  inherited Init;
  { Rejestracja podtawowych objekt¢w }
{  RegisterObjects; { Uaktywni† po rozbudowaniu programu }
{  RegisterViews;   { Uaktywni† po rozbudowaniu programu }
{  RegisterMenus;   { Uaktywni† po rozbudowaniu programu }
{  RegisterApp;     { Uaktywni† po rozbudowaniu programu }
  RegisterHelpFile;
  { Inicjacja gadget'¢w : }
  { zegarka czasu systemowego ... }
  GetExtent(Rect);
  with Rect do
    begin
      A.X := B.X - 9;
      B.Y := Succ(A.Y);
    end{begin};
  Clock := New(PClockView, Init(Rect));
  Insert(Clock);
  { i informatora o ilo˜ci wolnej pami©ci }
  GetExtent(Rect);
  with Rect do
    begin
      Dec(B.X);
      A.X := B.X - 9;
      A.Y := Pred(B.Y);
    end{begin};
  Heap := New(PHeapView, Init(Rect));
  Insert(Heap);
  GraphCollection := New(PCollection, Init(100, 50));
  {$IFDEF COMERCIAL}
  {$IFDEF KONKURS}
  {$IFNDEF PRàBA}
  if not Konkurs then
    begin
      Done;
      Halt;
    end{begin};
  {$ENDIF}
  {$ENDIF}
  {$ELSE}
  DisableCommands([cmPrint, cmSave, cmSaveAs]);
  {$ENDIF}
end{TApplication.Init};

{******************************************}
{*      Destrukcja gˆ¢wnego obiektu       *}
{******************************************}

destructor TCADApplication.Done;
begin
  Dispose(GraphCollection, Done);
  inherited Done;
end{TAppllication.Done};

{******************************************}
{*    Udost©pnienie na zewn¥trz palety    *}
{*  wykorzystywanych kolor¢w i atrybut¢w  *}
{******************************************}

function TCADApplication.GetPalette;
const
  CNewColor      = CCAD           + CHelpColor;
  CNewBlackWhite = CAppBlackWhite + CHelpBlackWhite;
  CNewMonochrome = CAppMonochrome + CHelpMonochrome;
  Palette: array[apColor..apMonochrome] of string[Length(CNewColor)] =
    ( CNewColor, CNewBlackWhite, CNewMonochrome );
begin
  GetPalette := Addr(Palette[AppPalette]);
end{TApplication.GetPalette};

{******************************************}
{*     Inicjacja belki menu gˆ¢wnego      *}
{******************************************}

procedure TCADApplication.InitMenuBar;
var
  R: TRect;
begin
  GetExtent(R);
  R.B.Y := Succ(R.A.Y);
  MenuBar := New(PMenuBar, Init(R, NewMenu(
    NewSubmenu('~ð~', hcSystem, NewMenu(
      NewItem('~A~utor', '', kbAltA, cmAbout, hcAbout,
      NewLine(
        NewItem('~D~OS na chwil©', 'Alt-D', kbAltD, cmDosShell, hcDosShell,
        NewItem('~W~yj˜cie z programu', 'Esc', kbEsc, cmQuit, hcExit,
        nil))))),
    NewSubMenu('~P~liki', hcFiles, NewMenu(
      NewItem('~O~tw¢rz', 'F2', kbF2, cmOpen, hcOpen,
      NewItem('~Z~achowaj', 'F3', kbF3, cmSave, hcSave,
      NewItem('Zachowaj ~j~ako', 'Alt-F3', kbAltF3, cmSaveAs, hcSaveAs,
      NewLine(
        NewItem('Zmieä ~k~atalog', 'F4', kbF4, cmChangeDir, hcChangeDir,
      NewLine(
        NewItem('~D~rukowanie', 'F5', kbF5, cmPrint, hcPrint,
        nil)))))))),
    NewItem('E~d~ycja', '', kbAltR, cmEditGraph, hcEdit,
    NewItem('Po~m~oc', '', kbF1, cmHelp, hcHelp,
  nil)))))));
end{TApplication.InitMenuBar};

{******************************************}
{*       Inicjacja lini statusu           *}
{******************************************}

procedure TCADApplication.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y := Pred(R.B.Y);
  StatusLine := New(PCADStatusLine, Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~Alt-W~ Wyj˜cie', kbAltW, cmQuit,
      NewStatusKey('', kbShiftF1, hcNoContext,
      NewStatusKey('', kbF10, cmMenu,
      NewStatusKey('', kbF1, cmHelp,
      {$IFDEF PRàBA}
      NewStatusKey('', kbCtrlF9, cmSaveTxt,
      NewStatusKey('', kbCtrlF10, cmLoadTxt,
      nil)))))),
      {$ELSE}
      nil)))),
      {$ENDIF}
    nil)))
end{TApplication.InitStatusLine};

{******************************************}
{*   Odczyt i reakcja na zdarzenie POMOC  *}
{******************************************}

procedure TCADApplication.GetEvent;
var
  Window     : PWindow;
  HelpFile   : PHelpFile;
  HelpStream : PDosStream;
const
  HelpInUse: Boolean = No;
begin
  inherited GetEvent(Event);
  with Event do
    case What of
      evCommand:
        if (Command = cmHelp) and (not HelpInUse) then
          begin
            HelpInUse := Yes;
            HelpStream := New(PDosStream, Init('HelpCAD.HLP', stOpenRead));
            HelpFile := New(PHelpFile, Init(HelpStream));
            if HelpStream^.Status<>stOk then
              begin
                MessageBox(^C'Brak pliku pomocy', nil, mfError + mfOkButton);
                Dispose(HelpFile, Done);
              end else
              begin
                Window := New(PHelpWindow, Init(HelpFile, GetHelpCtx));
                if ValidView(Window)<>nil then
                  begin
                    with Window^ do
                      HelpCtx := hcHelpInHelp;
                    ExecView(Window);
                    Dispose(Window, Done);
                  end{begin};
                ClearEvent(Event);
              end{begin};
            HelpInUse := No;
            ClearEvent(Event);
          end{begin};
    end{case};
end{TApplication.GetEvent};

{******************************************}
{*        Interpretacja zdarzeä           *}
{******************************************}

procedure TCADApplication.HandleEvent;

{******************************************}
{*     Informacje o autorze programu      *}
{******************************************}

procedure AboutBox;
var
  AboutDialog : PDialog;
  Control     : PView;
  Rect        : TRect;
begin
  with Rect do
    Assign(0, 0, 40, 11);
  AboutDialog := New(PDialog, Init(Rect, 'Autor'));
  with AboutDialog^ do
    begin
      Options := Options or ofCentered;
      with Rect do
        begin
          Grow(-1, -1);
          Dec(B.Y, 3);
        end{begin};
      Insert(New(PStaticText, Init(Rect,
             #13 + ^C'TM CAD - wersja prototypowa'#13 +
             #13 + ^C'Copyright (c) 1995 - G¢ra'#13 +
             #13 + ^C'Mariusz Terebecki')));
      with Rect do
        Assign(2, 8, 38, 10);
      Insert(New(PButton, Init(Rect, '~D~alej', cmOk, bfDefault)));
    end{begin};
  if ValidView(AboutDialog) <> nil then
    begin
      with Desktop^ do
        ExecView(AboutDialog);
      Dispose(AboutDialog, Done);
    end{begin};
end{AboutBox};

{******************************************}
{*       Zmiana bie¾¥cego katalogu        *}
{******************************************}

procedure ChangeDir;
{ Zmiana bie¾¥cego katalogu }
var
  ChangeDirDialog: PChDirDialog;
begin
  ChangeDirDialog := New(PChDirDialog, Init(cdNormal + cdHelpButton, 101));
  with ChangeDirDialog^ do
    HelpCtx := hcChangeDirBox;
  ExecuteDialog(ChangeDirDialog, nil);
end{TApplication.HandleEvent.ChangeDir};

const
  DriverName = 'VESA16';
  DriverMode = 1;
  BGIPath    = 'SYSTEM';

var
  Driver, Mode, ErrCode: Integer;

{******************************************}
{*     Powr¢t z trybu edycji rysunku      *}
{******************************************}

procedure GraphicsStop;
begin
  CloseGraph;
  InitMemory;
  InitVideo;
  InitEvents;
  InitSysError;
  Redraw;
end{TApplication.HandleEvent.TMCEdit.GraphicsStop};

{******************************************}
{*      Rozpocz©cie edycji rysunku        *}
{******************************************}

function GraphicsStart(var Result: Integer): Boolean;

{******************************************}
{*       Detekcja karty graficznej        *}
{******************************************}

function TestDetect: Integer; far;
begin
  TestDetect := 1;
end{TApplication.HandleEvent.TMCEdit.GraphicsStart.TestDetect};

{******************************************}
{*           Katalog programu             *}
{******************************************}

function MyDirectory: PathStr;
var
  Path: string;
begin
  {$IFDEF IDE}
  MyDirectory := '';
  {$ELSE}
  Path := ParamStr(0);
  while Path[Length(Path)] <> '\' do
    System.Delete(Path, Length(Path), 1);
  MyDirectory := Path;
  {$ENDIF}
end{TApplication.HandleEvent.TMCEdit.GraphicsStart.MyDirectory};

begin
  GraphicsStart := No;
  DoneSysError;
  DoneEvents;
  DoneVideo;
  DoneMemory;
  Driver := InstallUserDriver(DriverName, @TestDetect);
  Result := GraphResult;
  if Result = grOk then
    begin
      Mode   := DriverMode;
      InitGraph(Driver, Mode, MyDirectory + BGIPath);
      Result := GraphResult;
    end{begin};
  if Result <> grOk then
    begin
      GraphicsStop;
      Exit;
    end{begin};
  GraphicsStart := Yes;
end{TApplication.HandleEvent.TMCEdit.GraphicsStart};

{******************************************}
{*      Edycja rysunku technicznego       *}
{******************************************}

procedure GraphEdit;
{ Edycja rysunku }
var
  Ok          : Boolean;
  ErrorString : string;
begin
  if GraphicsStart(ErrCode) then
    begin
      ChangePicture := EditGraph(GraphCollection, Ok);
      GraphicsStop;
      if not Ok then
        MessageBox(^C'Bˆ¥d edycji.', nil, mfError or mfOkButton)
    end else
    MessageBox(^C'Bˆ¥d obsˆugi grafiki:'#13#10#3 +
               GraphErrorMsg(ErrCode) + '.', nil,
               mfError or mfOkButton);
end{TApplication.HandleEvent.GraphEdit};

{******************************************}
{*      Komunikat bˆ©du strumienia        *}
{******************************************}

procedure FileStatusBox(ErrorNumber: Integer);
var
  ErrorName: string;
begin
  case ErrorNumber of
    stOk         : ErrorName := 'Bez bˆ©du';
    stError      : ErrorName := 'Bˆ¥d dost©pu';
    stInitError  : ErrorName := 'Bˆ¥d inicjalizacji strumienia';
    stReaderror  : ErrorName := 'Odczyt poza koäcem strumienia';
    stWriteError : ErrorName := 'Bˆ¥d zapisu do strumienia';
    stGetError   : ErrorName := 'Odczyt obiektu niezarejestrowanego';
    stPutError   : ErrorName := 'Zapis obiektu niezarejestrowanego';
    else           ErrorName := 'Nieznany bˆ¥d';
  end{case};
  if ErrorName = 'Bez bˆ©du' then
    ChangePicture := No else
    MessageBox(^C'Bˆ¥d obsˆugi plik¢w:'#13#10#3 + ErrorName,
               nil, mfError + mfOkButton);
end{TApplication.HandleEvent.FileStatusBox};

{$IFDEF COMERCIAL}

{******************************************}
{*     Zachowanie edytowanego rysunku     *}
{******************************************}

procedure GraphSave(As: Boolean);
var
  Stream   : TStream;
  FileSave : PFileDialog;
  SaveOk   : Boolean;
begin
  with GraphCollection^ do
    if Count > 0 then
      begin
        SaveOk := ( ( not As ) and ( GraphFileName <> '*.TMC' ) );
        New(FileSave, Init('*.TMC', 'Zachowaj', '~N~azwa',
                           fdOkButton + fdReplaceButton + fdHelpButton,
                           101));
        if ( not SaveOk ) then
          begin
            with FileSave^ do
              HelpCtx := hcFileSaveBox;
            SaveOk :=
              ( ExecuteDialog(FileSave, Addr(GraphFileName)) <> cmCancel );
          end{begin};
        if SaveOk then
          FileStatusBox(SaveGraph(GraphFileName, GraphCollection));
      end{begin} else
      MessageBox(^C'Brak rysunku do zapisu', nil, mfError or mfOkButton);
end{TApplication.HandleEvent.GraphSave};

{******************************************}
{*     Okienko potwierdzenia zapisu       *}
{******************************************}

procedure IfSaved;
begin
  with GraphCollection^ do
    if (Count > 0) and ChangePicture then
      case MessageBox(^C'Czy zachowa† rysunek ?',
                      nil, mfConfirmation + mfYesNoCancel) of
        cmYes      : GraphSave(Yes);
      end{case};
end{TApplication.HandleEvent.IsSaved};

{******************************************}
{*    Drukowanie rysunku technicznego     *}
{******************************************}

procedure Print;
begin
  if ( MessageBox(^C'Wymagana poprawnie zainstalowana drukarka HP Laser' +
                    ' Jet. W przeciwnym razie mo¾na zawiesi† komputer.',
                  nil, mfWarning + mfOkButton + mfCancelButton) = cmOk ) then
    if GraphicsStart(ErrCode) then
      begin
        PrintHPLaserJet(GraphCollection);
        GraphicsStop;
      end{begin} else
      MessageBox(^C'Bˆ¥d obsˆugi grafiki:'#13#10#3 +
                   GraphErrorMsg(ErrCode) + '.',
                 nil, mfError or mfOkButton);
end{TApplication.HandleEvent.Print};

{$ENDIF}

{******************************************}
{*           Wczytanie rysunku            *}
{******************************************}

procedure GraphLoad;
var
  Stream: TStream;
  FileLoad: PFileDialog;
begin
  New(FileLoad, Init('*.TMC', 'Otw¢rz', '~N~azwa',
                     fdOpenButton + fdHelpButton, 100));
  with FileLoad^ do
    HelpCtx := hcFileLoadBox;
  {$IFDEF COMERCIAL}
  IfSaved;
  {$ENDIF}
  if (ExecuteDialog(FileLoad, Addr(GraphFileName)) <> cmCancel) then
   FileStatusBox(LoadGraph(GraphFileName, GraphCollection));
end{TApplication.HandleEvent.GraphLoad};

{******************************************}
{*        Brak obsˆugi zdarzenia          *}
{******************************************}

procedure NoCommand;
begin
  MessageBox(^C'Brak obsˆugi zdarzenia:'#13#10#3 +
             GraphErrorMsg(ErrCode) + '.', nil,
             mfError or mfOkButton);
end{TApplication.HandleEvent.Print};

begin
  with Event do
    case What of
      evCommand: case Command of
                   cmNone       : NoCommand;
                   cmAbout      : AboutBox;
                   cmOpen       : GraphLoad;
                   cmEditGraph  : GraphEdit;
                   cmChangeDir  : ChangeDir;
                   {$IFDEF COMERCIAL}
                   cmQuit       : IfSaved;
                   cmPrint      : Print;
                   cmSave       : GraphSave(No);
                   cmSaveAs     : GraphSave(Yes);
                   {$ENDIF}
                   {$IFDEF PRàBA}
                   cmSaveTxt    : SaveTxt(GraphCollection, Copy(GraphFileName, 1, Length(GraphFileName)-4));
                   cmLoadTxt    : LoadTxt(GraphCollection, Copy(GraphFileName, 1, Length(GraphFileName)-4));
                   {$ENDIF}
                 end{case};
    end{case};
  inherited HandleEvent(Event);
end{TApplication.HandleEvent};

{******************************************}
{* Tekst wy˜wietlany po chwilowym wyj˜ciu *}
{*               do DOS-u                 *}
{******************************************}

procedure TCADApplication.WriteShellMsg;
begin
  Write('Napisz EXIT w celu powrotu do programu...');
end{TApplication.WriteShellMsg};

{******************************************}
{* Od˜wie¾anie informacji o ilo˜ci wolnej *}
{*    pami©ci oraz o czasie systemowym    *}
{******************************************}

procedure TCADApplication.Idle;
begin
  inherited Idle;
  with Clock^ do
    Update;
  with Heap^ do
    Update;
end{TApplication.Idle};

{$IFNDEF COMERCIAL}

procedure TCADApplication.InitDesktop;
var
  Rect: TRect;
begin
  GetExtent(Rect);
  with Rect do
    Grow(0, -1);
  Desktop := New(PCADDesktop, Init(Rect));
end;

{$ENDIF}

{******************************************}
{*           Wykonanie programu           *}
{******************************************}

var
  CAD: PCADApplication;

begin
  New(CAD, Init);
  with CAD^ do
    Run;
  Dispose(CAD, Done);
end{TM_CAD}.