#include <Direct2D>
#include <Gdip_All>
#include <ctypes>
;Gdip_Startup()

d2ui := DirectGUI('+AlwaysOnTop -DPIScale -Caption -Border +LastFound ToolWindow -Resize -HScroll +E0x08000000 -SysMenu','gui')
d2ui.show()
d2ui.render.BeginDraw()
d2ui.render.Clear()

p_brush := d2ui.render.CreateSolidColorBrush(D2D1_COLOR_F(rgb2float('FF0000')))
p_brush1 := d2ui.render.CreateSolidColorBrush(D2D1_COLOR_F(rgba2float('00FF00CC')))
d2ui.render.FillEllipse(D2D1_ELLIPSE([D2D1_POINT_2F([100, 100]), 100, 50]), p_brush)
d2ui.render.FillRoundedRectangle(D2D1_ROUNDED_RECT([D2D1_RECT_F([100, 600, 400, 800]), 10, 10]) ,p_brush1)

d2ui.render.EndDraw()
d2ui.show()

rgb2float(x)
{
    x := Integer('0x' x)
    g := ((x & 0x00ff00) >> 8) / 255
    r := ((x & 0xff0000) >> 16) / 255
    b := ((x & 0xff)) / 255
    color := [r, g, b, 1]
    return color
}
rgba2float(x)
{
    x := Integer('0x' x)
    g := ((x & 0x00ff0000) >> 16) / 255
    r := ((x & 0xff000000) >> 24) / 255
    b := ((x & 0xff00) >> 8) / 255
    a := ((x & 0xff)) / 255
    color := [r, g, b, a]
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
