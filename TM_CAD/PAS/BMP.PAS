{ Moduˆ pomocniczy uˆatwiaj¥cy robienie    }
{ "zrzut¢w" ekranu graficznego 1024x768x16 }

unit BMP;

interface

uses
  Dos;

{ Zapis zawarto˜ci ekranu graficznego 1024x768x16 w postaci }
{ pliku w formacie BitMaP                                   }

procedure SaveScreen(FileName: PathStr);

implementation

uses
  Graph;

type
  PBMP_File_Hdr = ^TBMP_File_Hdr;
  TBMP_File_Hdr =
    record
      bfType: Word;
      bfSize: LongInt;
      bfReserved1, bfReserved2: Word;
      bfOffBits: LongInt;
    end{TBMP_File_Hdr};
  PBMP_Info_Hdr = ^TBMP_Info_Hdr;
  TBMP_Info_Hdr =
    record
      biSize, biWidth, biHeight: LongInt;
      biPlanes, biBitCount: Word;
      biCompression, biSizeImage, biXPelsPerMeter, biYPelsPerMeter,
      biClrUsed, biClrImportant: LongInt;
    end{TBMP_Info_Hdr};
  PRGB_Quad = ^TRGB_Quad;
  TRGB_Quad =
    record
      Blue, Green, Red, Null: Byte;
    end{TRGB_Quad};
  PScr_RGB = ^TScr_RGB;
  TScr_RGB =
    record
      _Red, _Green, _Blue: Byte;
    end{TScr_RGB};
  PPalette = ^TPalette;
  TPalette = array[Byte] of TRGB_Quad;
  PRGBPalette = ^TRGBPalette;
  TRGBPalette = array[Byte] of TScr_RGB;

const
  BMP_Identifier: array[Boolean] of Char = 'BM';

var
  BMP_Block:
    record
      File_Hdr: PBMP_File_Hdr;
      Info_Hdr: PBMP_Info_Hdr;
      BMP_Palette: PPalette;
    end{BMP_Block};

procedure GetPalette(var Palette: TRGBPalette);
var
  R: Registers;
begin
  with R do
    begin
      AX := $1017;
      BX := 0;
      CX := 256;
      ES := Seg(Palette);
      DX := Ofs(Palette);
    end{begin};
  Intr($10, R);
end{GetPalette};

procedure InitBMP;
var
  Palette: TRGBPalette;
  I: Byte;
begin
  with BMP_Block do
    begin
      New(File_Hdr);
      with File_Hdr^ do
        begin
          bfType := Word(BMP_Identifier);
          bfSize := SizeOf(TBMP_File_Hdr)+SizeOf(TBMP_Info_Hdr)+
                    SizeOf(TPalette) div 16+
                    (Succ(GetMaxX)*Succ(GetMaxY)) div 2;
          bfReserved1 := 0;
          bfReserved2 := 0;
          bfOffBits := SizeOf(TBMP_File_Hdr)+SizeOf(TBMP_Info_Hdr)+
                    SizeOf(TPalette) div 16;
        end{begin};
      New(Info_Hdr);
      with Info_Hdr^ do
        begin
          biSize := SizeOf(TBMP_Info_Hdr);
          biWidth := Succ(GetMaxX);
          biHeight := Succ(GetMaxY);
          biBitCount := 4;
          biCompression := 0;
          biPlanes := 1;
          biSizeImage := Succ(GetMaxX)*Succ(GetMaxY) div 2;
          biXPelsPerMeter := 0;
          biYPelsPerMeter := 0;
          biClrUsed := 0;
          biClrImportant := 0;
        end{begin};
      New(BMP_Palette);
      GetPalette(Palette);
      for I := 0 to 15 do
        with BMP_Palette^[I], Palette[I] do
          begin
            Red   := _Red   shl 2;
            Green := _Green shl 2;
            Blue  := _Blue  shl 2;
            Null  := 0;
          end{begin};
    end{begin};
end{InitBMP};

procedure DoneBMP;
begin
  with BMP_Block do
    begin
      Dispose(File_Hdr);
      Dispose(Info_Hdr);
      Dispose(BMP_Palette);
    end{begin};
end{DoneBMP};

procedure SaveScreen;
var
  BMP_File: file;
  I, J: Integer;
  Buffer: array[0..1023] of Byte;
begin
  InitBMP;
  Assign(BMP_File, FileName);
  Rewrite(BMP_File, 1);
  with BMP_Block do
    begin
      BlockWrite(BMP_File, File_Hdr^, SizeOf(TBMP_File_Hdr));
      BlockWrite(BMP_File, Info_Hdr^, SizeOf(TBMP_Info_Hdr));
      BlockWrite(BMP_File, BMP_Palette^, 16*4);
      SetColor(15);
        for I := GetMaxY downto 0 do
          begin
            for J := 0 to GetMaxX div 2 do
              Buffer[J] :=
                GetPixel(J*2+1, I) or (GetPixel(J*2, I) shl 4);
            BlockWrite(BMP_File, Buffer, Succ(GetMaxX) div 2);
            SetWriteMode(XORPut);
            Line(0, I, GetMaxX, I);
            SetWriteMode(NormalPut);
          end{begin};
    end{begin};
  Close(BMP_File);
  DoneBMP;
  SetWriteMode(XORPut);
  for I := 0 to GetMaxX do
    Line(0, I, GetMaxX, I);
  SetWriteMode(NormalPut);
end{SaveScreen};

end{BMP}.