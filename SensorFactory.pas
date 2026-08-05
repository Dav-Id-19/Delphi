unit SensorFactory;

{**
  @file SensorFactory.pas
  @brief Фабрика сенсоров для создания UI компонентов

  Создает визуальные компоненты (Grid, TrackBar, ProgressBar, Edit и др.)
  на основе данных о сенсорах из таблицы конфигурации.
*}

interface

uses
  Classes, SysUtils, Controls, Forms, StdCtrls, ComCtrls, ExtCtrls, Grids,
  SensorTypes, Contnrs, Variants, Graphics;

type
  { Конфигурация сенсора из таблицы }
  TSensorConfig = record
    ID: Integer;
    Name: string;
    Description: string;
    SensorType: TSensorType;
    MinValue: Variant;
    MaxValue: Variant;
    UnitName: string;
    Row: Integer;        // Позиция на форме
    Col: Integer;
    Width: Integer;
    Height: Integer;
  end;

  { Обертка для компонента сенсора }
  TSensorComponent = class(TObject)
  private
    FSensor: TSensor;
    FControl: TControl;  // Изменено с TWinControl на TControl для поддержки TLabel
    FLabelCaption: TLabel;
    FPanel: TPanel;
  public
    constructor Create(ASensor: TSensor; AControl: TControl;
      ALabelCaption: TLabel; APanel: TPanel);
    destructor Destroy; override;

    { Обновить отображение }
    procedure UpdateDisplay; virtual;

    { Освободить компоненты }
    procedure FreeControls;

    property Sensor: TSensor read FSensor;
    property Control: TControl read FControl;
    property LabelCaption: TLabel read FLabelCaption;
    property Panel: TPanel read FPanel;
  end;

  { Фабрика сенсоров }
  TSensorFactory = class(TObject)
  private
    FOwner: TWinControl;  // Владелец компонентов (форма или панель)
    FSensorList: TSensorList;
    FComponentList: TObjectList;
    FOnSensorChange: TNotifyEvent;
    procedure HandleSensorChange(Sender: TObject);
  public
    constructor Create(AOwner: TWinControl);
    destructor Destroy; override;

    { Создать сенсор из конфигурации }
    function CreateSensor(const Config: TSensorConfig): TSensorComponent;

    { Создать все сенсоры из списка конфигураций }
    procedure CreateSensorsFromConfig(const Configs: array of TSensorConfig);

    { Найти компонент сенсора по ID }
    function FindSensorComponent(ID: Integer): TSensorComponent;

    { Обновить значение сенсора }
    procedure UpdateSensorValue(ID: Integer; const Value: Variant);

    { Удалить все сенсоры }
    procedure ClearAll;

    { Список сенсоров }
    property Sensors: TSensorList read FSensorList;

    { Событие изменения сенсора }
    property OnSensorChange: TNotifyEvent read FOnSensorChange write FOnSensorChange;
  end;

implementation

{ TSensorComponent }

constructor TSensorComponent.Create(ASensor: TSensor; AControl: TControl;
  ALabelCaption: TLabel; APanel: TPanel);
begin
  inherited Create;
  FSensor := ASensor;
  FControl := AControl;
  FLabelCaption := ALabelCaption;
  FPanel := APanel;
end;

destructor TSensorComponent.Destroy;
begin
  FreeControls;
  inherited Destroy;
end;

procedure TSensorComponent.UpdateDisplay;
var
  StrValue: string;
begin
  if not Assigned(FControl) then Exit;

  StrValue := FSensor.GetValueAsString;

  { Обновляем в зависимости от типа контрола }
  if FControl is TEdit then
    TEdit(FControl).Text := StrValue
  else if FControl is TLabel then
    TLabel(FControl).Caption := StrValue
  else if FControl is TTrackBar then
  begin
    if not VarIsNull(FSensor.Data.Value) then
      TTrackBar(FControl).Position := Trunc(FSensor.Data.Value);
  end
  else if FControl is TProgressBar then
  begin
    if not VarIsNull(FSensor.Data.Value) then
      TProgressBar(FControl).Position := Trunc(FSensor.Data.Value);
  end
  else if FControl is TCheckBox then
  begin
    if not VarIsNull(FSensor.Data.Value) then
      TCheckBox(FControl).Checked := Boolean(FSensor.Data.Value);
  end
  else if FControl is TStringGrid then
  begin
    { Для Grid обновление происходит через событие OnDrawCell }
    TStringGrid(FControl).Refresh;
  end;

  { Обновляем label если есть }
  if Assigned(FLabelCaption) then
    FLabelCaption.Caption := FSensor.Name + ': ' + StrValue;
end;

procedure TSensorComponent.FreeControls;
begin
  if Assigned(FPanel) then
    FPanel.Free;
  { Контролы освобождаются вместе с панелью }
end;

{ TSensorFactory }

constructor TSensorFactory.Create(AOwner: TWinControl);
begin
  inherited Create;
  FOwner := AOwner;
  FSensorList := TSensorList.Create;
  FComponentList := TObjectList.Create(True); // Ownership включено
  FOnSensorChange := nil;
end;

destructor TSensorFactory.Destroy;
begin
  ClearAll;
  FComponentList.Free;
  FSensorList.Free;
  inherited Destroy;
end;

procedure TSensorFactory.HandleSensorChange(Sender: TObject);
var
  Comp: TSensorComponent;
begin
  if Sender is TSensor then
  begin
    Comp := FindSensorComponent(TSensor(Sender).ID);
    if Assigned(Comp) then
      Comp.UpdateDisplay;
  end;

  if Assigned(FOnSensorChange) then
    FOnSensorChange(Sender);
end;

function TSensorFactory.CreateSensor(const Config: TSensorConfig): TSensorComponent;
var
  Sensor: TSensor;
  Panel: TPanel;
  LabelCtrl: TLabel;
  Ctrl: TControl;
  SensorData: TSensorData;
  MinVal, MaxVal: Variant;
  UnitStr: string;
begin
  { Создаем сенсор }
  Sensor := TSensor.Create(Config.ID, Config.Name);
  Sensor.Description := Config.Description;
  Sensor.SensorType := Config.SensorType;

  { Копируем значения во временные переменные для избежания ошибок компиляции }
  MinVal := Config.MinValue;
  MaxVal := Config.MaxValue;
  UnitStr := Config.UnitName;

  { Получаем ссылку на объект данных и устанавливаем значения }
  SensorData := Sensor.Data;
  SensorData.MinValue := MinVal;
  SensorData.MaxValue := MaxVal;
  SensorData.UnitName := UnitStr;

  Sensor.OnChange := HandleSensorChange;
  FSensorList.Add(Sensor);

  { Создаем панель для размещения }
  Panel := TPanel.Create(FOwner);
  Panel.Parent := FOwner;
  Panel.Left := Config.Col * Config.Width;
  Panel.Top := Config.Row * Config.Height;
  Panel.Width := Config.Width;
  Panel.Height := Config.Height;
  Panel.BevelOuter := bvLowered;
  Panel.Color := clWhite;

  { Создаем label }
  LabelCtrl := TLabel.Create(FOwner);
  LabelCtrl.Parent := Panel;
  LabelCtrl.Left := 5;
  LabelCtrl.Top := 5;
  LabelCtrl.Width := Config.Width - 10;
  LabelCtrl.Height := 15;
  LabelCtrl.Caption := Config.Name;
  LabelCtrl.Font.Style := [fsBold];

  { Создаем контрол в зависимости от типа сенсора }
  case Config.SensorType of
    stAnalog:
      begin
        { TrackBar + Label для значения }
        Ctrl := TTrackBar.Create(FOwner);
        TTrackBar(Ctrl).Parent := Panel;
        TTrackBar(Ctrl).Left := 5;
        TTrackBar(Ctrl).Top := 25;
        TTrackBar(Ctrl).Width := Config.Width - 10;
        TTrackBar(Ctrl).Height := 30;
        if not VarIsNull(MinVal) then
          TTrackBar(Ctrl).Min := Trunc(MinVal);
        if not VarIsNull(MaxVal) then
          TTrackBar(Ctrl).Max := Trunc(MaxVal);
        TTrackBar(Ctrl).Enabled := False; { Только чтение }
      end;

    stDigital:
      begin
        { CheckBox }
        Ctrl := TCheckBox.Create(FOwner);
        TCheckBox(Ctrl).Parent := Panel;
        TCheckBox(Ctrl).Left := 5;
        TCheckBox(Ctrl).Top := 25;
        TCheckBox(Ctrl).Width := Config.Width - 10;
        TCheckBox(Ctrl).Height := 20;
        TCheckBox(Ctrl).Enabled := False;
      end;

    stNumeric:
      begin
        { Edit для числового значения }
        Ctrl := TEdit.Create(FOwner);
        TEdit(Ctrl).Parent := Panel;
        TEdit(Ctrl).Left := 5;
        TEdit(Ctrl).Top := 25;
        TEdit(Ctrl).Width := Config.Width - 10;
        TEdit(Ctrl).Height := 21;
        TEdit(Ctrl).ReadOnly := True;
        TEdit(Ctrl).Alignment := taRightJustify;
      end;

    stText:
      begin
        { Edit для текста }
        Ctrl := TEdit.Create(FOwner);
        TEdit(Ctrl).Parent := Panel;
        TEdit(Ctrl).Left := 5;
        TEdit(Ctrl).Top := 25;
        TEdit(Ctrl).Width := Config.Width - 10;
        TEdit(Ctrl).Height := 21;
        TEdit(Ctrl).ReadOnly := True;
      end;

  else
    { Custom - просто Label }
    Ctrl := TLabel.Create(FOwner);
    TLabel(Ctrl).Parent := Panel;
    TLabel(Ctrl).Left := 5;
    TLabel(Ctrl).Top := 25;
    TLabel(Ctrl).Width := Config.Width - 10;
    TLabel(Ctrl).Height := 15;
  end;

  { Создаем обертку }
  Result := TSensorComponent.Create(Sensor, Ctrl, LabelCtrl, Panel);
  FComponentList.Add(Result);

  { Первоначальное отображение }
  Result.UpdateDisplay;
end;

procedure TSensorFactory.CreateSensorsFromConfig(const Configs: array of TSensorConfig);
var
  i: Integer;
begin
  for i := Low(Configs) to High(Configs) do
    CreateSensor(Configs[i]);
end;

function TSensorFactory.FindSensorComponent(ID: Integer): TSensorComponent;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to FComponentList.Count - 1 do
  begin
    if TSensorComponent(FComponentList[i]).Sensor.ID = ID then
    begin
      Result := TSensorComponent(FComponentList[i]);
      Exit;
    end;
  end;
end;

procedure TSensorFactory.UpdateSensorValue(ID: Integer; const Value: Variant);
var
  Sensor: TSensor;
begin
  Sensor := FSensorList.FindByID(ID);
  if Assigned(Sensor) then
    Sensor.UpdateData(Value);
end;

procedure TSensorFactory.ClearAll;
var
  i: Integer;
begin
  for i := FComponentList.Count - 1 downto 0 do
  begin
    TSensorComponent(FComponentList[i]).FreeControls;
    FComponentList.Delete(i);
  end;
  FSensorList.Clear;
end;

end.
