program SensorDemo;

uses
  Forms,
  SensorTypes in 'SensorTypes.pas',
  SensorFactory in 'SensorFactory.pas',
  DeviceManager in 'DeviceManager.pas',
  uMainForm in 'uMainForm.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
