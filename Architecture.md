# Руководство по архитектуре приложения для работы с устройствами и сенсорами

## Обзор

Данное приложение на Delphi/RAD Studio 2010 предназначено для:
- Приема данных от подключенных устройств
- Отображения данных сенсоров на форме с использованием компонентов Delphi
- Динамического создания UI элементов на основе конфигурации из таблиц

## Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                      MainForm (UI)                          │
│  ┌─────────────┐  ┌─────────────────────────────────────┐   │
│  │ TStringGrid │  │        Панель сенсоров              │   │
│  │  (устройства)│  │  ┌─────┐ ┌─────┐ ┌─────┐          │   │
│  │             │  │  │TrkBr│ │Prgrs│ │ Edit│ ...       │   │
│  └─────────────┘  │  └─────┘ └─────┘ └─────┘          │   │
│                   └─────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    DeviceManager                            │
│  - Управление списком устройств                             │
│  - Подключение/отключение                                   │
│  - Создание дочерних форм с сенсорами                       │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    SensorFactory                            │
│  - Создание UI компонентов для сенсоров                     │
│  - Типы: TrackBar, ProgressBar, Edit, CheckBox, Grid        │
│  - Привязка к данным из таблицы конфигурации                │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     SensorTypes                             │
│  - Базовые классы TSensor, TSensorList                      │
│  - Типы сенсоров: stAnalog, stDigital, stNumeric, stText    │
│  - Статусы: ssOK, ssWarning, ssError, ssDisconnected        │
└─────────────────────────────────────────────────────────────┘
```

## Структура файлов

```
/workspace/
├── SensorDemo.dpr                 # Главный файл проекта
├── Source/
│   ├── UI/
│   │   └── MainForm.pas           # Главная форма
│   ├── Devices/
│   │   └── DeviceManager.pas      # Менеджер устройств
│   ├── Sensors/
│   │   ├── SensorTypes.pas        # Базовые типы сенсоров
│   │   └── SensorFactory.pas      # Фабрика сенсоров
│   └── Common/                    # Общие модули (Log, FIFO, etc.)
└── Documentation/
    └── Architecture.md            # Этот файл
```

## Ключевые компоненты

### 1. SensorTypes.pas

Определяет базовую инфраструктуру для работы с сенсорами:

```pascal
TSensorType = (
  stAnalog,    // TrackBar, ProgressBar
  stDigital,   // CheckBox
  stNumeric,   // Edit (числа)
  stText,      // Edit (текст)
  stCustom     // Пользовательский тип
);
TSensorStatus = (
  ssOK, ssWarning, ssError, ssDisconnected
);
TSensor = class
  property ID: Integer;
  property Name: string;
  property SensorType: TSensorType;
  property Status: TSensorStatus;
  property Data: TSensorData;
  procedure UpdateData(const Value: Variant);
end;
```

### 2. SensorFactory.pas

Фабрика для динамического создания UI компонентов на основе конфигурации:

```pascal
TSensorConfig = record
  ID: Integer;
  Name: string;
  SensorType: TSensorType;
  MinValue, MaxValue: Variant;
  UnitName: string;
  Row, Col, Width, Height: Integer; // Позиция на форме
end;
TSensorFactory = class
  function CreateSensor(const Config: TSensorConfig): TSensorComponent;
  procedure UpdateSensorValue(ID: Integer; const Value: Variant);
end;
```

**Создаваемые компоненты:**
- **TrackBar** - для аналоговых сенсоров (0-100, напряжение, ток)
- **ProgressBar** - для визуализации уровня
- **Edit** - для числовых и текстовых значений
- **CheckBox** - для цифровых (boolean) сенсоров
- **Label** - для отображения имени и единиц измерения
- **Panel** - для группировки элементов

### 3. DeviceManager.pas

Управляет устройствами и их жизненным циклом:

```pascal
TDevice = class
  property Info: TDeviceInfo;
  property SensorFactory: TSensorFactory;
  property ChildForm: TForm;  // Дочерняя форма с сенсорами
  
  function Connect: Boolean;
  procedure Disconnect;
  procedure CreateSensorForm(Parent: TForm);
  procedure ReceiveData(SensorID: Integer; const Value: Variant);
end;
TDeviceManager = class
  class function Instance: TDeviceManager;  // Singleton
  function AddDevice(const Info: TDeviceInfo): TDevice;
  function ConnectDevice(DeviceID: Integer): Boolean;
  procedure DisconnectDevice(DeviceID: Integer);
  procedure ReceiveSensorData(DeviceID, SensorID: Integer; const Value: Variant);
end;
```

### 4. MainForm.pas

Главная форма приложения:

**Компоненты:**
- `TStringGrid` - список подключенных устройств (из таблицы конфигурации)
- `TPanel` - панели для разделения интерфейса
- `TSplitter` - изменяемый размер панелей
- `TStatusBar` - строка состояния
- `TMainMenu` / `TToolBar` - меню и инструменты
- `TTimer` - периодический опрос устройств

**Функционал:**
- Отображение списка устройств из таблицы
- Подключение/отключение устройств
- Создание дочерних форм с сенсорами при подключении
- Получение и отображение данных в реальном времени

## Поток данных

```
1. Загрузка конфигурации
   └─> Чтение таблицы устройств
   └─> Чтение таблицы сенсоров для каждого устройства
2. Подключение устройства
   └─> TDeviceManager.ConnectDevice()
   └─> TDevice.Connect()
   └─> TDevice.CreateSensorForm()
       └─> Создается дочерняя TForm
       └─> SensorFactory.CreateSensor() для каждого сенсора из таблицы
           └─> Создаются: Panel, Label, TrackBar/ProgressBar/Edit/etc.
3. Получение данных
   └─> Устройство отправляет данные
   └─> TDeviceManager.ReceiveSensorData(DeviceID, SensorID, Value)
   └─> TDevice.ReceiveData(SensorID, Value)
   └─> TSensorFactory.UpdateSensorValue(SensorID, Value)
   └─> TSensor.UpdateData(Value)
   └─> Событие OnChange
   └─> TSensorComponent.UpdateDisplay()
       └─> Обновление UI компонента (TrackBar.Position, Edit.Text, etc.)
```

## Пример использования

### Добавление устройства из таблицы

```pascal
var
  DeviceInfo: TDeviceInfo;
begin
  DeviceInfo.ID := 1;
  DeviceInfo.Name := 'Device-001';
  DeviceInfo.Description := 'Тестовое устройство';
  DeviceInfo.DeviceType := 'USB';
  DeviceInfo.Connected := False;
  
  Device := FDeviceManager.AddDevice(DeviceInfo);
end;
```

### Создание сенсоров при подключении

```pascal
procedure TDevice.CreateSensorForm(Parent: TForm);
var
  Config: TSensorConfig;
begin
  FChildForm := TForm.Create(Parent);
  FChildForm.Parent := Parent;
  FChildForm.Align := alClient;
  
  { Загрузка конфигурации сенсоров из таблицы }
  { Пример для температурного сенсора }
  Config.ID := 1;
  Config.Name := 'Температура';
  Config.SensorType := stNumeric;
  Config.MinValue := -40;
  Config.MaxValue := 85;
  Config.UnitName := '°C';
  Config.Row := 0;
  Config.Col := 0;
  Config.Width := 200;
  Config.Height := 80;
  
  FSensorFactory.CreateSensor(Config);
  
  { Пример для аналогового сенсора (напряжение) }
  Config.ID := 2;
  Config.Name := 'Напряжение';
  Config.SensorType := stAnalog;
  Config.MinValue := 0;
  Config.MaxValue := 5000;
  Config.UnitName := 'mV';
  Config.Row := 0;
  Config.Col := 1;
  
  FSensorFactory.CreateSensor(Config);
  
  FChildForm.Show;
end;
```

### Обновление данных от устройства

```pascal
{ При получении данных от устройства }
procedure OnDataReceived(DeviceID, SensorID: Integer; Value: Double);
begin
  FDeviceManager.ReceiveSensorData(DeviceID, SensorID, Value);
end;
{ Визуальное обновление происходит автоматически через события }
```

## Расширение функциональности

### Добавление нового типа сенсора

1. Добавьте новый тип в `TSensorType`:
```pascal
TSensorType = (
  stAnalog, stDigital, stNumeric, stText, stCustom,
  stGauge  // Новый тип
);
```

2. Обновите `TSensorFactory.CreateSensor`:
```pascal
stGauge:
  begin
    { Создание компонента TGauge или другого индикатора }
  end;
```

### Интеграция с базой данных

Для загрузки конфигурации из реальной таблицы замените `LoadDeviceConfig`:

```pascal
procedure TMainForm.LoadDeviceConfig;
var
  Query: TADOQuery;  // Или другой компонент БД
begin
  Query := TADOQuery.Create(nil);
  try
    Query.Connection := FDConnection;  // Ваше подключение к БД
    Query.SQL.Text := 'SELECT * FROM Devices';
    Query.Open;
    
    while not Query.EOF do
    begin
      DeviceInfo.ID := Query.FieldByName('ID').AsInteger;
      DeviceInfo.Name := Query.FieldByName('Name').AsString;
      // ... остальные поля
      FDeviceManager.AddDevice(DeviceInfo);
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;
```

## Примечания для RAD Studio 2010

1. **Совместимость**: Код написан с учетом особенностей Delphi 2010
2. **Компоненты**: Используются стандартные компоненты VCL
3. **Кодировка**: UTF-8 с BOM для корректного отображения кириллицы
4. **DFM файлы**: Для каждой формы необходимо создать .dfm файл в дизайнере

## Следующие шаги

1. Создать .dfm файлы для форм в дизайнере RAD Studio
2. Реализовать конкретные драйверы для устройств (USB, COM, сеть)
3. Настроить подключение к таблице конфигурации (БД, файл, реестр)
4. Добавить систему логирования через модуль Log.pas
5. Реализовать механизм сохранения настроек пользователя
