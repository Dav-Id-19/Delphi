unit uMainForm;

{**
  @file MainForm.pas
  @brief Главная форма приложения

  Основная форма для управления устройствами и отображения данных сенсоров.
  Использует компоненты: Grid (список устройств), Panel, StatusBar и др.
*}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Grids, ComCtrls, Menus, ToolWin, ImgList,
  DeviceManager, SensorTypes, SensorFactory;

type
  TMainForm = class(TForm)
    { Основные компоненты }
    pnlMain: TPanel;
    pnlDevices: TPanel;
    pnlSensors: TPanel;
    splMain: TSplitter;

    { Grid со списком устройств }
    grdDevices: TStringGrid;

    { Статус бар }
    stbMain: TStatusBar;

    { Меню }
    mnuMain: TMainMenu;
    mnuFile: TMenuItem;
    mnuExit: TMenuItem;
    mnuDevices: TMenuItem;
    mnuConnect: TMenuItem;
    mnuDisconnect: TMenuItem;
    mnuHelp: TMenuItem;
    mnuAbout: TMenuItem;

    { Панель инструментов }
    tlbMain: TToolBar;
    btnConnect: TToolButton;
    btnDisconnect: TToolButton;
    sep1: TToolButton;
    btnRefresh: TToolButton;

    { Изображения }
    ilMain: TImageList;

    { Таймер для опроса устройств }
    tmrPoll: TTimer;

    { События }
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

    procedure grdDevicesClick(Sender: TObject);
    procedure grdDevicesDblClick(Sender: TObject);

    procedure mnuConnectClick(Sender: TObject);
    procedure mnuDisconnectClick(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
    procedure mnuAboutClick(Sender: TObject);

    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);

    procedure tmrPollTimer(Sender: TObject);
  private
    FDeviceManager: TDeviceManager;
    FSelectedDeviceID: string;
    FSensorForms: TList; // Список открытых форм с сенсорами

    { Инициализация грида устройств }
    procedure InitDeviceGrid;

    { Обновление грида устройств }
    procedure UpdateDeviceGrid;

    { Загрузка конфигурации из таблицы }
    procedure LoadDeviceConfig;

    { Обработка подключения устройства }
    procedure OnDeviceConnect(Sender: TObject);

    { Обработка отключения устройства }
    procedure OnDeviceDisconnect(Sender: TObject);

    { Получение данных от устройств (пример) }
    procedure PollDevices;

    { Показать сенсоры устройства }
    procedure ShowDeviceSensors(ADeviceID: string);

    { Обновить все открытые формы сенсоров }
    procedure UpdateSensorForms;
  public
    { Конструктор }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Получить менеджер устройств }
    property DeviceManager: TDeviceManager read FDeviceManager;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

{ TMainForm }

constructor TMainForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDeviceManager := nil;
  FSelectedDeviceID := '';
  FSensorForms := TList.Create;
end;

destructor TMainForm.Destroy;
begin
  // Закрываем все формы сенсоров
  while FSensorForms.Count > 0 do
  begin
    TForm(FSensorForms[0]).Free;
    FSensorForms.Delete(0);
  end;
  FSensorForms.Free;
  inherited Destroy;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  { Инициализация менеджера устройств }
  FDeviceManager := TDeviceManager.Instance;
  FDeviceManager.Initialize(Self);
  FDeviceManager.OnDeviceConnect := OnDeviceConnect;
  FDeviceManager.OnDeviceDisconnect := OnDeviceDisconnect;

  { Инициализация грида }
  InitDeviceGrid;

  { Загрузка конфигурации устройств из таблицы }
  LoadDeviceConfig;

  { Обновление грида }
  UpdateDeviceGrid;

  { Установка статуса }
  stbMain.Panels[0].Text := 'Готово';

  { Запуск таймера опроса }
  tmrPoll.Enabled := True;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  { Остановка таймера }
  tmrPoll.Enabled := False;

  { Отключение всех устройств }
  if Assigned(FDeviceManager) then
    FDeviceManager.DisconnectAll;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  { Проверка возможности закрытия }
  CanClose := True;
end;

procedure TMainForm.InitDeviceGrid;
begin
  with grdDevices do
  begin
    ColCount := 4;
    RowCount := 2;
    Cells[0, 0] := 'ID';
    Cells[1, 0] := 'Имя';
    Cells[2, 0] := 'Статус';
    Cells[3, 0] := 'Сенсоров';

    ColWidths[0] := 80;
    ColWidths[1] := 200;
    ColWidths[2] := 100;
    ColWidths[3] := 80;

    Options := Options + [goRowSelect];
  end;
end;

procedure TMainForm.LoadDeviceConfig;
var
  Dev1, Dev2: TDevice;
begin
  { Создаем тестовые устройства по ТЗ }

  { Устройство 1: ID1 - 1 сенсор с 3 значениями (Температура, Влажность, Давление) }
  Dev1 := TDevice.Create;
  Dev1.ID := 'ID1';
  Dev1.Name := 'Устройство 1 (Климатический комплекс)';
  Dev1.Connected := False;

  // Добавляем 1 мультисенсор
  with Dev1.Sensors.Add do
  begin
    ID := 'ID1_S1';
    Name := 'Климатический сенсор';
    SensorType := stMulti; // Специальный тип для 3 значений
    UnitName := '';
    MinValue := 0;
    MaxValue := 100;
    CurrentValue := 0;
  end;

  FDeviceManager.RegisterDevice(Dev1);

  { Устройство 2: ID2 - 3 отдельных сенсора (Влажность, Температура, Давление) }
  Dev2 := TDevice.Create;
  Dev2.ID := 'ID2';
  Dev2.Name := 'Устройство 2 (Раздельные датчики)';
  Dev2.Connected := False;

  // Сенсор 1: Влажность
  with Dev2.Sensors.Add do
  begin
    ID := 'ID2_S1';
    Name := 'Датчик влажности';
    SensorType := stHumidity;
    UnitName := '%';
    MinValue := 0;
    MaxValue := 100;
    CurrentValue := 0;
  end;

  // Сенсор 2: Температура
  with Dev2.Sensors.Add do
  begin
    ID := 'ID2_S2';
    Name := 'Датчик температуры';
    SensorType := stTemperature;
    UnitName := '°C';
    MinValue := -20;
    MaxValue := 50;
    CurrentValue := 0;
  end;

  // Сенсор 3: Давление
  with Dev2.Sensors.Add do
  begin
    ID := 'ID2_S3';
    Name := 'Датчик давления';
    SensorType := stPressure;
    UnitName := 'мм рт.ст.';
    MinValue := 700;
    MaxValue := 800;
    CurrentValue := 0;
  end;

  FDeviceManager.RegisterDevice(Dev2);
end;

procedure TMainForm.UpdateDeviceGrid;
var
  i: Integer;
  Device: TDevice;
begin
  grdDevices.RowCount := FDeviceManager.Devices.Count + 1;

  for i := 0 to FDeviceManager.Devices.Count - 1 do
  begin
    Device := FDeviceManager.Devices[i];
    grdDevices.Cells[0, i + 1] := Device.ID;
    grdDevices.Cells[1, i + 1] := Device.Name;
    grdDevices.Cells[2, i + 1] := IfThen(Device.Connected, 'Онлайн', 'Оффлайн');
    grdDevices.Cells[3, i + 1] := IntToStr(Device.Sensors.Count);
  end;
end;

procedure TMainForm.grdDevicesClick(Sender: TObject);
var
  Row: Integer;
begin
  Row := grdDevices.Row;
  if Row > 0 then
  begin
    FSelectedDeviceID := grdDevices.Cells[0, Row];
    stbMain.Panels[1].Text := 'Выбрано устройство: ' + FSelectedDeviceID;
    ShowDeviceSensors(FSelectedDeviceID);
  end;
end;

procedure TMainForm.grdDevicesDblClick(Sender: TObject);
var
  Device: TDevice;
begin
  { Двойной клик - подключение/отключение }
  if FSelectedDeviceID <> '' then
  begin
    Device := FDeviceManager.GetDeviceByID(FSelectedDeviceID);
    if Assigned(Device) then
    begin
      if Device.Connected then
        FDeviceManager.DisconnectDevice(FSelectedDeviceID)
      else
        FDeviceManager.ConnectDevice(FSelectedDeviceID);
    end;
  end;
end;

procedure TMainForm.mnuConnectClick(Sender: TObject);
var
  Device: TDevice;
begin
  if FSelectedDeviceID <> '' then
  begin
    Device := FDeviceManager.GetDeviceByID(FSelectedDeviceID);
    if Assigned(Device) then
    begin
      if not Device.Connected then
      begin
        if FDeviceManager.ConnectDevice(FSelectedDeviceID) then
        begin
          ShowDeviceSensors(FSelectedDeviceID);
          stbMain.Panels[0].Text := 'Устройство подключено';
        end;
      end
      else
        ShowMessage('Устройство уже подключено');
    end
    else
      ShowMessage('Устройство не найдено');
  end
  else
    ShowMessage('Выберите устройство из списка');
end;

procedure TMainForm.mnuDisconnectClick(Sender: TObject);
begin
  if FSelectedDeviceID <> '' then
  begin
    FDeviceManager.DisconnectDevice(FSelectedDeviceID);
    stbMain.Panels[0].Text := 'Устройство отключено';
  end;
end;

procedure TMainForm.mnuExitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.mnuAboutClick(Sender: TObject);
begin
  ShowMessage('Программа для работы с устройствами и сенсорами'#13#10 +
              'Версия 1.0'#13#10 +
              'Delphi/RAD Studio 2010'#13#10#13#10 +
              'ID1: 1 сенсор (Температура, Влажность, Давление)'#13#10 +
              'ID2: 3 сенсора (Влажность, Температура, Давление)');
end;

procedure TMainForm.btnConnectClick(Sender: TObject);
begin
  mnuConnectClick(Sender);
end;

procedure TMainForm.btnDisconnectClick(Sender: TObject);
begin
  mnuDisconnectClick(Sender);
end;

procedure TMainForm.btnRefreshClick(Sender: TObject);
begin
  UpdateDeviceGrid;
  stbMain.Panels[0].Text := 'Список устройств обновлен';
end;

procedure TMainForm.tmrPollTimer(Sender: TObject);
begin
  { Периодический опрос устройств }
  PollDevices;
  UpdateSensorForms;
end;

procedure TMainForm.PollDevices;
var
  i: Integer;
  Device: TDevice;
  S: TSensor;
begin
  { Эмуляция получения данных от устройств }
  Randomize;

  for i := 0 to FDeviceManager.Devices.Count - 1 do
  begin
    Device := FDeviceManager.Devices[i];
    if Device.Connected then
    begin
      if Device.Sensors.Count > 0 then
      begin
        S := Device.Sensors[0];

        if S.SensorType = stMulti then
        begin
          // Для мультисенсора генерируем 3 значения
          // В реальном приложении здесь будет парсинг пакета данных
          S.CurrentValue := 25 + Random(5); // Температура
          // Дополнительные значения можно хранить в расширенных полях
          // Для простоты эмулируем только одно значение
        end
        else
        begin
          case S.SensorType of
            stTemperature: S.CurrentValue := 20 + Random(10); // 20..30 °C
            stHumidity: S.CurrentValue := 40 + Random(40);   // 40..80 %
            stPressure: S.CurrentValue := 740 + Random(20);  // 740..760 мм рт.ст.
          end;
        end;

        S.LastUpdate := Now;
        S.Status := ssOk;
      end;
    end;
  end;
end;

procedure TMainForm.ShowDeviceSensors(ADeviceID: string);
var
  Device: TDevice;
  Frm: TForm;
  i: Integer;
begin
  Device := FDeviceManager.GetDeviceByID(ADeviceID);
  if not Assigned(Device) then Exit;

  if not Device.Connected then
  begin
    ShowMessage('Сначала подключите устройство');
    Exit;
  end;

  // Проверяем, есть ли уже открытая форма для этого устройства
  for i := 0 to FSensorForms.Count - 1 do
  begin
    Frm := TForm(FSensorForms[i]);
    if Frm.Tag = Device.ID.GetHashCode then
    begin
      Frm.BringToFront;
      Exit;
    end;
  end;

  // Создаем новую форму с сенсорами
  Frm := TForm.Create(Self);
  Frm.Caption := 'Сенсоры устройства: ' + Device.Name;
  Frm.Width := 500;
  Frm.Height := 400;
  Frm.Position := poScreenCenter;
  Frm.Tag := Device.ID.GetHashCode;

  // Используем фабрику для создания контролов
  try
    TSensorFactory.CreateSensorsOnForm(Frm, Device.Sensors);
  except
    on E: Exception do
    begin
      ShowMessage('Ошибка создания формы сенсоров: ' + E.Message);
      Frm.Free;
      Exit;
    end;
  end;

  FSensorForms.Add(Frm);
  Frm.Show;
end;

procedure TMainForm.UpdateSensorForms;
var
  i: Integer;
  Frm: TForm;
begin
  // Обновляем данные на всех открытых формах сенсоров
  // Формы должны сами подписаться на события или иметь метод обновления
  // Для простоты просто вызываем перерисовку
  for i := 0 to FSensorForms.Count - 1 do
  begin
    Frm := TForm(FSensorForms[i]);
    if Assigned(Frm) and Frm.Visible then
      Frm.Invalidate;
  end;
end;

procedure TMainForm.OnDeviceConnect(Sender: TObject);
var
  Device: TDevice;
begin
  if Sender is TDevice then
  begin
    Device := TDevice(Sender);
    UpdateDeviceGrid;
    stbMain.Panels[0].Text := 'Подключено: ' + Device.Name;
  end;
end;

procedure TMainForm.OnDeviceDisconnect(Sender: TObject);
var
  Device: TDevice;
begin
  if Sender is TDevice then
  begin
    Device := TDevice(Sender);
    UpdateDeviceGrid;
    stbMain.Panels[0].Text := 'Отключено: ' + Device.Name;
  end;
end;

end.
