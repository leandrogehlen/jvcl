{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: JvMessageBeep.PAS, released on 2001-02-28.

The Initial Developer of the Original Code is Sébastien Buysse [sbuysse@buypin.com]
Portions created by Sébastien Buysse are Copyright (C) 2001 Sébastien Buysse.
All Rights Reserved.

Contributor(s): Michael Beck [mbeck@bigfoot.com].

Last Modified: 2000-02-28

You may retrieve the latest version of this file at the Project JEDI home page,
located at http://www.delphi-jedi.org

Known Issues:
-----------------------------------------------------------------------------}
{$A+,B-,C+,D+,E-,F-,G+,H+,I+,J+,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$I JEDI.INC}

unit JvMessageBeep;

{$ObjExportAll On}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  JvBaseDlg, JvTypes;

type
  TJvMessageBeep = class(TJvCommonDialog)
  private
    FStyle: TMsgStyle;
  published
    property Style: TMsgStyle read FStyle write FStyle default msOk;
    function Execute: Boolean; override;
  end;

implementation

{**************************************************}

function TJvMessageBeep.Execute: Boolean;
var
  flag: Integer;
begin
{$WARNINGS OFF}
  case FStyle of
    msBeep:
      flag := $FFFFFFFF;
    msIconAsterisk:
      flag := MB_ICONASTERISK;
    msIconExclamation:
      flag := MB_ICONEXCLAMATION;
    msIconHand:
      flag := MB_ICONHAND;
    msIconQuestion:
      flag := MB_ICONQUESTION;
    msOk:
      flag := MB_OK;
  else
    flag := $FFFFFFFF;
  end;
  Result := MessageBeep(flag);
{$WARNINGS ON}
end;

end.
