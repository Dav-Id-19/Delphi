unit PortExpanderLED;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs;

type
  TLEDShape = (lsCircle, lsSquare);
  TOrientation = (orVertical, orHorizontal);
  THorizontalNumbering = (hnTop, hnBottom, hnBoth);
  TDisplayMode = (dmDigital, dmAnalog);

  TPortExpanderLED = class(TCustomControl)
  private
    FLEDCount: Integer;
    FLEDShape: TLEDShape;
    FOrientation: TOrientation;
    FHorizontalNumbering: THorizontalNumbering;
    FDisplayMode: TDisplayMode;
    FValues: array[0..31] of Word;
    FActiveColors: array[0..31] of TColor;
    FInactiveColor: TColor;
    FDigitalColorOff: TColor;
    FDigitalColorOn: TColor;
    FAnalogBaseColor: TColor;
    FMirrorVertical: Boolean;
    FSelectedLED: Integer;
    FOnChange: TNotifyEvent;
    FOnClickLED: TNotifyEvent;
    procedure SetLEDCount(Value: Integer);
    procedure SetLEDShape(Value: TLEDShape);
    procedure SetOrientation(Value: TOrientation);
    procedure SetHorizontalNumbering(Value: THorizontalNumbering);
    procedure SetDisplayMode(Value: TDisplayMode);
    procedure SetMirrorVertical(Value: Boolean);
    procedure SetValue(Index: Integer; Value: Word);
    function GetValue(Index: Integer): Word;
    procedure SetActiveColor(Index: Integer; Value: TColor);
    function GetActiveColor(Index: Integer): TColor;
    procedure DrawLED(Canvas: TCanvas; Index: Integer; Rect: TRect);
    procedure DrawNumbering(Canvas: TCanvas);
    function GetLEDRect(Index: Integer): TRect;
    function HitTest(X, Y: Integer): Integer;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetAllValues(const AValues: array of Word);
    procedure Clear;
    property Values[Index: Integer]: Word read GetValue write SetValue; default;
    property ActiveColors[Index: Integer]: TColor read GetActiveColor write SetActiveColor;
  published
    property Align;
    property Anchors;
    property LEDCount: Integer read FLEDCount write SetLEDCount default 8;
    property LEDShape: TLEDShape read FLEDShape write SetLEDShape default lsCircle;
    property Orientation: TOrientation read FOrientation write SetOrientation default orVertical;
    property HorizontalNumbering: THorizontalNumbering read FHorizontalNumbering write SetHorizontalNumbering default hnTop;
    property DisplayMode: TDisplayMode read FDisplayMode write SetDisplayMode default dmDigital;
    property MirrorVertical: Boolean read FMirrorVertical write SetMirrorVertical default False;
    property InactiveColor: TColor read FInactiveColor write FInactiveColor default clGray;
    property DigitalColorOff: TColor read FDigitalColorOff write FDigitalColorOff default clBlack;
    property DigitalColorOn: TColor read FDigitalColorOn write FDigitalColorOn default clLime;
    property AnalogBaseColor: TColor read FAnalogBaseColor write FAnalogBaseColor default clYellow;
    property SelectedLED: Integer read FSelectedLED write FSelectedLED default -1;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnClickLED: TNotifyEvent read FOnClickLED write FOnClickLED;
    property Color default clWhite;
    property Enabled;
    property Font;
    property ParentColor default False;
    property ParentFont default True;
    property Visible;
  end;

procedure Register;

implementation

constructor TPortExpanderLED.Create(AOwner: TComponent);
var
  I: Integer;
begin
  inherited Create(AOwner);
  Width := 120;
  Height := 200;
  FLEDCount := 8;
  FLEDShape := lsCircle;
  FOrientation := orVertical;
  FHorizontalNumbering := hnTop;
  FDisplayMode := dmDigital;
  FInactiveColor := clGray;
  FDigitalColorOff := clBlack;
  FDigitalColorOn := clLime;
  FAnalogBaseColor := clYellow;
  FMirrorVertical := False;
  FSelectedLED := -1;
  Color := clWhite;
  ParentColor := False;
  ParentFont := True;
  
  for I := 0 to 31 do
  begin
    FValues[I] := 0;
    FActiveColors[I] := clRed;
  end;
end;

procedure TPortExpanderLED.CreateWnd;
begin
  inherited CreateWnd;
  Invalidate;
end;

procedure TPortExpanderLED.SetLEDCount(Value: Integer);
begin
  if Value < 8 then Value := 8;
  if Value > 32 then Value := 32;
  // Округляем до кратного 8
  Value := (Value div 8) * 8;
  if Value = 0 then Value := 8;
  
  if FLEDCount <> Value then
  begin
    FLEDCount := Value;
    if FSelectedLED >= FLEDCount then
      FSelectedLED := -1;
    Invalidate;
  end;
end;

procedure TPortExpanderLED.SetLEDShape(Value: TLEDShape);
begin
  if FLEDShape <> Value then
  begin
    FLEDShape := Value;
    Invalidate;
  end;
end;

procedure TPortExpanderLED.SetOrientation(Value: TOrientation);
begin
  if FOrientation <> Value then
  begin
    FOrientation := Value;
    // Меняем размеры при смене ориентации
    if FOrientation = orHorizontal then
    begin
      Width := 200;
      Height := 120;
    end
    else
    begin
      Width := 120;
      Height := 200;
    end;
    Invalidate;
  end;
end;

procedure TPortExpanderLED.SetHorizontalNumbering(Value: THorizontalNumbering);
begin
  if FHorizontalNumbering <> Value then
  begin
    FHorizontalNumbering := Value;
    Invalidate;
  end;
end;

procedure TPortExpanderLED.SetDisplayMode(Value: TDisplayMode);
begin
  if FDisplayMode <> Value then
  begin
    FDisplayMode := Value;
    Invalidate;
  end;
end;

procedure TPortExpanderLED.SetMirrorVertical(Value: Boolean);
begin
  if FMirrorVertical <> Value then
  begin
    FMirrorVertical := Value;
    Invalidate;
  end;
end;

function TPortExpanderLED.GetValue(Index: Integer): Word;
begin
  if (Index >= 0) and (Index < FLEDCount) then
    Result := FValues[Index]
  else
    Result := 0;
end;

procedure TPortExpanderLED.SetValue(Index: Integer; Value: Word);
begin
  if (Index >= 0) and (Index < FLEDCount) then
  begin
    // Word уже имеет диапазон 0-65535, дополнительная проверка не нужна
    if FValues[Index] <> Value then
    begin
      FValues[Index] := Value;
      Invalidate;
      if Assigned(FOnChange) then
        FOnChange(Self);
    end;
  end;
end;

function TPortExpanderLED.GetActiveColor(Index: Integer): TColor;
begin
  if (Index >= 0) and (Index < FLEDCount) then
    Result := FActiveColors[Index]
  else
    Result := clRed;
end;

procedure TPortExpanderLED.SetActiveColor(Index: Integer; Value: TColor);
begin
  if (Index >= 0) and (Index < FLEDCount) then
  begin
    if FActiveColors[Index] <> Value then
    begin
      FActiveColors[Index] := Value;
      Invalidate;
    end;
  end;
end;

procedure TPortExpanderLED.SetAllValues(const AValues: array of Word);
var
  I, Count: Integer;
begin
  if High(AValues) < FLEDCount - 1 then
    Count := High(AValues) + 1
  else
    Count := FLEDCount;
    
  for I := 0 to Count - 1 do
    FValues[I] := AValues[I];
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPortExpanderLED.Clear;
var
  I: Integer;
begin
  for I := 0 to FLEDCount - 1 do
    FValues[I] := 0;
  FSelectedLED := -1;
  Invalidate;
end;

function TPortExpanderLED.GetLEDRect(Index: Integer): TRect;
var
  Margin, Spacing, LEDSize: Integer;
  Row, Col: Integer;
  TotalRows, TotalCols: Integer;
  StartY, StartX: Integer;
begin
  Margin := 4;
  Spacing := 2;
  LEDSize := 16;
  
  if FOrientation = orVertical then
  begin
    TotalCols := 1;
    TotalRows := FLEDCount;
    Col := 0;
    if FMirrorVertical then
      Row := FLEDCount - 1 - Index
    else
      Row := Index;
    
    StartX := (Width - LEDSize) div 2;
    StartY := Margin + 15; // Место для нумерации сверху
    
    Result.Left := StartX;
    Result.Top := StartY + Row * (LEDSize + Spacing);
    Result.Right := Result.Left + LEDSize;
    Result.Bottom := Result.Top + LEDSize;
  end
  else
  begin
    TotalCols := FLEDCount;
    TotalRows := 1;
    Col := Index;
    Row := 0;
    
    StartY := (Height - LEDSize) div 2;
    StartX := Margin + 20; // Место для нумерации слева
    
    Result.Left := StartX + Col * (LEDSize + Spacing);
    Result.Top := StartY;
    Result.Right := Result.Left + LEDSize;
    Result.Bottom := Result.Top + LEDSize;
  end;
end;

function TPortExpanderLED.HitTest(X, Y: Integer): Integer;
var
  I: Integer;
  Rect: TRect;
begin
  Result := -1;
  for I := 0 to FLEDCount - 1 do
  begin
    Rect := GetLEDRect(I);
    if PtInRect(Rect, X, Y) then
    begin
      Result := I;
      Exit;
    end;
  end;
end;

procedure TPortExpanderLED.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LEDIndex: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  
  if Button = mbLeft then
  begin
    LEDIndex := HitTest(X, Y);
    if LEDIndex >= 0 then
    begin
      FSelectedLED := LEDIndex;
      Invalidate;
      
      if Assigned(FOnClickLED) then
        FOnClickLED(Self);
    end;
  end;
end;

procedure TPortExpanderLED.DrawLED(Canvas: TCanvas; Index: Integer; Rect: TRect);
var
  BrushColor: TColor;
  OldBrushStyle: TBrushStyle;
  CenterX, CenterY, Radius: Integer;
begin
  if FDisplayMode = dmDigital then
  begin
    // Цифровой режим: два цвета
    if FValues[Index] > 0 then
      BrushColor := FDigitalColorOn
    else
      BrushColor := FDigitalColorOff;
  end
  else
  begin
    // Аналоговый режим
    if FValues[Index] = 0 then
      BrushColor := FInactiveColor
    else
      BrushColor := FActiveColors[Index];
  end;
  
  OldBrushStyle := Canvas.Brush.Style;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := BrushColor;
  Canvas.Pen.Color := clGray;
  Canvas.Pen.Width := 1;
  
  if FLEDShape = lsCircle then
  begin
    CenterX := (Rect.Left + Rect.Right) div 2;
    CenterY := (Rect.Top + Rect.Bottom) div 2;
    Radius := (Rect.Right - Rect.Left) div 2;
    Canvas.Ellipse(CenterX - Radius, CenterY - Radius, CenterX + Radius, CenterY + Radius);
  end
  else
  begin
    Canvas.Rectangle(Rect);
  end;
  
  // Рисуем рамку выделения для выбранного LED
  if Index = FSelectedLED then
  begin
    Canvas.Pen.Color := clBlue;
    Canvas.Pen.Width := 2;
    Canvas.Brush.Style := bsClear;
    if FLEDShape = lsCircle then
      Canvas.Ellipse(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom)
    else
      Canvas.Rectangle(Rect);
  end;
  
  Canvas.Brush.Style := OldBrushStyle;
end;

procedure TPortExpanderLED.DrawNumbering(Canvas: TCanvas);
var
  I: Integer;
  Rect: TRect;
  NumText: string;
  TextRect: TRect;
  CenterX, CenterY: Integer;
begin
  Canvas.Font.Name := 'Tahoma';
  Canvas.Font.Size := 8;
  Canvas.Font.Color := clBlack;
  Canvas.Brush.Style := bsClear;
  
  if FOrientation = orVertical then
  begin
    // Вертикальная ориентация - номера слева
    for I := 0 to FLEDCount - 1 do
    begin
      Rect := GetLEDRect(I);
      CenterY := (Rect.Top + Rect.Bottom) div 2;
      NumText := IntToStr(I);
      
      // Рисуем номер слева от LED
      TextRect := Rect;
      TextRect.Right := Rect.Left - 2;
      TextRect.Left := 2;
      Canvas.TextOut(TextRect.Right, CenterY - 6, NumText);
    end;
  end
  else
  begin
    // Горизонтальная ориентация
    for I := 0 to FLEDCount - 1 do
    begin
      Rect := GetLEDRect(I);
      CenterX := (Rect.Left + Rect.Right) div 2;
      NumText := IntToStr(I);
      
      // Рисуем номер сверху
      if (FHorizontalNumbering = hnTop) or (FHorizontalNumbering = hnBoth) then
      begin
        TextRect := Rect;
        TextRect.Bottom := Rect.Top - 2;
        TextRect.Top := 2;
        Canvas.TextOut(CenterX - 6, TextRect.Top, NumText);
      end;
      
      // Рисуем номер снизу
      if (FHorizontalNumbering = hnBottom) or (FHorizontalNumbering = hnBoth) then
      begin
        TextRect := Rect;
        TextRect.Top := Rect.Bottom + 2;
        TextRect.Bottom := Height - 2;
        Canvas.TextOut(CenterX - 6, TextRect.Top, NumText);
      end;
    end;
  end;
end;

procedure TPortExpanderLED.Paint;
var
  I: Integer;
  Rect: TRect;
begin
  inherited Paint;
  
  // Очищаем фон
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
  
  // Рисуем все LED
  for I := 0 to FLEDCount - 1 do
  begin
    Rect := GetLEDRect(I);
    DrawLED(Canvas, I, Rect);
  end;
  
  // Рисуем нумерацию
  DrawNumbering(Canvas);
end;

procedure Register;
begin
  RegisterComponents('Samples', [TPortExpanderLED]);
end;

end.
