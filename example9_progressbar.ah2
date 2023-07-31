#include <Direct2D>
#include <Gdip_All>
#include <ctypes>
Gdip_Startup()

Gui1 := Gui("-DPIScale")
SliderObj := Gui1.Add("Slider", "x10 y10 w400 Range0-100 vPercentage Tooltip", 50)
SliderObj.OnEvent("Change", Slider_Change)
PictureObj := Gui1.Add("Picture", "x10 y+30 w500 h100 0xE vProgressBar")
Gdip_SetProgress(PictureObj, 50, 0xff0993ea, 0xffbde5ff, "50`%")
Gui1.Title := "Example 9 - d2d progress bar"
Gui1.Show("AutoSize")
Slider_Change(GuiCtrlObj, Info)
{
	Gdip_SetProgress(GuiCtrlObj.Gui["ProgressBar"], GuiCtrlObj.Value, 0xff0993ea, 0xffbde5ff, GuiCtrlObj.Value "`%")
}
Gdip_SetProgress(GuiCtrl, Percentage, Foreground, Background:=0x00000000, Text:="", TextOptions:="x0p y15p s60p Center cff000000 r4 Bold", Font:="Arial")
{
	static d2ui := DirectGUI('+AlwaysOnTop -DPIScale -Caption -Border +LastFound ToolWindow -Resize -HScroll +E0x08000000 -SysMenu','gui', 500, 100)
	static p_brush := d2ui.render.CreateSolidColorBrush(D2D1_COLOR_F(rgb2float('FF0000')))
	static pBrush_back := d2ui.render.CreateSolidColorBrush(D2D1_COLOR_F(rgba2float('00FF00CC')))
	static pBrush_front := d2ui.render.CreateSolidColorBrush(D2D1_COLOR_F(rgba2float('00FF00FF')))
	GuiCtrl.GetPos(&X, &Y, &Posw, &Posh)
	hwnd := GuiCtrl.Hwnd

	static pTextFormat := d2ui.pdwrite.CreateTextFormat('Microsoft YaHei UI', 0, 400, 0, 5, 37.5, 'en-us')
	pTextFormat.SetTextAlignment(2)
	pTextFormat.SetParagraphAlignment(2)

	d2ui.show()
	d2ui.render.BeginDraw()
	d2ui.render.Clear()

	d2ui.render.FillRoundedRectangle(D2D1_ROUNDED_RECT([D2D1_RECT_F([0, 0, Posw, Posh]), 2, 2]), pBrush_back)
	d2ui.render.FillRoundedRectangle(D2D1_ROUNDED_RECT([D2D1_RECT_F([0, 10, Posw * Percentage/100, Posh - 10]), 10, 10]), pBrush_front)

	d2ui.render.DrawText(Percentage '%', pTextFormat, D2D1_RECT_F([Posw / 2, 0, 100, 100]), p_brush)
	d2ui.render.EndDraw()
	d2ui.update(0, 0, 500, 100)

	chdc := CreateCompatibleDC()
	hbm := CreateDIBSection(500, 100, chdc)
	obm := SelectObject(chdc, hbm)
	sdc := d2ui.hdc
	BitBlt(chdc, 0, 0, 500, 100, sdc, 0, 0)
	SelectObject(chdc, obm)
	SetImage(PictureObj.Hwnd, hbm)
	DeleteObject(hbm)
	DeleteDC(chdc)
}

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
    g := ((x & 0x00ff0000) >> 8) / 255
    r := ((x & 0xff000000) >> 16) / 255
    b := ((x & 0xff00)) / 255
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
