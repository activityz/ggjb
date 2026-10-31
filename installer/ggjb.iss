; 搞个机吧 —— Windows 安装包脚本（Inno Setup 6）
;
; 编译：
;   "C:\Users\25852\AppData\Local\Programs\Inno Setup 6\ISCC.exe" installer\ggjb.iss
; 产物：
;   dist\ggjb-<版本>-windows-setup.exe
;
; 两个刻意的选择：
; 1) 装到 {localappdata}\Programs\ggjb 而不是 Program Files —— 程序要把
;    数据库和导出文件写在 exe 同级的 data\ 里，Program Files 不可写。
; 2) 卸载不删 data\ —— 那是用户几年的账，删程序不该顺手删账本。

#define AppName "搞个机吧"
#define AppVersion "1.5.1"
#define AppExe "ggjb.exe"
#define AppSource "..\dist\ggjb-windows-x64"

[Setup]
AppId={{6E2F4A87-2C1D-4B55-9A3E-0F1B7D8C5A21}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=local
AppPublisherURL=https://localhost/
DefaultDirName={localappdata}\Programs\ggjb
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; 装到用户目录，不需要管理员权限，也不会弹 UAC
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=ggjb-{#AppVersion}-windows-setup
SetupIconFile=..\app\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; 关掉「许可协议」页 —— 自用工具没有协议可签
LicenseFile=

[Languages]
Name: "chs"; MessagesFile: "compiler:Default.isl"

[Messages]
SetupAppTitle=安装
SetupWindowTitle=安装 - %1
UninstallAppTitle=卸载
UninstallAppFullTitle=卸载 %1

WelcomeLabel1=欢迎安装 [name]
WelcomeLabel2=这会把 [name/ver] 装到你的电脑上。%n%n装好后桌面和开始菜单都会有快捷方式，账本数据存在程序目录的 data 文件夹里，随时可以整个拷走。

WizardSelectDir=选择安装位置
SelectDirDesc=装到哪里？
SelectDirLabel3=安装程序会把 [name] 装到下面这个文件夹。
SelectDirBrowseLabel=点「下一步」继续；想换地方就点「浏览」。
DiskSpaceMBLabel=至少需要 [mb] MB 磁盘空间。

WizardReady=准备就绪
ReadyLabel1=现在开始装 [name]。
ReadyLabel2a=点「安装」开始，或者点「上一步」回去改。
ReadyLabel2b=点「安装」开始。

WizardInstalling=正在安装
InstallingLabel=正在把文件复制到你的电脑，请稍等。

FinishedHeadingLabel=装好了
FinishedLabel=点「完成」关掉安装程序，然后双击桌面上的「{#AppName}」就能用。
ClickFinish=点「完成」退出安装程序。

ButtonNext=下一步(&N)
ButtonBack=上一步(&B)
ButtonInstall=安装(&I)
ButtonFinish=完成(&F)
ButtonCancel=取消
ButtonBrowse=浏览(&R)...
ButtonYes=是(&Y)
ButtonNo=否(&N)
ButtonOK=确定
ButtonClose=关闭

ExitSetupTitle=确定退出安装？
ExitSetupMessage=安装还没完成。现在退出的话，已经复制的文件会保留下来。%n%n确定要退出吗？
ExitSetupExitButton=退出(&X)
ExitSetupStayButton=继续安装(&R)

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务:"

[Files]
Source: "{#AppSource}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "立即打开 {#AppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; 只清 data 以外的残留；data 目录（数据库 + 导出文件）原样保留
Type: dirifempty; Name: "{app}\data"

[Code]
// 升级安装时，如果 data\ 里已有数据库，提示一下「数据会保留」，
// 免得用户以为重装会把账清掉。
//
// 必须放在 ssPostInstall 而不是 InitializeWizard：
// InitializeWizard 跑的时候用户还没选安装目录，{app} 常量尚未初始化，
// 在那里 ExpandConstant('{app}') 会直接抛
// "An attempt was made to expand the app constant before it was initialized"。
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if FileExists(ExpandConstant('{app}\data\ggjb.sqlite')) then
    begin
      MsgBox('检测到已有数据（data\ggjb.sqlite），本次安装会保留它，不会被覆盖。',
        mbInformation, MB_OK);
    end;
  end;
end;