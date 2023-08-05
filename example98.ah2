#include <Direct2D>
#include <Gdip_All>
#include <ctypes>
#include <wincapture>
#Include <Advapi32>
Gdip_Startup()
dx := wincapture.DXGI()

ORDINARY_NUM_WIDTH := 75
ORDINARY_NUM_HEIGHT := 126
DIGIT_WIDTH_FACTOR := ORDINARY_NUM_WIDTH / ORDINARY_NUM_HEIGHT

g_back_width := 640
g_back_height := 815

d2ui := DirectGUI('+AlwaysOnTop -DPIScale -Caption -Border +LastFound ToolWindow -Resize -HScroll +E0x08000000 -SysMenu','gui', g_back_width, g_back_height)
OnMessage(0x201, WM_LBUTTONDOWN)

;color
BACKCOLOR := D2D1_COLOR_F([0.62, 0.68, 0.53, 1.0])
FORECOLOR := D2D1_COLOR_F([0.0, 0.0, 0.0, 1.0])
GRIDCOLOR := D2D1_COLOR_F([0.54, 0.59, 0.46, 1.0])

;brush
p_back_brush := d2ui.render.CreateSolidColorBrush(D2D1_COLOR_F(rgba2float('9EAC88FF')))
p_line_brush := d2ui.render.CreateSolidColorBrush(D2D1_COLOR_F(rgba2float('000000FF')))

;font
pTextFormat := d2ui.pdwrite.CreateTextFormat('Microsoft YaHei UI', 0, 400, 0, 5, 30, 'en-us')
pTextFormat.SetTextAlignment(2)
pTextFormat.SetParagraphAlignment(2)

d2ui.show(,, g_back_width, g_back_height)
loop(100000)
{
	d2ui.render.BeginDraw()
	d2ui.render.Clear()
	d2ui.render.FillRoundedRectangle(D2D1_ROUNDED_RECT([D2D1_RECT_F([0, 0, g_back_width, g_back_height]), 10, 10]), p_back_brush)
	d2ui.render.DrawRectangle(D2D1_RECT_F([18, 18, 18+370, 18+780]), p_line_brush, 3, 0)

	d2ui.render.DrawText('得分', pTextFormat, D2D1_RECT_F([415, 43, 415+72, 43+35]), p_line_brush)
	d2ui.render.DrawText('清除行', pTextFormat, D2D1_RECT_F([415, 180, 415+110, 180+35]), p_line_brush)
	d2ui.render.DrawText('级别', pTextFormat, D2D1_RECT_F([415, 320, 415+72, 320+35]), p_line_brush)
	d2ui.render.DrawText('下一个', pTextFormat, D2D1_RECT_F([415, 466, 415+110, 466+35]), p_line_brush)

	lcd_score_rect := D2D1_RECT_F([480, 90, 280, ORDINARY_NUM_HEIGHT * 0.9])
	lcd_score := Lcd_number(d2ui.render, lcd_score_rect, 0.3, 5)

	lcd_score.draw_lcd_number(A_Index, p_line_brush, FORECOLOR, GRIDCOLOR)

	d2ui.render.EndDraw()
	d2ui.show(,, g_back_width, g_back_height)
	Sleep(200)
}


class Lcd_number
{
	__New(render_target, rect, spacing, digits, is_enable_bg_color := false) 
	{
		this.m_render_target := render_target
		this.m_digits := digits
		this.__Item := Map()
		this.m_enable_bg_color := is_enable_bg_color
		p_factor := this.m_render_target.GetFactory()
		
		width := (rect.bottom - rect.top) * DIGIT_WIDTH_FACTOR
		loop(digits)
		{
			px := rect.Left + (width + width * spacing) * (A_Index - 1)
			p_lcd := Lcd_digit(p_factor, {left : px, top : rect.top, right : px + width, bottom : rect.bottom})
			this[A_Index - 1] := p_lcd
		}
	}
	draw_lcd_number(num, brush, fr_color, bg_color)
	{
		while(num > 10 ** this.m_digits - 1)
		{
			num := Integer(Mod(num, this.m_digits))
		}

		;brush.SetColor(fr_color)
		;a := this[0]
		;b := Integer(9)
		;c := a[b]
		;this.m_render_target.FillGeometry(c, brush)
		;return

		ar := StrSplit(num)
		if(ar.Length > this.m_digits)
			return
		loop(this.m_digits - ar.Length)
			ar.InsertAt(1, 0)
		loop(this.m_digits)
		{
			if(this.m_enable_bg_color)
			{
				brush.SetColor(bg_color)
				this.m_render_target.FillGeometry(this[A_Index][0], brush)
			}
			brush.SetColor(fr_color)
			a := this[A_Index - 1]
			b := Integer(ar[A_Index])
			c := a[b]
			this.m_render_target.FillGeometry(c, brush)
		}
	}
}

class Lcd_digit
{
	__New(p_factory, rect)  ; rect : {left : , top :, right :, bottom :}
	{
		this.p_factory :=  p_factory
		this.m_rect := rect
		this.__Item := Map()
		this.geomery := Map()
		this.init_path_geometry()
		this.init_geometry_group()
	}
	__Delete() 
	{
	}
	; [x, y]
	get_absolute_point(rel_point)
	{
		px := this.m_rect.Left
		py := this.m_rect.Top
		return D2D1_POINT_2F([px + rel_point[1] / ORDINARY_NUM_WIDTH * (this.m_rect.Right - this.m_rect.Left),
								py + rel_point[2] / ORDINARY_NUM_HEIGHT * (this.m_rect.Bottom - this.m_rect.Top)])
	}
	init_path_geometry()
	{
		static line_points := 
		[
			[[3, 0], [16, 13], [58, 13], [71, 0]],
			[[0, 1], [14, 15], [14, 53], [7, 60], [6, 60], [0, 54]],
			[[74, 1], [74, 54], [68, 60], [67, 60], [60, 53], [60, 15]],
			[[15, 56], [59, 56], [65, 62], [59, 69], [15, 69], [9, 63], [9, 62]],
			[[6, 65], [7, 65], [14, 72], [14, 110], [0, 124], [0, 71]],
			[[3, 125], [16, 112], [58, 112], [71, 125]],
			[[67, 65], [68, 65], [74, 71], [74, 124], [60, 110], [60, 72]]
		]
		loop(7)
		{
			this.geomery[A_Index] := this.p_factory.CreatePathGeometry()
			p_sink := this.geomery[A_Index].Open()
			p_sink.SetFillMode(D2D1_FILL_MODE_WINDING := 1)
			p_sink.BeginFigure(this.get_absolute_point(line_points[A_Index][1]), D2D1_FIGURE_BEGIN_FILLED := 0)
			points := ctypes.array(D2D1_POINT_2F, line_points[A_Index].Length)()
			for k,v in line_points[A_Index]
			{
				points[k - 1] := this.get_absolute_point(v)
			}
			p_sink.AddLines(points, points.Length)
			p_sink.EndFigure(D2D1_FIGURE_END_CLOSED := 1)
			p_sink.Close()
			;p_sink.Release()
			p_sink := 0
		}
	}
	init_geometry_group()
	{
		static geometry_array := 
		[
			[1, 2, 3, 5, 6, 7], ;0
			[3, 7], ;1
			[1, 3, 4, 5, 6], ;2
			[1 ,3 ,4, 7, 6], ;3
			[2, 4, 3, 7], ;4
			[1, 2, 4, 7,6], ;5
			[1, 2, 5, 6, 7, 4], ;6
			[1, 3, 7], ;7
			[1, 2, 3, 4, 5, 6, 7], ;8
			[1, 2, 3, 4, 6, 7] ;9
		]

		loop(geometry_array.Length)
		{
			;指针数组
			p_array := ctypes.array('ptr', geometry_array[A_Index].Length)()
			for k,v in geometry_array[A_Index]
			{
				p_array[k - 1] := this.geomery[v].Ptr
			}
			this[A_Index - 1] := this.p_factory.CreateGeometryGroup(D2D1_FILL_MODE_WINDING := 1, p_array, geometry_array[A_Index].Length)
		}
	}
}


WM_LBUTTONDOWN(wParam, lParam, msg, hwnd)
{
	PostMessage 0xA1, 2
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
