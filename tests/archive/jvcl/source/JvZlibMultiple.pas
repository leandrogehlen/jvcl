{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: JvZlibMultiple.PAS, released on 2001-02-28.

The Initial Developer of the Original Code is Sébastien Buysse [sbuysse@buypin.com]
Portions created by Sébastien Buysse are Copyright (C) 2001 Sébastien Buysse.
All Rights Reserved.

Contributor(s): Michael Beck [mbeck@bigfoot.com].

Last Modified: 2000-02-28

You may retrieve the latest version of this file at the Project JEDI's JVCL home page,
located at http://jvcl.sourceforge.net

Known Issues:
-----------------------------------------------------------------------------}

{$I JVCL.INC}

{$IFDEF COMPILER6_UP}
{$WARN UNIT_PLATFORM OFF}
{$ENDIF}

unit JvZlibMultiple;
{$IFDEF LINUX}
This unit is only supported on Windows!
{$ENDIF}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Dialogs,
  ZLib, JvComponent;

type
  TFileEvent = procedure(Sender: TObject; const FileName: string) of object;
  TProgressEvent = procedure(Sender: TObject; Position, Total: Integer) of object;

  TJvZlibMultiple = class(TJvComponent)
  private
    FOnDecompressFile: TFileEvent;
    FOnDecompressedFile: TFileEvent;
    FOnProgress: TProgressEvent;
    FOnCompressFile: TFileEvent;
    FOnCompressedFile: TFileEvent;
  protected
    procedure AddFile(FileName, Directory, FilePath: string; DestStream: TStream);
  public
    // compresses a list of files (can contain wildcards)
    // NOTE: caller must free returned stream!
    function CompressFiles(Files: TStringList): TStream; overload;
    // compresses a list of files (can contain wildcards)
    // and saves the compressed result to Filename
    procedure CompressFiles(Files: TStringList; FileName: string); overload;
    // compresses a Directory (recursing if Recursive is true)
    // NOTE: caller must free returned stream!
    function CompressDirectory(Directory: string; Recursive: Boolean): TStream; overload;
    // compresses a Directory (recursing if Recursive is true)
    // and saves the compressed result to Filename
    procedure CompressDirectory(Directory: string; Recursive: Boolean; FileName: string); overload;
    // decompresses Filename into Directory. If Overwrite is true, overwrites any existing files with
    // the same name as those in the compressed archive
    procedure DecompressFile(FileName, Directory: string; Overwrite: Boolean);
    // decompresses Stream into Directory optionally overwriting any existing files
    procedure DecompressStream(Stream: TStream; Directory: string;
      Overwrite: Boolean);
  published
    property OnDecompressingFile: TFileEvent read FOnDecompressFile write FOnDecompressFile;
    property OnDecompressedFile: TFileEvent read FOnDecompressedFile write FOnDecompressedFile;
    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
    property OnCompressingFile: TFileEvent read FOnCompressFile write FOnCompressFile;
    property OnCompressedFile: TFileEvent read FOnCompressedFile write FOnCompressedFile;
  end;

implementation
{$IFNDEF COMPILER6_UP}
uses
  FileCtrl;
{$ENDIF}

{*******************************************************}
{  Format of the File:                                  }
{   File Header                                         }
{    1 Byte    Size of the directory variable           }
{    x bytes   Directory of the file                    }
{    1 Byte    Size of the filename                     }
{    x bytes   Filename                                 }
{    4 bytes   Size of the file (uncompressed)          }
{    4 bytes   Size of the file (compressed)            }
{   Data chunk                                          }
{    x bytes   the compressed chunk                     }
{*******************************************************}

{***********************************************}

function TJvZlibMultiple.CompressDirectory(Directory: string;
  Recursive: Boolean): TStream;

  procedure SearchDirectory(SDirectory: string);
  var
    SearchRec: TSearchRec;
    Res: Integer;
  begin
    Res := FindFirst(Directory + SDirectory + '*.*', faAnyFile, SearchRec);
    try
      while (Res = 0) do
      begin
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          if (SearchRec.Attr and faDirectory = 0) then
            AddFile(SearchRec.Name, SDirectory, Directory + SDirectory + SearchRec.Name, Result)
          else if Recursive then
            SearchDirectory(SDirectory + SearchRec.Name + '\');
        end;
        Res := FindNext(SearchRec);
      end;
    finally
      FindClose(SearchRec);
    end;
  end;

begin
  Result := TMemoryStream.Create;
  if (Length(Directory) > 0) and (Directory[Length(Directory)] <> '\') then
    Directory := Directory + '\';
  SearchDirectory('');
  Result.Position := 0;
end;

{***********************************************}

procedure TJvZlibMultiple.AddFile(FileName, Directory, FilePath: string;
  DestStream: TStream);
var
  Stream: TStream;
  FStream: TFileStream;
  ZStream: TCompressionStream;
  buf: array[0..1023] of Byte;
  count: Integer;

  procedure WriteFileRecord(Directory, FileName: string; FileSize: Integer;
    CompressedSize: Integer);
  var
    b: Byte;
    tab: array[1..256] of Char;
  begin
    for b := 1 to Length(Directory) do
      tab[b] := Directory[b];
    b := Length(Directory);
    DestStream.Write(b, SizeOf(b));
    DestStream.Write(tab, b);

    for b := 1 to Length(FileName) do
      tab[b] := FileName[b];
    b := Length(FileName);
    DestStream.Write(b, SizeOf(b));
    DestStream.Write(tab, b);

    DestStream.Write(FileSize, SizeOf(FileSize));
    DestStream.Write(CompressedSize, SizeOf(CompressedSize));
  end;

begin
  Stream := TMemoryStream.Create;
  FStream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
  try
    ZStream := TCompressionStream.Create(clDefault, Stream);
    try

      if Assigned(FOnCompressFile) then
        FOnCompressFile(Self, FilePath);

      repeat
        count := FStream.Read(buf, sizeof(buf));
        ZStream.Write(buf, count);
        if Assigned(FOnProgress) then
          FOnProgress(Self, FStream.Position, FStream.Size);
      until Count = 0;
    finally
      ZStream.Free;
    end;

    if Assigned(FOnCompressedFile) then
      FOnCompressedFile(Self, FilePath);

    WriteFileRecord(Directory, FileName, FStream.Size, Stream.Size);
    DestStream.CopyFrom(Stream, 0);
  finally
    FStream.Free;
    Stream.Free;
  end;
end;

{***********************************************}

procedure TJvZlibMultiple.CompressDirectory(Directory: string;
  Recursive: Boolean; FileName: string);
var
  MemStream:TMemoryStream;
begin
  // don't create file until we save it so we don't accidentally
  // try to compress ourselves!
  if FileExists(Filename) then
    DeleteFile(Filename); // make sure we don't compress a previous archive into ourselves
  MemStream := TMemoryStream.Create;
  try
    MemStream.CopyFrom(CompressDirectory(Directory, Recursive), 0);
    MemStream.SaveToFile(Filename);
  finally
    MemStream.Free;
  end;
end;

{***********************************************}

function TJvZlibMultiple.CompressFiles(Files: TStringList): TStream;
var
  i: Integer;
  st, st2, common: string;
begin
  Result := TMemoryStream.Create;
  if Files.Count = 0 then
    Exit;

  //Find the biggest common part of all files
  st := UpperCase(Files[0]);
  for i := 1 to Files.Count - 1 do
  begin
    st2 := Files[i];
    while (Pos(st, st2) = 0) and (st <> '') do
      st := Copy(st, 1, Length(st) - 1);
  end;
  common := st2;

  //Add the files to the stream
  for i := 0 to Files.Count - 1 do
  begin
    st := ExtractFileName(Files[i]);
    st2 := ExtractFilePath(Files[i]);
    st2 := Copy(st2, 1, Length(common));
    AddFile(st, st2, Files[i], Result);
  end;

  Result.Position := 0;
end;

{***********************************************}

procedure TJvZlibMultiple.CompressFiles(Files: TStringList;
  FileName: string);
var
  MemStream: TMemoryStream;
begin
  MemStream := TMemoryStream.Create;
  try
    MemStream.CopyFrom(CompressFiles(Files), 0);
    MemStream.SaveToFile(Filename);
  finally
    MemStream.Free;
  end;
end;

{***********************************************}

procedure TJvZlibMultiple.DecompressStream(Stream: TStream;
  Directory: string; Overwrite: Boolean);
var
  FStream: TFileStream;
  ZStream: TDecompressionStream;
  CStream: TMemoryStream;
  b: Byte;
  tab: array [1..256] of Char;
  st: string;
  count, fsize, i: Integer;
  buf: array [0..1023] of Byte;
begin
  if (Length(Directory) > 0) and (Directory[Length(Directory)] <> '\') then
    Directory := Directory + '\';

  while Stream.Position < Stream.Size do
  begin
    //Read and force the directory
    Stream.Read(b, SizeOf(b));
    Stream.Read(tab, b);
    st := '';
    for i := 1 to b do
      st := st + tab[i];
    ForceDirectories(Directory + st);
    if (Length(st) > 0) and (st[Length(st)] <> '\') then
      st := st + '\';

    //Read filename
    Stream.Read(b, SizeOf(b));
    Stream.Read(tab, b);
    for i := 1 to b do
      st := st + tab[i];

    Stream.Read(fsize, SizeOf(fsize));
    Stream.Read(i, SizeOf(i));
    CStream := TMemoryStream.Create;
    try
      CStream.CopyFrom(Stream, i);
      CStream.Position := 0;

      //Decompress the file
      st := Directory + st;
      if Overwrite or not FileExists(st) then
      begin
        FStream := TFileStream.Create(st, fmCreate or fmShareExclusive);
        ZStream := TDecompressionStream.Create(CStream);
        try

          if Assigned(FOnDecompressFile) then
            FOnDecompressFile(Self, st);

          repeat
            count := ZStream.Read(buf, sizeof(buf));
            FStream.Write(buf, count);
            if Assigned(FOnProgress) then
              FOnProgress(Self, FStream.Size, fsize);
          until count = 0;

          if Assigned(FOnDecompressedFile) then
            FOnDecompressedFile(Self, st);
        finally
          FStream.Free;
          ZStream.Free;
        end;
      end;
    finally
      CStream.Free;
    end;
  end;
end;

{***********************************************}

procedure TJvZlibMultiple.DecompressFile(FileName, Directory: string;
  Overwrite: Boolean);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Stream.Position := 0;
    DecompressStream(Stream, Directory, Overwrite);
  finally
    Stream.Free;
  end;
end;

end.

