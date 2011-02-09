unit uTestsFromLibGit2;

interface

uses
   TestFramework, SysUtils, Windows,
   uGitForDelphi;

type
   TTestFromLibGit2 = class (TTestCase)
   strict private
      function GitReturnValue(aResult: Integer): String;
   public
      procedure must_pass(aResult: Integer);
      procedure must_fail(aResult: Integer; aExpectedResult: Integer = 0);
      procedure must_be_true(b: Boolean; const msg: String = '');
      function remove_loose_object(const aRepository_folder: PAnsiChar; object_: Pgit_object): Integer;
   end;

const
   REPOSITORY_FOLDER_         = 'resources/testrepo.git/';
   TEST_INDEX_PATH            = 'resources/testrepo.git/index';
   TEST_INDEX2_PATH           = 'resources/gitgit.index';
   TEST_INDEX_ENTRY_COUNT     = 109;
   TEST_INDEX2_ENTRY_COUNT    = 1437;

   tag1_id           = 'b25fa35b38051e4ae45d4222e795f9df2e43f1d1';
   tag2_id           = '7b4384978d2493e851f9cca7858815fac9b10980';
   tagged_commit     = 'e90810b8df3e80c413d903f631643c716887138d';
   tree_oid          = '1810dff58d8a660512d4832e740f692884338ccd';

type
   test_entry = record
      index:         Integer;
      path:          array [0..127] of AnsiChar;
      file_size:     size_t;
      mtime:         time_t;
   end;

const
   TEST_ENTRIES: array [0..4] of test_entry =
   (
      (index:  4; path: 'Makefile';          file_size: 5064;  mtime: $4C3F7F33),
      (index: 62; path: 'tests/Makefile';    file_size: 2631;  mtime: $4C3F7F33),
      (index: 36; path: 'src/index.c';       file_size: 10014; mtime: $4C43368D),
      (index:  6; path: 'git.git-authors';   file_size: 2709;  mtime: $4C3F7F33),
      (index: 48; path: 'src/revobject.h';   file_size: 1448;  mtime: $4C3F7FE2)
   );

function REPOSITORY_FOLDER: PAnsiChar;
function OctalToInt(const Value: string): Longint;

implementation

function REPOSITORY_FOLDER: PAnsiChar;
begin
   Result := PAnsiChar(AnsiString(ExtractFilePath(ParamStr(0)) + REPOSITORY_FOLDER_));
end;

function OctalToInt(const Value: string): Longint;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(Value) do
    Result := Result * 8 + StrToInt(Value[i]);
end;

{ TTestFromLibGit2 }

procedure TTestFromLibGit2.must_fail(aResult: Integer; aExpectedResult: Integer = 0);
begin
   if aExpectedResult <> 0 then
   begin
      if aExpectedResult <> aResult then
         CheckEquals(GitReturnValue(aExpectedResult), GitReturnValue(aResult));
   end
   else
   begin
      if aResult = GIT_SUCCESS then
         CheckEquals('not GIT_SUCCESS', GitReturnValue(aResult));
   end;
end;

procedure TTestFromLibGit2.must_pass(aResult: Integer);
begin
   if aResult <> GIT_SUCCESS then
      CheckEquals('GIT_SUCCESS', GitReturnValue(aResult));
end;

function TTestFromLibGit2.GitReturnValue(aResult: Integer): String;
begin
   case aResult of
      GIT_ERROR                  : Result := 'GIT_ERROR';
      GIT_ENOTOID                : Result := 'GIT_ENOTOID';
      GIT_ENOTFOUND              : Result := 'GIT_ENOTFOUND';
      GIT_ENOMEM                 : Result := 'GIT_ENOMEM';
      GIT_EOSERR                 : Result := 'GIT_EOSERR';
      GIT_EOBJTYPE               : Result := 'GIT_EOBJTYPE';
      GIT_EOBJCORRUPTED          : Result := 'GIT_EOBJCORRUPTED';
      GIT_ENOTAREPO              : Result := 'GIT_ENOTAREPO';
      GIT_EINVALIDTYPE           : Result := 'GIT_EINVALIDTYPE';
      GIT_EMISSINGOBJDATA        : Result := 'GIT_EMISSINGOBJDATA';
      GIT_EPACKCORRUPTED         : Result := 'GIT_EPACKCORRUPTED';
      GIT_EFLOCKFAIL             : Result := 'GIT_EFLOCKFAIL';
      GIT_EZLIB                  : Result := 'GIT_EZLIB';
      GIT_EBUSY                  : Result := 'GIT_EBUSY';
      GIT_EBAREINDEX             : Result := 'GIT_EBAREINDEX';
      GIT_EINVALIDREFNAME        : Result := 'GIT_EINVALIDREFNAME';
      GIT_EREFCORRUPTED          : Result := 'GIT_EREFCORRUPTED';
      GIT_ETOONESTEDSYMREF       : Result := 'GIT_ETOONESTEDSYMREF';
      GIT_EPACKEDREFSCORRUPTED   : Result := 'GIT_EPACKEDREFSCORRUPTED';
      GIT_EINVALIDPATH           : Result := 'GIT_EINVALIDPATH';
      GIT_EREVWALKOVER           : Result := 'GIT_EREVWALKOVER';
      else
         Result := 'Unknown';
   end;
end;

procedure TTestFromLibGit2.must_be_true(b: Boolean; const msg: String = '');
begin
   CheckTrue(b, msg);
end;

function TTestFromLibGit2.remove_loose_object(const aRepository_folder: PAnsiChar; object_: Pgit_object): Integer;
const
   objects_folder = 'objects/';
var
   ptr, full_path, top_folder: PAnsiChar;
   path_length, objects_length: Integer;
   dwAttrs: Cardinal;
begin
   CheckTrue(aRepository_folder <> nil);
   CheckTrue(object_ <> nil);

   objects_length := strlen(objects_folder);
   path_length := strlen(aRepository_folder);
   GetMem(full_path, path_length + objects_length + GIT_OID_HEXSZ + 3);
   ptr := full_path;

   StrCopy(ptr, aRepository_folder);
   StrCopy(ptr + path_length, objects_folder);

   top_folder := ptr + path_length + objects_length;
   ptr := top_folder;

   ptr^ := '/';
   Inc(ptr);
   git_oid_pathfmt(ptr, git_object_id(object_));
   Inc(ptr, GIT_OID_HEXSZ + 1);
   ptr^ := #0;

   dwAttrs := GetFileAttributesA(full_path);
   if SetFileAttributesA(full_path, dwAttrs and (not FILE_ATTRIBUTE_READONLY)) and (not DeleteFileA(full_path)) then
   begin
      raise Exception.CreateFmt('can''t delete object file "%s"', [full_path]);
      Result := -1;
      Exit;
   end;

   top_folder^ := #0;

   if (not RemoveDirectoryA(full_path)) and (GetLastError <> ERROR_DIR_NOT_EMPTY) then
   begin
      raise Exception.CreateFmt('can''t remove object directory "%s"', [full_path]);
      Result := -1;
      Exit;
   end;

   FreeMem(full_path, path_length + objects_length + GIT_OID_HEXSZ + 3);

   Result := GIT_SUCCESS;
end;

initialization
   InitLibgit2;

end.