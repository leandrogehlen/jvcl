{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: JvAlignListbox.PAS, released on 2000-11-22.

The Initial Developer of the Original Code is Peter Below <100113.1101@compuserve.com>
Portions created by Peter Below are Copyright (C) 2000 Peter Below.
All Rights Reserved.

Contributor(s): ______________________________________.

Last Modified: 2000-mm-dd

You may retrieve the latest version of this file at the Project JEDI home page,
located at http://www.delphi-jedi.org

Known Issues:
-----------------------------------------------------------------------------}
{$A+,B-,C+,D+,E-,F-,G+,H+,I+,J+,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$I JEDI.INC}


unit JvControlStringgrid;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,  Grids ,JVCLVer;

type
  TJvControlStringGrid = class(TStringGrid)
  private
    FAboutJVCL: TJVCLAboutInfo;
    { Private declarations }
    Procedure WMCommand( var msg: TWMCommand ); message WM_COMMAND;
  protected
    { Protected declarations }
  public
    { Public declarations }
  published
    property AboutJVCL: TJVCLAboutInfo read FAboutJVCL write FAboutJVCL  stored False;
  end;


implementation



{ TJvControlStringGrid }

procedure TJvControlStringGrid.WMCommand(var msg: TWMCommand);
begin
  If EditorMode and ( msg.Ctl = InplaceEditor.Handle ) Then
    inherited
  Else
    If msg.Ctl <> 0 Then
      msg.result :=
        SendMessage( msg.ctl, CN_COMMAND,
                     TMessage(msg).wparam,
                     TMessage(msg).lparam );
end;

end.
