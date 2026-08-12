unit PortExpanderLED;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Math, Types;

type
  TExpanderOrientation = (eoVertical, eoHorizontal);
  TExpanderLabelsPos = (lpTop, lpBottom, lpLeft, lpRight);
  TLabelsSide = (lsLeft, lsRight); // Если еще не объявлен
  TExpanderGroupCount = 1..4;              // Если еще не объявлен
  TExpanderLEDShape = (lsCircle, lsSquare); // Если используется свойство формы
  TExpanderMode = (emDigital, emAnalog);

  TExpanderLEDClickEvent = procedure(Sender: TObject; Index: Integer; Value: Word) of object;

  // Элемент коллекции цветов для аналогового режима
  // Объявление элемента коллекции для аналоговых цветов
  TAnalogColorItem = class(TCollectionItem)
  private
    FColor: TColor;
    FThreshold: Word; // Пороговое значение
    FActive: Boolean; // Является ли этот цвет активным при клике
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
  published
    property Color: TColor read FColor write FColor default clRed;
    property Threshold: Word read FThreshold write FThreshold default 0;
    property Active: Boolean read FActive write FActive default False;
  end;

  TAnalogColors = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TAnalogColorItem;
    procedure SetItem(Index: Integer; Value: TAnalogColorItem);
  public
    constructor  Create(AOwner: TPersistent);// Или   Create(ItemClass: TCollectionItemClass);
    function Add: TAnalogColorItem;
    property Items[Index: Integer]: TAnalogColorItem read GetItem write SetItem; default;
  end;

  TPortExpanderLED = class(TCustomControl)
  private
    FOnLedClick: TExpanderLEDClickEvent;
    FOrientation: TExpanderOrientation;
    FLabelsPos: TExpanderLabelsPos;
    FGroupCount: TExpanderGroupCount;
    FLEDShape: TExpanderLEDShape;
    FMode: TExpanderMode;
    FValues: array[0..31] of Integer; // Хранит состояния: -1 (нет), 0/1 (Digital), 0..65535 (Analog)
//    FPinValues: array[0..31] of Word; // Индивидуальные значения для каждого пина в Analog режиме
    FActiveColorIndex: Integer;
    FAnalogColors: TAnalogColors;

    FBitCount: Integer; // 8, 16, 24, 32
    FGroupGap: Integer;
    FShowGroups: Boolean;
    FHoverIndex: Integer;

    procedure SetOrientation(const Value: TExpanderOrientation);
    procedure SetLabelsPos(const Value: TExpanderLabelsPos);
    procedure SetGroupCount(const Value: TExpanderGroupCount);
    procedure SetLEDShape(const Value: TExpanderLEDShape);
    procedure SetMode(const Value: TExpanderMode);

    procedure SetAnalogColors(const Value: TAnalogColors);
    function GetPinValue(Index: Integer): Integer;
    procedure DrawLed(Index: Integer; const Rect: TRect; Canvas: TCanvas);
////////////////////////////////    function GetColorForValue(Value: Word): TColor;
     procedure InitValues; // для инициализации

    procedure SetBitCount(Value: Integer);
    function GetLEDRect(Index: Integer): TRect;
    function HitTest(X, Y: Integer): Integer;
    procedure DoClick(Index: Integer);
/////////////////////////////////    procedure UpdateColorsFromThresholds;


  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    ////////////////////////////////////////procedure Click; override;

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
//    procedure MouseLeave; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
/////////////////////////////////////////    procedure SetBit(Index: Integer; AValue: Word); // Внешний метод установки значения по адресу
    procedure SetValue(Index: Integer; const Value: Integer);
    property PinValues[Index: Integer]: Integer read GetPinValue write SetValue;

  property HoverIndex: Integer read FHoverIndex;


  published
    property Align;
    property Orientation: TExpanderOrientation read FOrientation write SetOrientation default eoVertical;
    property LabelsPos: TExpanderLabelsPos read FLabelsPos write SetLabelsPos default lpLeft;
    property GroupCount: TExpanderGroupCount read FGroupCount write SetGroupCount default 1;
    property LEDShape: TExpanderLEDShape read FLEDShape write SetLEDShape default lsCircle;
    property Mode: TExpanderMode read FMode write SetMode default emDigital;

    property ActiveColorIndex: Integer read FActiveColorIndex write FActiveColorIndex default 0;
    property AnalogColors: TAnalogColors read FAnalogColors write SetAnalogColors;
    property OnLedClick: TExpanderLEDClickEvent read FOnLedClick write FOnLedClick;
    property Anchors;
    property Color;
    property Enabled;
    property ParentColor;
    property ParentShowHint;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;

    property BitCount: Integer read FBitCount write SetBitCount default 8;
    property GroupGap: Integer read FGroupGap write FGroupGap default 4;
    property ShowGroups: Boolean read FShowGroups write FShowGroups default True;
    // Значение всего компонента (маска для Digital, базовое для Analog)


    property OnClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;

  end;


procedure Register;

implementation

procedure TPortExpanderLED.SetLEDShape(const Value: TExpanderLEDShape);
begin
  if FLEDShape <> Value then
  begin
    FLEDShape := Value;
    Invalidate; // Перерисовать компонент при изменении формы
  end;
end;

procedure TPortExpanderLED.SetLabelsPos(const Value: TExpanderLabelsPos);
begin
  if FLabelsPos <> Value then
  begin
    FLabelsPos := Value;
    Invalidate; // Перерисовать компонент с новыми позициями подписей
  end;
end;

function TPortExpanderLED.GetPinValue(Index: Integer): integer;
begin
  if (Index < 0) or (Index > 31) then Result := -1
  else
    Result := FValues[Index];
end;

procedure TPortExpanderLED.InitValues;
var
  i: Integer;
begin
  for i := 0 to 31 do
    FValues[i] := -1; // Инициализация "пустым" значением
end;

{ TAnalogColorItem }
constructor TAnalogColorItem.Create(Collection: TCollection);
begin
  inherited Create(Collection); // Передаем коллекцию в родительский конструктор
  // Инициализация по умолчанию
  FColor := clRed;
  FThreshold := 0;
  // Не нужно делать ничего другого с параметром, базовый класс сам установит свойство Collection
end;

procedure TAnalogColorItem.Assign(Source: TPersistent);
begin
  if Source is TAnalogColorItem then
  begin
    FColor := TAnalogColorItem(Source).FColor;
    FThreshold := TAnalogColorItem(Source).FThreshold;
    FActive := TAnalogColorItem(Source).FActive;
  end
  else
    inherited Assign(Source);
end;


{ TAnalogColors }
constructor TAnalogColors.Create;
begin
  inherited Create(AOwner, TAnalogColorItem);
  //constructor TOwnedCollection.Create(AOwner: TPersistent;  ItemClass: TCollectionItemClass);
end;

function TAnalogColors.Add: TAnalogColorItem;
begin
  Result := TAnalogColorItem(inherited Add);
  Result.FColor := clRed;
  Result.FThreshold := 0;
  Result.FActive := False;
end;

function TAnalogColors.GetItem(Index: Integer): TAnalogColorItem;
begin
  Result := TAnalogColorItem(inherited GetItem(Index));
end;

procedure TAnalogColors.SetItem(Index: Integer; Value: TAnalogColorItem);
begin
  inherited SetItem(Index, Value);
end;

{ TPortExpanderLED }

constructor TPortExpanderLED.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 100;
  Height := 200;
  Color := clWhite;
  FOrientation := eoVertical;
  FLabelsPos := lpLeft;
  LEDShape := lsCircle;
  FMode := emDigital;
  FBitCount := 8;
  FGroupCount := 1;
  FGroupGap := 4;
  FShowGroups := True;
  FHoverIndex := -1;

InitValues; // Вызов инициализации массива
 FAnalogColors := TAnalogColors.Create(Self);
  // Добавим дефолтные цвета для примера
  with FAnalogColors.Add do begin FColor := clRed; FThreshold := 1000; FActive := False; end;
  with FAnalogColors.Add do begin FColor := clYellow; FThreshold := 3000; FActive := False; end;
  with FAnalogColors.Add do begin FColor := clGreen; FThreshold := 65535; FActive := True; end;
  FActiveColorIndex := 2; // По умолчанию последний активный
/////////////////////////////////////////////////////////////////////FAnalogColors.OnNotify := CollectionChanged;
end;

destructor TPortExpanderLED.Destroy;
begin
  FAnalogColors.Free;
  inherited Destroy;
end;

procedure TPortExpanderLED.SetBitCount(Value: Integer);
begin
  if Value in [8, 16, 24, 32] then
  begin
    FBitCount := Value;
    Invalidate;
  end;
end;

procedure TPortExpanderLED.SetOrientation(const Value: TExpanderOrientation);
var sw: Integer;
begin
  if FOrientation <> Value then
  begin
    FOrientation := Value;
    if FOrientation = eoVertical then
    begin
      if Width < Height then
      begin
      sw := Width; Width := Height; Height := sw;
      end;
    end
    else
    begin
      if Height > Width then
      begin
      sw := Width; Width := Height; Height := sw;
      end;
    end;
    Invalidate;
  end;
end;

procedure TPortExpanderLED.SetMode(const Value: TExpanderMode);
begin
  if FMode <> Value then
  begin
    FMode := Value;
    Invalidate;
  end;
end;

procedure TPortExpanderLED.SetGroupCount(const Value: TExpanderGroupCount);
var
  NewValue: TExpanderGroupCount;
begin
  NewValue := Value;
  // Ограничиваем значение диапазоном 1..4
  if NewValue < 1 then NewValue := 1;
  if NewValue > 4 then NewValue := 4;

  if FGroupCount <> NewValue then
  begin
    FGroupCount := NewValue;
    Invalidate; // Перерисовываем компонент при изменении количества групп
  end;
end;

procedure TPortExpanderLED.SetAnalogColors(const Value: TAnalogColors);
begin
  FAnalogColors.Assign(Value);
  Invalidate;
end;

// Внешний метод установки значения для конкретного LED
procedure TPortExpanderLED.SetValue(Index: Integer; const Value: Integer);
var
  NewVal: Integer;
begin
  if (Index < 0) or (Index > 31) then Exit;

  if FMode = emDigital then
  begin
    // В цифровом режиме: 0 -> 0, всё остальное -> 1
    if Value = 0 then
      NewVal := 0
    else
      NewVal := 1;
  end
  else
  begin
    // В аналоговом режиме: значение как есть (обрезаем диапазон 0-65535 для безопасности)
    if Value < 0 then
      NewVal := 0
    else if Value > 65535 then
      NewVal := 65535
    else
      NewVal := Value;
  end;

  // Записываем только если значение изменилось
  if FValues[Index] <> NewVal then
  begin
    FValues[Index] := NewVal;
    Invalidate; // Перерисовываем компонент

    // Если нужно событие изменения конкретного пина, можно добавить его здесь
    // if Assigned(FOnPinChange) then FOnPinChange(Self, Index, NewVal);
  end;
end;

// ПЕРЕПИСАННАЯ ЧАСТЬ С МАССИВОМ ЗНАЧЕНИЙ




function TPortExpanderLED.GetLEDRect(Index: Integer): TRect;
var
  TotalHeight, TotalWidth: Integer;
  LEDSize, Step: Integer;
  GroupSize: Integer;
  TopOffset, LeftOffset: Integer;
  GroupIdx, LocalIdx: Integer;
  GapTotal: Integer;
begin
  Result := Rect(0, 0, 0, 0);

  // Отступы от краев компонента
  TopOffset := 4;
  LeftOffset := 4;

  if FOrientation = eoVertical then
  begin
    TotalHeight := ClientHeight - TopOffset * 2;
    // Учитываем место под подписи, если они слева/справа внутри ClientRect?
    // Нет, подписи рисуем рядом, но размер LED считаем по всей ширине доступной для них
    // Если LabelsPos = lpLeft/Right, сужаем область для LED

    if (FLabelsPos = lpLeft) or (FLabelsPos = lpRight) then
      TotalWidth := ClientWidth - 40 // Место под текст
    else
      TotalWidth := ClientWidth - LeftOffset * 2;

    if TotalWidth < 10 then TotalWidth := 10;
    if TotalHeight < 10 then TotalHeight := 10;

    LEDSize := TotalWidth;
    if LEDSize > 30 then LEDSize := 30; // Макс размер

    // Расчет высоты с учетом групп
    GapTotal := (FGroupCount - 1) * FGroupGap;
    GroupSize := (TotalHeight - GapTotal) div FGroupCount;
    if GroupSize < LEDSize then GroupSize := LEDSize;

    Step := GroupSize div 8; // Шаг внутри группы (всегда 8 диодов в группе)
    if Step < LEDSize then Step := LEDSize;

    GroupIdx := Index div 8;
    LocalIdx := Index mod 8;

    if GroupIdx >= FGroupCount then Exit;

    Result.Top := TopOffset + GroupIdx * (GroupSize + FGroupGap) + LocalIdx * Step;
    Result.Bottom := Result.Top + LEDSize;

    // Центрирование по горизонтали
    if (FLabelsPos = lpLeft) then
    begin
      Result.Left := ClientWidth - LEDSize - 4;
      Result.Right := ClientWidth - 4;
    end
    else if (FLabelsPos = lpRight) then
    begin
      Result.Left := 36; // Место под текст слева
      Result.Right := Result.Left + LEDSize;
    end
    else
    begin
      Result.Left := (ClientWidth - LEDSize) div 2;
      Result.Right := Result.Left + LEDSize;
    end;
  end
  else // Horizontal
  begin
    TotalWidth := ClientWidth - LeftOffset * 2;

    // В горизонтальном режиме подписи сверху/снизу
    if (FLabelsPos = lpTop) or (FLabelsPos = lpBottom) then
      TotalHeight := ClientHeight - 40
    else
      TotalHeight := ClientHeight - TopOffset * 2;

    LEDSize := TotalHeight;
    if LEDSize > 30 then LEDSize := 30;

    GapTotal := (FGroupCount - 1) * FGroupGap;
    GroupSize := (TotalWidth - GapTotal) div FGroupCount;
    if GroupSize < LEDSize then GroupSize := LEDSize;

    Step := GroupSize div 8;
    if Step < LEDSize then Step := LEDSize;

    GroupIdx := Index div 8;
    LocalIdx := Index mod 8;

    if GroupIdx >= FGroupCount then Exit;

    Result.Left := LeftOffset + GroupIdx * (GroupSize + FGroupGap) + LocalIdx * Step;
    Result.Right := Result.Left + LEDSize;

    // Центрирование по вертикали
    if (FLabelsPos = lpTop) then
    begin
      Result.Top := ClientHeight - LEDSize - 4;
      Result.Bottom := ClientHeight - 4;
    end
    else if (FLabelsPos = lpBottom) then
    begin
      Result.Top := 36;
      Result.Bottom := Result.Top + LEDSize;
    end
    else
    begin
      Result.Top := (ClientHeight - LEDSize) div 2;
      Result.Bottom := Result.Top + LEDSize;
    end;
  end;
end;

function TPortExpanderLED.HitTest(X, Y: Integer): Integer;
var
  i: Integer;
  R: TRect;
  P: TPoint;
begin
  Result := -1;
  for i := 0 to FBitCount - 1 do
  begin
    R := GetLEDRect(i);
    P := Point(X,Y);
    if PtInRect(R,P) then
    begin
      Result := i;
      Exit;
    end;
  end;
end;

procedure TPortExpanderLED.DoClick(Index: Integer);
var
  ColorVal: TAnalogColorItem;
begin
  if Index < 0 then Exit;

  if FMode = emDigital then
  begin
    // Переключаем бит
    if FValues[index] = 0 then FValues[index] := 1 else FValues[index] := 0;

    // Событие Click с параметрами можно реализовать через отдельное событие
    // Но стандартный OnClick не имеет параметров.
    // Пользователь может прочитать Value и HoverIndex
  end
  else
  begin
    // Analog mode: устанавливаем активное значение
    if (FActiveColorIndex >= 0) and (FActiveColorIndex < FAnalogColors.Count) then
    begin
      ColorVal := FAnalogColors[FActiveColorIndex];
      FValues[Index] := ColorVal.Threshold; // Устанавливаем пороговое значение активного цвета
      // Или можно установить само значение, которое дает этот цвет?
      // Пусть будет порог, как наиболее логичное "включение" уровня.
    end;
  end;

  Invalidate;
  if Assigned(OnClick) then OnClick(Self);
end;

procedure TPortExpanderLED.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Index: Integer;
begin
  inherited;
  if Button = mbLeft then
  begin
    Index := HitTest(X, Y);
    if Index <> -1 then
    begin
      FHoverIndex := Index;
      DoClick(Index);
    end;
  end;
end;

procedure TPortExpanderLED.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Index: Integer;
begin
  inherited;
  Index := HitTest(X, Y);
  if Index <> FHoverIndex then
  begin
    FHoverIndex := Index;
    if Index = -1 then
      Cursor := crDefault
    else
      Cursor := crHandPoint;
    Invalidate; // Для перерисовки ховер-эффекта
  end;
end;

{procedure TPortExpanderLED.MouseLeave;
begin
  inherited;
  if FHoverIndex <> -1 then
  begin
    FHoverIndex := -1;
    Cursor := crDefault;
    Invalidate;
  end;
end;}

procedure TPortExpanderLED.DrawLed(Index: Integer; const Rect: TRect; Canvas: TCanvas);//DrawLED(Canvas: TCanvas; Index: Integer; const Rect: TRect);
var
  IsActive: Boolean;
  LEDColor: TColor;
  Val: Word;
  i: Integer;
  Item: TAnalogColorItem;
  CenterX, CenterY: Integer;
  S: string;
begin
  // Определение состояния
  if FMode = emDigital then
  begin
    IsActive := (FValues[Index]) > 0;
    if IsActive then
      LEDColor := clLime // Активный цвет для Digital
    else
      LEDColor := clGray; // Неактивный
  end
  else // Analog
  begin
    Val := FValues[Index];
////////////////////////////////////////////////////////////////////    IsActive := Val > 0;
    LEDColor := clSilver; // Цвет по умолчанию (неактивный/минимальный)

    // Поиск цвета по порогам
    // Логика: находим первый порог, который больше или равен значению?
    // Или последний, который меньше?
    // Пример ТЗ: 0-1000 Red, 1000-1500 Yellow...
    // Значит, если Val <= 1000 -> Red. Если 1000 < Val <= 1500 -> Yellow.

    for i := 0 to FAnalogColors.Count - 1 do
    begin
      Item := FAnalogColors[i];
      if Val <= Item.Threshold then
      begin
        LEDColor := Item.Color;
        Break;
      end;
      // Если прошли все пороги, остается последний цвет (или дефолтный)
      if i = FAnalogColors.Count - 1 then
        LEDColor := Item.Color;
    end;

    if Val = 0 then LEDColor := clSilver; // Полностью выключен
  end;

  // Рисуем рамку группы если нужно
  if FShowGroups and (Index mod 8 = 0) and (FGroupCount > 1) then
  begin
    // Рисуется в цикле Paint, здесь только сам LED
  end;

  // Отрисовка формы
  Canvas.Brush.Color := LEDColor;
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Width := 1;

  if FLEDShape = lsCircle then
    Canvas.Ellipse(Rect)
  else
    Canvas.Rectangle(Rect);

  // Эффект наведения
  if Index = FHoverIndex then
  begin
    Canvas.Pen.Color := clWhite;
    Canvas.Pen.Width := 2;
    if FLEDShape =lsCircle then
      Canvas.Ellipse(Rect)
    else
      Canvas.Rectangle(Rect);
  end;

  // Нумерация внутри
  Canvas.Font.Color := clBlack;
  Canvas.Font.Style := [];
  Canvas.Font.Size := 8;
  S := IntToStr(Index);

  // Центрирование текста
  CenterX := (Rect.Left + Rect.Right - Canvas.TextWidth(S)) div 2;
  CenterY := (Rect.Top + Rect.Bottom - Canvas.TextHeight(S)) div 2;

  // Коррекция, чтобы текст не вылезал
  if (Rect.Right - Rect.Left > Canvas.TextWidth(S) + 4) and
     (Rect.Bottom - Rect.Top > Canvas.TextHeight(S) + 4) then
    Canvas.TextOut(CenterX, CenterY, S);
end;

procedure TPortExpanderLED.Paint;
var
  i: Integer;
  R: TRect;
//////////////////////////////////////////////  LabelRect: TRect;
  S: string;
 //////////////////////////////////////////////// OldPenColor: TColor;
begin
  inherited;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  // Рамка компонента
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Width := 1;
  Canvas.Rectangle(ClientRect);

  // Отрисовка групповых рамок
  if FShowGroups and (FGroupCount > 1) then
  begin
    // Логика рисования рамок вокруг групп по 8
    // Упрощенно: рисуем прямоугольники вокруг диапазонов
    for i := 0 to FGroupCount - 1 do
    begin
      // Получаем rects первого и последнего элемента группы
      // Это сложно сделать точно без дублирования логики GetLEDRect,
      // поэтому нарисуем просто линии разделения или рамки в цикле отрисовки LED
    end;
  end;

  // Отрисовка LED
  for i := 0 to FBitCount - 1 do
  begin
    R := GetLEDRect(i);
    if (R.Right > R.Left) and (R.Bottom > R.Top) then
    begin
      DrawLED(i, R,Canvas);

      // Рисуем рамку группы, если это первый элемент группы (кроме первой группы, если она с края)
      if FShowGroups and (i mod 8 = 0) and (FGroupCount > 1) then
      begin
        // Находим конец группы
        // Просто рисуем рамку вокруг текущей позиции + 7 элементов?
        // Лучше сделать отдельный проход или расширить GetLEDRect до GroupRect
        // Для простоты: рисуем рамку вокруг каждого 8-го, расширяя её
        // Это требует сложной геометрии, пока опустим детальные рамки групп,
        // оставив только отступы (Gap), которые уже работают в GetLEDRect
      end;
    end;
  end;

  // Если нужны явные рамки групп, можно добавить их отрисовку здесь

  // Отрисовка подписей (Адресов)
  Canvas.Font.Size := 9;
  Canvas.Font.Style := [fsBold];

  for i := 0 to FBitCount - 1 do
  begin
    R := GetLEDRect(i);
    if FOrientation = eoVertical then
    begin
      if FLabelsPos = lpLeft then
      begin
        S := IntToStr(i);
        Canvas.TextOut(4, R.Top + (R.Bottom - R.Top - Canvas.TextHeight(S)) div 2, S);
      end
      else if FLabelsPos = lpRight then
      begin
        S := 'Val: ' + IntToStr(FValues[i]);
        // Для Analog лучше показывать само значение
        Canvas.TextOut(4, R.Top + (R.Bottom - R.Top - Canvas.TextHeight(S)) div 2, IntToStr(i));
      end;
    end
    else // Horizontal
    begin
      if FLabelsPos = lpTop then
      begin
        Canvas.TextOut(R.Left + (R.Right - R.Left - Canvas.TextWidth(IntToStr(i))) div 2, 4, IntToStr(i));
      end
      else if FLabelsPos = lpBottom then
      begin
        Canvas.TextOut(R.Left + (R.Right - R.Left - Canvas.TextWidth(IntToStr(i))) div 2, ClientHeight - 20, IntToStr(i));
      end;
    end;
  end;

  // Отрисовка Значений (только для Vertical и если нужно)
  if FOrientation = eoVertical then
  begin
    Canvas.Font.Style := [];
    Canvas.Font.Size := 8;
    for i := 0 to FBitCount - 1 do
    begin
      R := GetLEDRect(i);
      if FLabelsPos = lpLeft then
      begin
        // Значение справа
        if FMode = emDigital then
          S := IntToStr((FValues[i]) and 1)
        else
          S := IntToStr(FValues[i]);

        Canvas.TextOut(ClientWidth - 30, R.Top + (R.Bottom - R.Top - Canvas.TextHeight(S)) div 2, S);
      end
      else if FLabelsPos = lpRight then
      begin
         // Значение слева (рядом с адресом? или адрес слева, значение справа?)
         // По ТЗ: "адрес с одной стороны ... значение с другой"
         if FMode = emDigital then
           S := IntToStr((FValues[i]) and 1)
         else
           S := IntToStr(FValues[i]);

         Canvas.TextOut(4, R.Top + (R.Bottom - R.Top - Canvas.TextHeight(S)) div 2, S);
         // Адрес тогда рисуем выше в блоке lpRight
      end;
    end;
  end;
end;

procedure TPortExpanderLED.Resize;
begin
  inherited;
  Invalidate;
end;

procedure Register;
begin
  RegisterComponents('Samples', [TPortExpanderLED]);
end;

end.
