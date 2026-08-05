unit SensorTypes;

{**
  @file SensorTypes.pas
  @brief Базовые типы для сенсоров

  Определяет базовые классы и типы для работы с сенсорами устройств.
*}

interface

uses
  Classes, SysUtils, Contnrs, Variants;

type
  { Типы сенсоров }
  TSensorType = (
    stAnalog,      // Аналоговый сенсор (TrackBar, ProgressBar)
    stDigital,     // Цифровой сенсор (CheckBox, Edit)
    stNumeric,     // Числовой сенсор (Edit, SpinEdit)
    stText,        // Текстовый сенсор (Memo, Edit)
    stTemperature, // Датчик температуры
    stHumidity,    // Датчик влажности
    stPressure,    // Датчик давления
    stCustom       // Пользовательский тип
  );

  { Статус сенсора }
  TSensorStatus = (
    ssOK,          // Норма
    ssWarning,     // Предупреждение
    ssError,       // Ошибка
    ssDisconnected // Отключен
  );

  { Данные сенсора }
  TSensorData = record
    Value: Variant;        // Текущее значение
    MinValue: Variant;     // Минимальное значение
    MaxValue: Variant;     // Максимальное значение
    UnitName: string;      // Единица измерения
    Status: TSensorStatus; // Статус
    Timestamp: TDateTime;  // Время последнего обновления
  end;

  { Базовый класс сенсора }
  TSensor = class(TObject)
  private
    FID: Integer;
    FName: string;
    FDescription: string;
    FSensorType: TSensorType;
    FStatus: TSensorStatus;
    FData: TSensorData;
    FEnabled: Boolean;
    FOnChange: TNotifyEvent;
  protected
    procedure DoChange; virtual;
    procedure UpdateStatus(const NewStatus: TSensorStatus); virtual;
  public
    constructor Create(AID: Integer; const AName: string); virtual;
    destructor Destroy; override;

    { Обновить данные сенсора }
    procedure UpdateData(const AValue: Variant); virtual;

    { Сбросить сенсор }
    procedure Reset; virtual;

    { Получить строковое представление значения }
    function GetValueAsString: string; virtual;

    { ID сенсора }
    property ID: Integer read FID write FID;

    { Имя сенсора }
    property Name: string read FName write FName;

    { Описание }
    property Description: string read FDescription write FDescription;

    { Тип сенсора }
    property SensorType: TSensorType read FSensorType write FSensorType;

    { Статус }
    property Status: TSensorStatus read FStatus write FStatus;

    { Данные }
    property Data: TSensorData read FData write FData;

    { Доступность }
    property Enabled: Boolean read FEnabled write FEnabled;

    { Событие изменения }
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  { Коллекция сенсоров }
  TSensorList = class(TObjectList)
  private
    function GetSensor(Index: Integer): TSensor;
  public
    constructor Create;
    function Add(Sensor: TSensor): Integer;
    function FindByID(ID: Integer): TSensor;
    function FindByName(const AName: string): TSensor;
    property Sensors[Index: Integer]: TSensor read GetSensor; default;
  end;

implementation

{ TSensor }

constructor TSensor.Create(AID: Integer; const AName: string);
begin
  inherited Create;
  FID := AID;
  FName := AName;
  FDescription := '';
  FSensorType := stCustom;
  FStatus := ssDisconnected;
  FEnabled := True;
  FData.Value := Null;
  FData.MinValue := Null;
  FData.MaxValue := Null;
  FData.UnitName := '';
  FData.Status := ssDisconnected;
  FData.Timestamp := 0;
  FOnChange := nil;
end;

destructor TSensor.Destroy;
begin
  inherited Destroy;
end;

procedure TSensor.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TSensor.UpdateStatus(const NewStatus: TSensorStatus);
begin
  if FStatus <> NewStatus then
  begin
    FStatus := NewStatus;
    FData.Status := NewStatus;
    DoChange;
  end;
end;

procedure TSensor.UpdateData(const AValue: Variant);
begin
  FData.Value := AValue;
  FData.Timestamp := Now;
  if FStatus = ssDisconnected then
    UpdateStatus(ssOK);
  DoChange;
end;

procedure TSensor.Reset;
begin
  FData.Value := Null;
  FData.Timestamp := 0;
  UpdateStatus(ssDisconnected);
end;

function TSensor.GetValueAsString: string;
begin
  if VarIsNull(FData.Value) then
    Result := 'N/A'
  else
    Result := VarToStr(FData.Value) + ' ' + FData.UnitName;
end;

{ TSensorList }

constructor TSensorList.Create;
begin
  inherited Create(True); // Ownership включено - список удаляет объекты при уничтожении
end;

function TSensorList.Add(Sensor: TSensor): Integer;
begin
  Result := inherited Add(Sensor);
end;

function TSensorList.GetSensor(Index: Integer): TSensor;
begin
  Result := TSensor(inherited Get(Index));
end;

function TSensorList.FindByID(ID: Integer): TSensor;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if Sensors[i].ID = ID then
    begin
      Result := Sensors[i];
      Exit;
    end;
  end;
end;

function TSensorList.FindByName(const AName: string): TSensor;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if SameText(Sensors[i].Name, AName) then
    begin
      Result := Sensors[i];
      Exit;
    end;
  end;
end;

end.
