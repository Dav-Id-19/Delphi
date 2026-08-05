unit DeviceManager;

{**
  @file DeviceManager.pas
  @brief Менеджер устройств и их сенсоров

  Управляет подключенными устройствами, создает дочерние формы
  с сенсорами на основе данных из таблиц конфигурации.
*}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, Contnrs,
  SensorTypes, SensorFactory, SyncObjs;

type
  { Информация об устройстве }
  TDeviceInfo = record
    ID: Integer;
    Name: string;
    Description: string;
    Connected: Boolean;
    DeviceType: string;
    // Дополнительные поля могут быть добавлены по мере необходимости
  end;

  { Объект устройства }
  TDevice = class(TObject)
  private
    FInfo: TDeviceInfo;
    FSensorFactory: TSensorFactory;
    FChildForm: TForm;
    FOwner: TWinControl;
    FOnDataReceived: TNotifyEvent;
    procedure HandleSensorChange(Sender: TObject);
  public
    constructor Create(const Info: TDeviceInfo; AOwner: TWinControl);
    destructor Destroy; override;

    { Подключить устройство }
    function Connect: Boolean; virtual;

    { Отключить устройство }
    procedure Disconnect; virtual;

    { Создать дочернюю форму с сенсорами }
    procedure CreateSensorForm(Parent: TForm);

    { Получить данные от устройства (вызывается при получении данных) }
    procedure ReceiveData(SensorID: Integer; const Value: Variant);

    { Закрыть форму сенсоров }
    procedure CloseSensorForm;

    { Информация об устройстве }
    property Info: TDeviceInfo read FInfo write FInfo;

    { Фабрика сенсоров }
    property SensorFactory: TSensorFactory read FSensorFactory;

    { Дочерняя форма }
    property ChildForm: TForm read FChildForm;

    { Событие получения данных }
    property OnDataReceived: TNotifyEvent read FOnDataReceived write FOnDataReceived;
  end;

  { Список устройств }
  TDeviceList = class(TObjectList)
  private
    function GetDevice(Index: Integer): TDevice;
  public
    function Add(Device: TDevice): Integer;
    function FindByID(ID: Integer): TDevice;
    function FindByName(const AName: string): TDevice;
    property Devices[Index: Integer]: TDevice read GetDevice; default;
  end;

  { Менеджер устройств }
  TDeviceManager = class(TObject)
  private
    FDeviceList: TDeviceList;
    FMainForm: TForm;
    FOnDeviceConnect: TNotifyEvent;
    FOnDeviceDisconnect: TNotifyEvent;
    class var FInstance: TDeviceManager;
    constructor Create;
  public
    destructor Destroy; override;

    { Получить единственный экземпляр (Singleton) }
    class function Instance: TDeviceManager;

    { Инициализировать менеджер }
    procedure Initialize(MainForm: TForm);

    { Добавить устройство из таблицы }
    function AddDevice(const Info: TDeviceInfo): TDevice;

    { Удалить устройство }
    procedure RemoveDevice(DeviceID: Integer);

    { Найти устройство }
    function FindDevice(ID: Integer): TDevice;

    { Подключить устройство }
    function ConnectDevice(DeviceID: Integer): Boolean;

    { Отключить устройство }
    procedure DisconnectDevice(DeviceID: Integer);

    { Отключить все устройства }
    procedure DisconnectAll;

    { Получить данные для сенсора (вызывается при получении данных от устройства) }
    procedure ReceiveSensorData(DeviceID: Integer; SensorID: Integer; const Value: Variant);

    { Список устройств }
    property Devices: TDeviceList read FDeviceList;

    { Событие подключения устройства }
    property OnDeviceConnect: TNotifyEvent read FOnDeviceConnect write FOnDeviceConnect;

    { Событие отключения устройства }
    property OnDeviceDisconnect: TNotifyEvent read FOnDeviceDisconnect write FOnDeviceDisconnect;
  end;

implementation

var
  FDeviceManagerLock: TCriticalSection = nil;
  FDeviceManagerInstance: TDeviceManager = nil;

{ TDevice }

constructor TDevice.Create(const Info: TDeviceInfo; AOwner: TWinControl);
begin
  inherited Create;
  FInfo := Info;
  FChildForm := nil;
  FSensorFactory := TSensorFactory.Create(AOwner);
  FSensorFactory.OnSensorChange := HandleSensorChange;
  FOnDataReceived := nil;
  FOwner := AOwner;
end;

destructor TDevice.Destroy;
begin
  CloseSensorForm;
  FSensorFactory.Free;
  inherited Destroy;
end;

procedure TDevice.HandleSensorChange(Sender: TObject);
begin
  { Обработка изменения сенсора }
  if Assigned(FOnDataReceived) then
    FOnDataReceived(Sender);
end;

function TDevice.Connect: Boolean;
begin
  Result := True;
  FInfo.Connected := True;

  { Создаем форму с сенсорами сразу после подключения }
  if Assigned(FOwner) and (not Assigned(FChildForm)) then
    CreateSensorForm(TForm(FOwner));

  { Здесь будет код для установления соединения с устройством }
  { Например, через USB, COM-порт или сеть }
end;

procedure TDevice.Disconnect;
begin
  FInfo.Connected := False;

  { Закрываем форму сенсоров }
  CloseSensorForm;

  { Здесь будет код для разрыва соединения с устройством }
end;

procedure TDevice.CreateSensorForm(Parent: TForm);
var
  SensorConfig: TSensorConfig;
  Sensor: TSensor;
begin
  if Assigned(FChildForm) then Exit;

  { Создаем дочернюю форму }
  FChildForm := TForm.Create(Parent);
  FChildForm.Parent := Parent;
  FChildForm.BorderStyle := bsNone;
  FChildForm.Align := alClient;
  FChildForm.Caption := 'Сенсоры: ' + FInfo.Name;
  FChildForm.Show;

  { Загружаем конфигурацию сенсоров из таблицы в зависимости от устройства }
  { Здесь должна быть загрузка из реальной таблицы конфигурации }

  { Пример конфигурации для Device-001 (ID=1): 1 сенсор с 3 значениями }
  if FInfo.ID = 1 then
  begin
    { Сенсор 1: Температура }
    SensorConfig.ID := 1;
    SensorConfig.Name := 'Температура';
    SensorConfig.SensorType := stTemperature;
    SensorConfig.MinValue := 0;
    SensorConfig.MaxValue := 100;
    SensorConfig.DefaultValue := 20;
    SensorConfig.UnitName := '°C';
    FSensorFactory.CreateSensor(FChildForm, SensorConfig);

    { Сенсор 2: Влажность }
    SensorConfig.ID := 2;
    SensorConfig.Name := 'Влажность';
    SensorConfig.SensorType := stHumidity;
    SensorConfig.MinValue := 0;
    SensorConfig.MaxValue := 100;
    SensorConfig.DefaultValue := 50;
    SensorConfig.UnitName := '%';
    FSensorFactory.CreateSensor(FChildForm, SensorConfig);

    { Сенсор 3: Давление }
    SensorConfig.ID := 3;
    SensorConfig.Name := 'Давление';
    SensorConfig.SensorType := stPressure;
    SensorConfig.MinValue := 700;
    SensorConfig.MaxValue := 800;
    SensorConfig.DefaultValue := 760;
    SensorConfig.UnitName := 'мм рт.ст.';
    FSensorFactory.CreateSensor(FChildForm, SensorConfig);
  end
  else if FInfo.ID = 2 then
  begin
    { Устройство 2: 3 сенсора }
    { Сенсор 1: Влажность }
    SensorConfig.ID := 1;
    SensorConfig.Name := 'Влажность';
    SensorConfig.SensorType := stHumidity;
    SensorConfig.MinValue := 0;
    SensorConfig.MaxValue := 100;
    SensorConfig.DefaultValue := 45;
    SensorConfig.UnitName := '%';
    FSensorFactory.CreateSensor(FChildForm, SensorConfig);

    { Сенсор 2: Температура }
    SensorConfig.ID := 2;
    SensorConfig.Name := 'Температура';
    SensorConfig.SensorType := stTemperature;
    SensorConfig.MinValue := -20;
    SensorConfig.MaxValue := 50;
    SensorConfig.DefaultValue := 22;
    SensorConfig.UnitName := '°C';
    FSensorFactory.CreateSensor(FChildForm, SensorConfig);

    { Сенсор 3: Давление }
    SensorConfig.ID := 3;
    SensorConfig.Name := 'Давление';
    SensorConfig.SensorType := stPressure;
    SensorConfig.MinValue := 700;
    SensorConfig.MaxValue := 800;
    SensorConfig.DefaultValue := 755;
    SensorConfig.UnitName := 'мм рт.ст.';
    FSensorFactory.CreateSensor(FChildForm, SensorConfig);
  end;
end;

procedure TDevice.ReceiveData(SensorID: Integer; const Value: Variant);
begin
  if Assigned(FSensorFactory) then
    FSensorFactory.UpdateSensorValue(SensorID, Value);
end;

procedure TDevice.CloseSensorForm;
begin
  if Assigned(FChildForm) then
  begin
    FChildForm.Close;
    FChildForm.Free;
    FChildForm := nil;
  end;
end;

{ TDeviceList }

function TDeviceList.Add(Device: TDevice): Integer;
begin
  Result := inherited Add(Device);
end;

function TDeviceList.GetDevice(Index: Integer): TDevice;
begin
  Result := TDevice(inherited Get(Index));
end;

function TDeviceList.FindByID(ID: Integer): TDevice;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if Devices[i].Info.ID = ID then
    begin
      Result := Devices[i];
      Exit;
    end;
  end;
end;

function TDeviceList.FindByName(const AName: string): TDevice;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if SameText(Devices[i].Info.Name, AName) then
    begin
      Result := Devices[i];
      Exit;
    end;
  end;
end;

{ TDeviceManager }

class function TDeviceManager.Instance: TDeviceManager;
begin
  if not Assigned(FInstance) then
  begin
    if not Assigned(FDeviceManagerLock) then
      FDeviceManagerLock := TCriticalSection.Create;

    FDeviceManagerLock.Enter;
    try
      if not Assigned(FInstance) then
        FInstance := TDeviceManager.Create;
    finally
      FDeviceManagerLock.Leave;
    end;
  end;
  Result := FInstance;
end;

constructor TDeviceManager.Create;
begin
  inherited Create;
  FDeviceList := TDeviceList.Create(True);
  FMainForm := nil;
  FOnDeviceConnect := nil;
  FOnDeviceDisconnect := nil;
end;

destructor TDeviceManager.Destroy;
begin
  DisconnectAll;
  FDeviceList.Free;
  inherited Destroy;
end;

procedure TDeviceManager.Initialize(MainForm: TForm);
begin
  FMainForm := MainForm;
end;

function TDeviceManager.AddDevice(const Info: TDeviceInfo): TDevice;
begin
  if not Assigned(FMainForm) then
    raise Exception.Create('DeviceManager не инициализирован');

  Result := TDevice.Create(Info, FMainForm);
  FDeviceList.Add(Result);
end;

procedure TDeviceManager.RemoveDevice(DeviceID: Integer);
var
  Device: TDevice;
begin
  Device := FindDevice(DeviceID);
  if Assigned(Device) then
  begin
    Device.Disconnect;
    FDeviceList.Remove(Device);
  end;
end;

function TDeviceManager.FindDevice(ID: Integer): TDevice;
begin
  Result := FDeviceList.FindByID(ID);
end;

function TDeviceManager.ConnectDevice(DeviceID: Integer): Boolean;
var
  Device: TDevice;
begin
  Result := False;
  Device := FindDevice(DeviceID);
  if Assigned(Device) then
  begin
    Result := Device.Connect;
    if Result and Assigned(FOnDeviceConnect) then
      FOnDeviceConnect(Device);
  end;
end;

procedure TDeviceManager.DisconnectDevice(DeviceID: Integer);
var
  Device: TDevice;
begin
  Device := FindDevice(DeviceID);
  if Assigned(Device) then
  begin
    Device.Disconnect;
    if Assigned(FOnDeviceDisconnect) then
      FOnDeviceDisconnect(Device);
  end;
end;

procedure TDeviceManager.DisconnectAll;
var
  i: Integer;
begin
  for i := FDeviceList.Count - 1 downto 0 do
    DisconnectDevice(FDeviceList[i].Info.ID);
end;

procedure TDeviceManager.ReceiveSensorData(DeviceID: Integer;
  SensorID: Integer; const Value: Variant);
var
  Device: TDevice;
begin
  Device := FindDevice(DeviceID);
  if Assigned(Device) then
    Device.ReceiveData(SensorID, Value);
end;

initialization
  FDeviceManagerLock := TCriticalSection.Create;

finalization
  if Assigned(FDeviceManagerInstance) then
    FDeviceManagerInstance.Free;
  if Assigned(FDeviceManagerLock) then
    FDeviceManagerLock.Free;

end.
