#include <Gdip_All>
#include <Direct2D>
#include <Gdip_All>
#Include *i <wincapture>
Gdip_Startup()
g := DirectGUI()
pTextFormat := g.pdwrite.CreateTextFormat('Microsoft YaHei UI', 0, 400, 0, 5, 37.5, 'en-us')
pTextFormat.SetTextAlignment(2)
pTextFormat.SetParagraphAlignment(2)
pBrush := g.render.CreateSolidColorBrush(D2D1_COLOR_F(rgb2float('FF0000')))

is_dxgi_capture := false

if (is_dxgi_capture)
	dx := wincapture.DXGI(), ccc := dx.captureAndSave()
else
{
	pbitmp := Gdip_BitmapFromScreen()
	ccc := BitmapBuffer.loadGpBitmap(pbitmp)
}
props := D2D1_BITMAP_PROPERTIES([D2D1_PIXEL_FORMAT([87, 1]), 96, 96])
img := g.render.CreateBitmap(size := D2D1_SIZE_U([ccc.width, ccc.height]),
	ccc.ptr, ccc.pitch, props)

g.Show()

t := A_TickCount
r := 10, b := 10
loop n := 400 {
	g.render.BeginDraw()
	g.render.Clear()
	s := 'Hello World using DirectWrite      `n测试'
	if IsSet(img)
		g.render.DrawBitmap(img)
	g.render.DrawRectangle(D2D1_RECT_F([5, 5, r += 5, b += 5]), pBrush, 5, 0)
	g.render.DrawText(s, pTextFormat, D2D1_RECT_F([0, 0, 450, 300]), pBrush)
	; t := g.pdwrite.CreateTextLayout(s, pTextFormat, 500, 500), g.render.DrawTextLayout(direct2d_struct('D2D1_POINT_2F'), t, pBrush)
	g.render.EndDraw()
	g.update(0, 0, A_ScreenWidth, A_ScreenHeight)
}
MsgBox (1000 * n / (A_TickCount - t)) 'fps'
F9:: Reload
F10:: ExitApp

; x '00FF00'
rgb2float(x)
{
    x := Integer('0x' x)
    g := ((x & 0x00ff00) >> 8) / 255
    r := ((x & 0xff0000) >> 16) / 255
    b := ((x & 0xff)) / 255
    color := [r, g, b, 1]
    return color
}

class DirectGUI extends Gui {
	pd2d1 := ID2D1Factory(), pdwrite := IDWriteFactory()
	/** @type {ID2D1DCRenderTarget} */
	render := 0

	__New(Options := '', Title := A_ScriptName, maxwidth := SysGet(78), maxheight := SysGet(79)) {
		super.__New('+E0x80000 ' Options, Title || A_ScriptName)
		this.render := this.pd2d1.CreateDCRenderTarget(D2D1_RENDER_TARGET_PROPERTIES([,87,1]))
		this.render.BindDC(this.hdc := DllCall('CreateCompatibleDC', 'ptr', 0, 'ptr'),
			D2D1_RECT_U([,,maxwidth, maxheight]))
		NumPut('uint', 40, 'uint', maxwidth, 'uint', maxheight, 'ushort', 1, 'ushort', 32, 'uint', 0, BITMAPINFO := Buffer(40))
		this.hbm := DllCall('CreateDIBSection', 'ptr', this.hdc, 'ptr', BITMAPINFO, 'uint', 0, 'ptr*', &ppvBits := 0, 'ptr', 0, 'uint', 0, 'ptr')
		this.odm := DllCall('SelectObject', 'ptr', this.hdc, 'ptr', this.hbm, 'ptr')
	}
	__Delete() {
		this.render := this.pd2d1 := this.pdwrite := 0
		DllCall('SelectObject', 'ptr', this.hdc, 'ptr', this.odm, 'ptr')
		DllCall('DeleteObject', 'ptr', this.hbm)
		DllCall('DeleteDC', 'ptr', this.hdc)
	}
	show(x := SysGet(76), y := SysGet(77), w := SysGet(78), h := SysGet(79), alpha := 255, options := 'NA') {
		super.Show('w' w ' h' h ' ' options ' NoActivate')
		this.update(this.x := x ?? (SysGet(78) - w) >> 1, this.y := y ?? (SysGet(79) - h) >> 1,
			this.w := w, this.h := h, this.alpha := alpha)
	}
	only_show()
	{
		super.Show(' NoActivate')
	}
	update(x?, y?, w?, h?, alpha?) 
	{
		UpdateLayeredWindow(this.Hwnd, this.hdc, x, y, w, h)
	}
}