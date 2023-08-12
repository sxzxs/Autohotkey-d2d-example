#include <Direct2D>
#include <Gdip_All>
#include <ctypes>
#include <wincapture>

KEY_LEFT := GetKeyVK('h')
KEY_DOWN := GetKeyVK('j')
KEY_RIGHT := GetKeyVK('l')
KEY_UP := GetKeyVK('k')

ROW_NUM := 20
COL_NUM := 10
MINIMUM_HEIGHT := 284.0
MINIMUM_WIDTH := 223.0
MARGIN :=  11.0
BACKCOLOR := D2D1_COLOR_F([0.62,0.68,0.53,1.0])
FORECOLOR := D2D1_COLOR_F([0.0,0.0,0.0,1.0])
GRIDCOLOR := D2D1_COLOR_F([0.54,0.59,0.46,1.0])
FOODCOLOR := D2D1_COLOR_F([1,0,0,1.0])
FIGURE_INFO_NUM := 7
FIGURE_NUM := 4

MAXIMUM_DIGITS := 8
ORDINARY_NUM_WIDTH := 75
ORDINARY_NUM_HEIGHT := 126
DIGIT_WIDTH_FACTOR := ORDINARY_NUM_WIDTH / ORDINARY_NUM_HEIGHT

main()
main()
{
    Gdip_Startup()
    dx := wincapture.DXGI()
    global ui := Gui('+AlwaysOnTop -DPIScale +Caption  +Border +LastFound -ToolWindow +Resize -HScroll  +SysMenu','上k下j左h右l')
    ui.show('x0 y0 w500 h600')
	global pView := View()
    pView.Initial(ui)
    pView.InitialRectLCD()
	global pGame := Game(pView)
    pGame.UpdateView()

    SubclassControl(ui.Hwnd, win_process)
    SetTimer(timer_handle.bind(ui), 600 - pGame.GetLevel() * 1)
}

timer_handle(ui)
{
    PostMessage(WM_TIMER := 0x113, ,,, ui.Hwnd)
    ;更新定时器时间
    SetTimer , 600 - pGame.GetLevel() * 1 
    if(pGame.GameOver())
    {
        rtn := MsgBox('GAME over! restart?',,'YesNo')
        if(rtn = "Yes")
            Reload
        else
            ExitApp
    }
}

class Game
{
    __New(pView) 
    {
        this.m_pView :=  pView
        this.m_Grid := []
        loop ROW_NUM
        {
            r := A_Index
            this.m_Grid.Push([])
            loop COL_NUM
            {
                c := A_Index
                this.m_Grid[r].Push(0)
            }   
        }
        this.m_iLevel := 1
        this.m_iLines := 0
        this.m_iScore := 0
        this.m_isOver := false
        this.sn := Snake()
        this.food := food()
    }
    __Delete() 
    {
        
    }
    SetView(pView)
    {
        this.m_pView := pView
    }
    UpdateView()
    {
        if(this.m_isOver)
            return
        this.m_pView.BeginDraw()
        this.m_pView.DrawBackground()
        this.m_pView.DrawBorder()
        this.m_pView.DrawGrid(this.m_Grid)
        this.m_pView.draw_food(this.food)
        this.m_pView.draw_snake(this.sn)
        this.m_pView.DrawStaticText()
        this.m_pView.DrawScore(this.m_iLevel * 10)
        this.m_pView.DrawLevel(this.m_iLevel)
        this.m_pView.EndDraw()
    }
    GetLevel()
    {
        return this.m_iLevel
    }
    set_position(direnct := [1, 0])
    {
        current_direct := this.sn.direct
        if(current_direct[1] != -direnct[1] && current_direct[2] != -direnct[2])
        {
            this.sn.direct[1] := direnct[1]
            this.sn.direct[2] := direnct[2]
        }
    }
	Timer()
    {	
        this.move()
    }
    move()
    {
        if(this.sn.move(this.food.position))
        {
            ;产生新的food位置
            loop(1000)
            {
                x := Random(1, COL_NUM)
                y := Random(1, ROW_NUM)
                for k,v in this.sn.position
                {
                    if(x != v[1] &7 y != v[2])
                        break
                }
                this.food.set_position(x, y)
            }
        }
        if(this.sn.is_out_position())
            this.m_isOver := true
        this.m_iLevel := this.sn.position.length
    }
	GameOver()
    {	
        return this.m_isOver
    }
}
class food
{
    __New() 
    {
        this.position := [1, 1]

    }
    set_position(x, y)
    {
        this.position := [x, y]
    }
}

class Snake
{
    __New() 
    {
        this.length := 2
        ;x y
        this.position := [[2, 5], [1, 5]]
        this.direct := [1, 0]
    }
    move(food_position)
    {
        ;记录尾部的位置
        last_position := this.position[this.position.length].Clone()
        p := this.position.length
        loop this.position.length - 1
        {
            this.position[p] := this.position[p - 1].Clone()
            p--
        }
        this.position[1][1] := this.position[1][1] + this.direct[1]
        this.position[1][2] := this.position[1][2] + this.direct[2]

        if(this.position[1][1] == food_position[1] && this.position[1][2] == food_position[2])
        {
            this.position.Push(last_position)
            return true
        }
        return false
    }
    is_out_position()
    {
        if(this.position[1][1] > COL_NUM || this.position[1][2] > ROW_NUM)
            return true
        if(this.position[1][1] < 1 || this.position[1][2] < 1)
            return true
        return false
    }
}

class View
{
    __New() 
    {
        this.m_pFactory := ID2D1Factory()
        this.m_pRenderTarget := 0
        this.m_pBrush := 0
        this.m_pWriteFactory := 0
        this.m_pTextFormat := 0

        m_rectTetris := D2D1_RECT_F([])
        m_rectGrid := D2D1_RECT_F([])
        m_rectStatus := D2D1_RECT_F([])

        m_rectScoreText := D2D1_RECT_F([])
        m_rectScoreLCD := D2D1_RECT_F([])
        m_rectRemoveLineText := D2D1_RECT_F([])
        m_rectRemoveLineLCD := D2D1_RECT_F([])
        m_rectLevelText := D2D1_RECT_F([])
        m_rectLevelLCD := D2D1_RECT_F([])
        m_rectNextText := D2D1_RECT_F([])
    }
    Initial(ui)
    {
	    this.m_pFactory := ID2D1Factory(), this.m_pWriteFactory := IDWriteFactory()
        ui.GetClientPos(&x, &y, &w, &h)
        hwnd_render_target_property := D2D1_HWND_RENDER_TARGET_PROPERTIES([ui.Hwnd, w, h, D2D1_PRESENT_OPTIONS_NONE := 0])
        this.m_pRenderTarget := this.m_pFactory.CreateHwndRenderTarget(D2D1_RENDER_TARGET_PROPERTIES([]), hwnd_render_target_property)
        this.m_pBrush := this.m_pRenderTarget.CreateSolidColorBrush(BACKCOLOR)
    }
    SetTextFormat(size)
    {
        this.m_pTextFormat := this.m_pWriteFactory.CreateTextFormat('Microsoft YaHei UI', 0, 
                                                                        DWRITE_FONT_WEIGHT_LIGHT := 300, 
                                                                        DWRITE_FONT_STYLE_NORMAL := 0, 
                                                                        DWRITE_FONT_STRETCH_NORMAL := 5, size, '')

    }
    InitialRectLCD()
    {
        this.CaculateLayout()
        this.InitLCD()
    }
    draw_snake(sn)
    {
        for k,v in sn.position
        {
            i := v[2] ;colum x
            j := v[1] ;row y
            this.m_pBrush.SetColor(FORECOLOR)

            left := this.m_rectGrid.left + (this.m_fMargin_x + this.m_fCell_x) * (j - 1) + this.m_fMargin_x
            top := this.m_rectGrid.top + (this.m_fMargin_y + this.m_fCell_y) * (i - 1) + this.m_fMargin_y
            right := left + this.m_fCell_x
            bottom := top + this.m_fCell_y

            this.m_pRenderTarget.DrawRectangle(D2D1_RECT_F([left + this.m_fMargin_x * 0.5,
                                                            top + this.m_fMargin_y * 0.5,
                                                            right - this.m_fMargin_x * 0.5,
                                                            bottom - this.m_fMargin_y * 0.5]), 
                                                this.m_pBrush, 2.0, 0)
            this.m_pRenderTarget.FillRectangle(D2D1_RECT_F([left + this.m_fMargin_x * 1.9,
                                                            top + this.m_fMargin_y * 1.9,
                                                            right - this.m_fMargin_x * 1.9,
                                                            bottom - this.m_fMargin_y * 1.9]), 
                                                this.m_pBrush)
        }
    }
    draw_food(fd)
    {
        i := fd.position[2]
        j := fd.position[1]

        this.m_pBrush.SetColor(FOODCOLOR)
        left := this.m_rectGrid.left + (this.m_fMargin_x + this.m_fCell_x) * (j - 1) + this.m_fMargin_x
        top := this.m_rectGrid.top + (this.m_fMargin_y + this.m_fCell_y) * (i - 1) + this.m_fMargin_y
        right := left + this.m_fCell_x
        bottom := top + this.m_fCell_y

        this.m_pRenderTarget.DrawRectangle(D2D1_RECT_F([left + this.m_fMargin_x * 0.5,
                                                        top + this.m_fMargin_y * 0.5,
                                                        right - this.m_fMargin_x * 0.5,
                                                        bottom - this.m_fMargin_y * 0.5]), 
                                            this.m_pBrush, 2.0, 0)
        this.m_pRenderTarget.FillRectangle(D2D1_RECT_F([left + this.m_fMargin_x * 1.9,
                                                        top + this.m_fMargin_y * 1.9,
                                                        right - this.m_fMargin_x * 1.9,
                                                        bottom - this.m_fMargin_y * 1.9]), 
                                            this.m_pBrush)

    }
	InitLCD()
    {
        this.m_pLcdScore := LCDNumber(this.m_pRenderTarget, this.m_rectScoreLCD, 0.3, 5, true)
        this.m_pLcdRemoveLine := LCDNumber(this.m_pRenderTarget, this.m_rectRemoveLineLCD, 0.3, 5, true)
        this.m_pLcdLevel := LCDNumber(this.m_pRenderTarget, this.m_rectLevelLCD, 0.3, 1, true)
    }
	BeginDraw()
    {
        this.m_pRenderTarget.BeginDraw()
    }
	EndDraw()
    {
        this.m_pRenderTarget.EndDraw()
    }
	Resize(width, height)
    {
        this.m_pRenderTarget.Resize(D2D1_SIZE_U([width, height]))
        this.CaculateLayout()
        this.InitLCD()
    }
	CaculateLayout()
    {
        size := this.m_pRenderTarget.GetSize()
        width := size.width
        height := size.height
        if ((size.width / size.height) > (MINIMUM_WIDTH / MINIMUM_HEIGHT))
        {
            width := size.height * MINIMUM_WIDTH / MINIMUM_HEIGHT
        }
        else
        {
            height := width * MINIMUM_HEIGHT / MINIMUM_WIDTH
        }

        left := (size.width - width) / 2
        top := (size.height - height) / 2
        this.m_rectTetris := D2D1_RECT_F([left, top, left + width, top + height])
        
        m_rectTetris_with := GetRectWidth(this.m_rectTetris)
        this.m_rectGrid := D2D1_RECT_F([this.m_rectTetris.left + m_rectTetris_with * 0.03,
                                        this.m_rectTetris.top + m_rectTetris_with * 0.03,
                                        this.m_rectTetris.left + m_rectTetris_with * 0.6,
                                        this.m_rectTetris.bottom - m_rectTetris_with * 0.03])

        this.m_fMargin_x := (this.m_rectGrid.right - this.m_rectGrid.left) / (10 * COL_NUM + 1)
        this.m_fMargin_y := (this.m_rectGrid.bottom - this.m_rectGrid.top) / (10 * ROW_NUM + 1)

        this.m_fCell_x := this.m_fMargin_x * 9
        this.m_fCell_y := this.m_fMargin_y * 9

        this.m_rectStatus := D2D1_RECT_F([this.m_rectTetris.left + m_rectTetris_with * 0.6,
                                    this.m_rectTetris.top + 5 * this.m_fMargin_y,
                                    this.m_rectTetris.right - 5 * this.m_fMargin_x,
                                    this.m_rectTetris.bottom - 5 * this.m_fMargin_y])

        this.m_rectScoreText := D2D1_RECT_F([this.m_rectStatus.left + this.m_fCell_x,
                                            this.m_rectStatus.top + this.m_fCell_y * 0.5,
                                            this.m_rectStatus.left + (this.m_fCell_x + this.m_fMargin_x) * 5.0,
                                            this.m_rectStatus.top + this.m_fCell_y * 1.5])

        this.m_rectScoreLCD := D2D1_RECT_F([this.m_rectStatus.left + (this.m_fCell_x + this.m_fMargin_x) * 2.0,
                                            this.m_rectStatus.top + this.m_fCell_y * 2.5,
                                            this.m_rectStatus.left + (this.m_fCell_x + this.m_fMargin_x) * 6.0,
                                            this.m_rectStatus.top + this.m_fCell_y * 3.5])

        this.m_rectRemoveLineText := D2D1_RECT_F([this.m_rectStatus.left + this.m_fCell_x,
                                                    this.m_rectStatus.top + this.m_fCell_y * 4.5,
                                                    this.m_rectStatus.left + (this.m_fCell_x + this.m_fMargin_x) * 5.0,
                                                    this.m_rectStatus.top + this.m_fCell_y * 5.5])
                                                
        this.m_rectRemoveLineLCD := D2D1_RECT_F([this.m_rectStatus.left + (this.m_fCell_x + this.m_fMargin_x) * 2.0,
                                                this.m_rectStatus.top + this.m_fCell_y * 6.5,
                                                this.m_rectStatus.left + (this.m_fCell_x + this.m_fMargin_x) * 6.0,
                                                this.m_rectStatus.top + this.m_fCell_y * 7.5])

        this.m_rectLevelText := D2D1_RECT_F([this.m_rectStatus.left + this.m_fCell_x,
                                            this.m_rectStatus.top + this.m_fCell_y * 8.5,
                                            this.m_rectStatus.left + (this.m_fCell_x + this.m_fMargin_x) * 5.0,
                                            this.m_rectStatus.top + this.m_fCell_y * 9.5])

        this.m_rectLevelLCD := D2D1_RECT_F([this.m_rectStatus.left + (this.m_fCell_x + this.m_fMargin_x) * 5.0,
                                            this.m_rectStatus.top + this.m_fCell_y * 10.5,
                                            this.m_rectStatus.left + (this.m_fCell_x + this.m_fMargin_x) * 6.0,
                                            this.m_rectStatus.top + this.m_fCell_y * 11.5])

        this.m_rectNextText := D2D1_RECT_F([this.m_rectStatus.left + this.m_fCell_x,
                                            this.m_rectStatus.top + this.m_fCell_y * 12.5,
                                            this.m_rectStatus.left + (this.m_fCell_x + this.m_fMargin_x) * 5.0,
                                            this.m_rectStatus.top + this.m_fCell_y * 13.5])
    }
	DrawBackground()
    {
        this.m_pRenderTarget.SetTransform(D2D1_MATRIX_3X2_F([1, 0, 0, 1, 00]))
        this.m_pRenderTarget.Clear(BACKCOLOR)
    }
	DrawBorder()
    {
        this.m_pBrush.SetColor(FORECOLOR)
        this.m_pRenderTarget.DrawRectangle(this.m_rectGrid, this.m_pBrush, 2.0, 0)
    }
	DrawGrid(pGrid)
    {
        loop ROW_NUM
        {
            i := A_Index
            loop COL_NUM
            {
                j := A_Index
                this.m_pBrush.SetColor(GRIDCOLOR)

                left := this.m_rectGrid.left + (this.m_fMargin_x + this.m_fCell_x) * (j - 1) + this.m_fMargin_x
                top := this.m_rectGrid.top + (this.m_fMargin_y + this.m_fCell_y) * (i - 1) + this.m_fMargin_y
                right := left + this.m_fCell_x
                bottom := top + this.m_fCell_y

                this.m_pRenderTarget.DrawRectangle(D2D1_RECT_F([left + this.m_fMargin_x * 0.5,
                                                                top + this.m_fMargin_y * 0.5,
                                                                right - this.m_fMargin_x * 0.5,
                                                                bottom - this.m_fMargin_y * 0.5]), 
                                                    this.m_pBrush, 2.0, 0)
                this.m_pRenderTarget.FillRectangle(D2D1_RECT_F([left + this.m_fMargin_x * 1.9,
                                                                top + this.m_fMargin_y * 1.9,
                                                                right - this.m_fMargin_x * 1.9,
                                                                bottom - this.m_fMargin_y * 1.9]), 
                                                    this.m_pBrush)

            }
        }
    }
	DrawScore(score)
    {
    	this.m_pLcdScore.DrawLCDNumber(score, this.m_pBrush, FORECOLOR, GRIDCOLOR)
    }
	DrawLevel(lev)
    {	
        this.m_pLcdLevel.DrawLCDNumber(lev, this.m_pBrush, FORECOLOR, GRIDCOLOR)
    }
	DrawStaticText()
    {
        this.m_pBrush.SetColor(FORECOLOR)
        this.SetTextFormat(GetRectHeight(this.m_rectScoreText))
	    this.SetTextFormat(GetRectHeight(this.m_rectScoreText))
	    this.m_pRenderTarget.DrawText('得分', this.m_pTextFormat, this.m_rectScoreText, this.m_pBrush)
	    this.SetTextFormat(GetRectHeight(this.m_rectLevelText))
	    this.m_pRenderTarget.DrawText('级别', this.m_pTextFormat, this.m_rectLevelText, this.m_pBrush)
    }
}



class Square
{
    __New(col := 0, row := 0) 
    {
        this.m_iCol := col
        this.m_iRow := row
    }
    __Delete() 
    {
        
    }
    GetRow()
    {
        return this.m_iRow
    }
    GetCol()
    {
        return this.m_iCol
    }
    SetRow(row)
    {
        this.m_iRow := row
    }
    SetCol(col)
    {
        this.m_iCol := col
    }
}

class LCDNumber
{
	__New(render_target, rect, spacing, digits, is_enable_bg_color := true) 
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
	DrawLCDNumber(num, brush, fr_color, bg_color)
	{
		while(num > 10 ** this.m_digits - 1)
		{
			num := Integer(Mod(num, this.m_digits))
		}

		ar := StrSplit(num)
        number_length := ar.Length
		if(ar.Length > this.m_digits)
			return
		loop(this.m_digits - ar.Length)
			ar.InsertAt(1, 0)
        flag := false
		loop(this.m_digits)
		{
			a := this[A_Index - 1]
			b := Integer(ar[A_Index])
			c := a[b]
            if(A_Index > (this.m_digits - number_length))
            {
                flag := true
            }
			if(this.m_enable_bg_color)
			{
				brush.SetColor(bg_color)
				this.m_render_target.FillGeometry(a[0], brush)
			}
            if(flag)
            {
                brush.SetColor(fr_color)
                this.m_render_target.FillGeometry(c, brush)
            }
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

GetRectHeight(rect)
{
	return rect.bottom-rect.top
}
GetRectWidth(rect)
{
	return rect.right-rect.left
}


win_process(HWND, Msg, wParam, lParam, SubclassID, RefData)
{
    Critical
    switch Msg 
    {
        case WM_SIZE := 0x0005:
        {
            width := lParam & 0xffff
            height := (lParam >> 16) & 0xffff
            pView.Resize(width, height)
        }
        case WM_PAINT := 0x000F:
        {
            PaintStruct := Buffer(A_PtrSize + 60, 0)
            hdc := DllCall('User32\BeginPaint', 'ptr', hwnd, 'ptr', PaintStruct, 'ptr')
            DllCall('User32\EndPaint', 'ptr', hWnd, 'ptr', PaintStruct, 'int')
            pGame.UpdateView()
        }
        case WM_KEYDOWN := 0x0100:
        {
            if (!pGame.GameOver())
            {
                switch(wParam)
                {
                    case KEY_UP: 
                    {
                        pGame.set_position([0, -1])
                    }
                    case KEY_DOWN:
                    {
                        pGame.set_position([0, 1])
                    }
                    case KEY_LEFT:
                    {
                        pGame.set_position([-1, 0])
                    }
                    case KEY_RIGHT:
                    {
                        pGame.set_position([1, 0])
                    }
                }
                pGame.UpdateView()
            }
        }
        case WM_TIMER := 0x113:
        {
            if (!pGame.GameOver())
            {
                pGame.Timer()
            }
            pGame.UpdateView()
        }
        default:
    }
    Return DllCall("Comctl32.dll\DefSubclassProc", "Ptr", HWND, "UInt", Msg, "Ptr", wParam, "Ptr", lParam)
}

class DirectGui2Hwnd extends Gui
{
	pd2d1 := ID2D1Factory(), pdwrite := IDWriteFactory()
	/** @type {ID2D1DCRenderTarget} */
	render := 0
    __New(Options := '', Title := A_ScriptName, w := SysGet(78), h := SysGet(79)) 
    {
		super.__New(Options, Title || A_ScriptName)
        hwnd_render_target_property := D2D1_HWND_RENDER_TARGET_PROPERTIES([this.Hwnd, w, h, D2D1_PRESENT_OPTIONS_NONE := 0])
        this.render := this.pd2d1.CreateHwndRenderTarget(D2D1_RENDER_TARGET_PROPERTIES([]), hwnd_render_target_property)
    }
    __Delete() => (0)
    show(p*) => super.Show(p*)
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

rgba(color := [0, 0, 0, 0]) => ([color[1]/255, color[2]/255, color[3]/255, color[4]/255])

rgb2float(x)
{
    x := Integer('0x' x)
    g := ((x & 0x00ff00) >> 8) / 255
    r := ((x & 0xff0000) >> 16) / 255
    b := ((x & 0xff)) / 255
    color := [r, g, b, 1]
    return color
}
deepclone(obj) {
	objs := Map(), objs.Default := ''
	return clone(obj)

	clone(obj) {
		switch Type(obj) {
			case 'Array', 'Map':
				o := obj.Clone()
				for k, v in o
					if IsObject(v)
						o[k] := objs[p := ObjPtr(v)] || (objs[p] := clone(v))
				return o
			case 'Object':
				o := obj.Clone()
				for k, v in o.OwnProps()
					if IsObject(v)
						o.%k% := objs[p := ObjPtr(v)] || (objs[p] := clone(v))
				return o
			default:
				return obj
		}
	}
}


; ======================================================================================================================
; SubclassControl    Installs, updates, or removes the subclass callback for the specified control.
; Author:            just me (www.ahkscript.org) v1; => v2 by sxz
; Tested with:       AHK 1.1.15.00 U64
; Tested on:         Win 8.1 x64
; Parameters:        HCTRL    -  Handle to the control.
;                    func_object - If you pass an empty string (""), the subclass callback will be removed.
;                    RefData  -  Optional integer value passed to the callback function.
; Return value:      Non-zero if the subclass callback was successfully installed, updated, or removed;
;                    otherwise, False.
; Remarks:           The callback function must have exactly six parameters, see
;                    SUBCLASSPROC -> msdn.microsoft.com/en-us/library/bb776774(v=vs.85).aspx
; ======================================================================================================================
SubclassControl(HCTRL, func_object, RefData := 0)
{
    Static ControlCB := Map()
    If ControlCB.Has(HCTRL) 
    {
        DllCall("Comctl32.dll\RemoveWindowSubclass", "Ptr", HCTRL, "Ptr", ControlCB[HCTRL], "Ptr", HCTRL)
        DllCall("Kernel32.dll\GlobalFree", "Ptr", ControlCB[HCTRL], "Ptr")
        ControlCB.Delete(HCTRL)
        If (func_object = '')
            Return True
    }
    a := DllCall("User32.dll\IsWindow", "Ptr", HCTRL, "UInt")
    b := HasMethod(func_object)
    c := CallbackCreate(func_object)
    if(!DllCall("User32.dll\IsWindow", "Ptr", HCTRL, "UInt") 
        || !HasMethod(func_object)
        || !(cb := CallbackCreate(func_object)))
    {
        return false
    }
    If !DllCall("Comctl32.dll\SetWindowSubclass", "Ptr", HCTRL, "Ptr", CB, "Ptr", HCTRL, "Ptr", RefData)
        Return (DllCall("Kernel32.dll\GlobalFree", "Ptr", CB, "Ptr") & 0)
    Return (ControlCB[HCTRL] := CB)
}