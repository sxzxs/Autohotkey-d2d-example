#include <Direct2D>
#include <Gdip_All>
#include <ctypes>
#include <wincapture>
Gdip_Startup()
dx := wincapture.DXGI()

d2ui := DirectGUI('+AlwaysOnTop -DPIScale -Caption -Border +LastFound ToolWindow -Resize -HScroll +E0x08000000 -SysMenu','gui')

SetTimer(draw_circle, 200)


draw_circle()
{

    d2ui.show()
    d2ui.render.BeginDraw()
	d2ui.render.Clear()

    ;solid brush
    v := Format("{:X}", Random(0, 0xffffffff))
    v1 := Format("{:X}", 0xff0000ff)
    p_brush := d2ui.render.CreateSolidColorBrush(D2D1_COLOR_F(rgba2float('0000ffcc')))
    d2ui.render.FillEllipse(D2D1_ELLIPSE([D2D1_POINT_2F([100, 100]), 100, 50]), p_brush)

    D2D1_GRADIENT_STOPS := ctypes.array('D2D1_GRADIENT_STOP', 2)
    stops := D2D1_GRADIENT_STOPS()
    stops[0] := D2D1_GRADIENT_STOP([0, D2D1_COLOR_F(rgba2float('ff0000ff'))])
    stops[1] := D2D1_GRADIENT_STOP([1, D2D1_COLOR_F(rgba2float('0000ffff'))])

    stop_collection := d2ui.render.CreateGradientStopCollection(stops, 2, 0, 0)

    ;linear gradient brush
	;线性渐变画刷
    linear_gradient_brush_propertyies := D2D1_LINEAR_GRADIENT_BRUSH_PROPERTIES([D2D1_POINT_2F([500, 500]), D2D1_POINT_2F([600, 550])])
    p_linear_brush := d2ui.render.CreateLinearGradientBrush(linear_gradient_brush_propertyies, 0, stop_collection)
	;p_linear_brush.SetStartPoint(D2D1_POINT_2F([0, 0]))
	;p_linear_brush.SetEndPoint(D2D1_POINT_2F([500, 500]))

    d2ui.render.FillEllipse(D2D1_ELLIPSE([D2D1_POINT_2F([500, 500]), 100, 50]), p_linear_brush)

	;径向渐变
	radialGradientBrushProperties := D2D1_RADIAL_GRADIENT_BRUSH_PROPERTIES([D2D1_POINT_2F([800, 800]), D2D1_POINT_2F([0, 0]), 75, 50])
	p_radia_gradient_brush := d2ui.render.CreateRadialGradientBrush(radialGradientBrushProperties, 0, stop_collection)
	d2ui.render.FillEllipse(D2D1_ELLIPSE([D2D1_POINT_2F([600, 600]), 100, 50]), p_radia_gradient_brush)

	;位图画刷
	;大小不清楚规则
	;ccc := BitmapBuffer.loadPicture(A_ScriptDir '\MJ.jpg') ;好像不支持jpg
	pbitmp := Gdip_CreateBitmapFromFile(A_ScriptDir '\MJ.jpg')
	ccc := BitmapBuffer.loadGpBitmap(pbitmp)
	props := D2D1_BITMAP_PROPERTIES([D2D1_PIXEL_FORMAT([87, 1]), 96 * 2, 96 * 2])
	img := d2ui.render.CreateBitmap(size := D2D1_SIZE_U([ccc.width, ccc.height]),
		ccc.ptr, ccc.pitch, props)
	p_bitmap_brush := d2ui.render.CreateBitmapBrush(img)
	p_bitmap_brush.SetExtendModeX(D2D1_EXTEND_MODE_MIRROR := 2)
	p_bitmap_brush.SetExtendModeY(D2D1_EXTEND_MODE_MIRROR := 2)
	;d2ui.render.FillEllipse(D2D1_ELLIPSE([D2D1_POINT_2F([900, 800]), 500, 200]), p_bitmap_brush)
	d2ui.render.FillRoundedRectangle(D2D1_ROUNDED_RECT([D2D1_RECT_F([700, 600, 900, 800]), 10, 10]) ,p_bitmap_brush)

	;变形画刷
	;平移矩阵
	;| 1   0 |
	;| 0   1 |
	;| dx  dy|
	p_bitmap_brush.SetTransform(D2D1_MATRIX_3X2_F([1, 0, 0, 1, 300, 300]))
	d2ui.render.FillRoundedRectangle(D2D1_ROUNDED_RECT([D2D1_RECT_F([1000, 800, 1200, 1000]), 10, 10]) ,p_bitmap_brush)
    d2ui.render.EndDraw()
    d2ui.show()
}


;local func and class
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
