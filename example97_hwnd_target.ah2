;@@@@@@@@@*=%@@@%#%#=%@@@@@@@@@#***************=%@@@@@@#+%@@+*@@@@@@@@#*@@@@@@@@@@@@*=#@@@@@@@@@@@@@@#+%@@@@@*=@@@@@@@@@
;@@@@@@@@#-*%%%=-*%#.@@+=@@@@@@+-#@@-:%@@*.%@%*.@@@@@%%=:*%#:-*##-*%##%%@@@@@@@@@@@@%==@@@@@@%*%@@@@@+.#@@@@@+:%@@@%@@@@
;@@@@@@@#.+@%%%=-@@#.%@@+*@@@@@+:*%%+-*#%*:#%%+.@@@@@@@+-#@%-=@@#:#@@@@@@@@@%%%%%%%+-#@%@@@@%%#%@@@@@+:##+##%=:#%#+.#@@@
;@@@@@@**:+@@@@=-@%#:#@@+*@@@@@#*%@@#::#%%@@%*##@@@@@@@*-#@%-+@@#:*%%***%@@@@@@@@@@=.#%%%%#+%@@@@@@@@+:#@%@@@+:@@@*.@@@@
;@@@@@%%@-+@@%%-:%%%-*@--@@@@@@@@@#==#@%%@@*:-%@@@@@@@@+:*%#:=@@#:#@%-=@@@@@@@@@@@#-*@@@@%=.@@@@@@@@@*:%%%%#%-.#%#+:*+#@
;@@@@@@@@-+@+=*--@@@*.-*@@@@@@@####%*-#@@#+=*@@@@@@@@%%#*#@%+**#*.@@@=+@@@@@@@@@@#-+@@@@@%:+@@@@@@@@@=.#%#%@*:*#+@@@@%@@
;@@@@@@@@-+@@@@=-@%#*=:#@##@@@@@@@@@@*+*=+#@@@@@@@@@@@@*-*@@*+%%-*@@@=+@@@@@@@@%+=#@@@@@@* %@@@@@@#=*+*%@@%*-*@@#=*@@@@@
;@@@@@@@@:=@@#+:+@%%@@%+=.#@@@@@%#####%%@@@@@@@@@@@@@#**%@@@@*+*%@@@@-+@@@@@@##*%@@@@%#+=:=@@@@@@@@@@@@@##*#@@@@@%+-=+#@
;@@@@@@@@#%@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@%%@@@@@@@@@@#*%@@@@@@@@@@@%#@@@@@@@@@@@@@%#@@
#include <Direct2D>
#include <Gdip_All>
#include <ctypes>
#include <wincapture>
ROW_NUM := 20
COL_NUM := 10
ROW_NUM_FIGURE := 2
COL_NUM_FIGURE := 4
MINIMUM_HEIGHT := 284.0
MINIMUM_WIDTH := 223.0
MARGIN :=  11.0
BACKCOLOR := D2D1_COLOR_F([0.62,0.68,0.53,1.0])
FORECOLOR := D2D1_COLOR_F([0.0,0.0,0.0,1.0])
GRIDCOLOR := D2D1_COLOR_F([0.54,0.59,0.46,1.0])
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
    global ui := Gui('+AlwaysOnTop -DPIScale +Caption  +Border +LastFound -ToolWindow +Resize -HScroll +E0x08000000 +SysMenu','AHK俄罗斯方块')
    ui.show('x0 y0 w400 h380')
	global pView := View()
    pView.Initial(ui)
    pView.InitialRectLCD()
	global pGame := Game(pView)
    pGame.UpdateView()

    ;定时器
    SetTimer(timer_handle.bind(pGame), 1000)
    ;注册消息
    OnMessage 0x000F, WM_PAINT ;resize
    OnMessage(0x0005, WM_SIZE) ;resize
    OnMessage(0x0100, WM_KEYDOWN)
}

timer_handle(pGame)
{
    if (!pGame.GameOver())
    {
        if (pGame.CanMoveDown())
            pGame.Timer()
        else
            pGame.MergeFigureToGrid()
        pGame.UpdateView()
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
        this.m_currFigureInfo := ''
        this.m_nextFigureInfo := ''
        this.m_iLevel := 1
        this.m_iLines := 0
        this.m_iScore := 0
        this.m_isOver := false
        this.m_iFigure_i := 0
        this.m_iFigure_j := 0

	    this.m_currFigureInfo := create_figure(Random(1, 7))
	    this.m_currFigureInfo.SetIndex(Random(1, 4))
	    y := this.m_currFigureInfo.GetFigure().GetBottomY()
	    this.m_currFigureInfo.GetFigure().Move((COL_NUM - 1) / 2, 0 - y)

        this.m_nextFigureInfo := create_figure(Random(1, 7))
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
        Critical
        this.m_pView.BeginDraw()
        this.m_pView.DrawBackground()
        this.m_pView.DrawBorder()
        this.m_pView.DrawGrid(this.m_Grid)
        this.m_pView.DrawCurrentFigure(this.m_currFigureInfo.GetFigure())
        this.m_pView.DrawNextFigure(this.m_nextFigureInfo.GetFigure())
        this.m_pView.DrawStaticText()
        this.m_pView.DrawScore(this.m_iScore)
        this.m_pView.DrawRemoveLine(this.m_iLines)
        this.m_pView.DrawLevel(this.m_iLevel)
        this.m_pView.EndDraw()
    }
    GetLevel()
    {
        return this.m_iLevel
    }
	UpArrowKey()
    {
        x := this.m_currFigureInfo.GetFigure().GetPositionX()
        y := this.m_currFigureInfo.GetFigure().GetPositionY()
        figure := this.m_currFigureInfo.GetNextFigure()
        figure.Move(x, y)
        if (figure.GetLeftX() < 0 || figure.GetRightX() > COL_NUM - 1)
        {
            this.m_currFigureInfo.GetPrevFigure()
        }
    }
	DownArrowKey()
    {
        figure := this.m_currFigureInfo.GetFigure()
        x := figure.GetPositionX()
        y := figure.GetPositionY()
        figure.Move(x, y + 1)
    }
	LeftArrowKey()
    {
        figure := this.m_currFigureInfo.GetFigure()
        x := figure.GetPositionX()
        y := figure.GetPositionY()
        canMove := true

        loop FIGURE_NUM
        {
            sq := figure.GetSquare(A_Index)
            r := sq.GetRow() + figure.GetPositionY()
            c := sq.GetCol() + figure.GetPositionX()
            if (!(c > 0) || (r >= 0 && this.m_Grid[r + 1][c - 1 + 1] == 1))
            {
                canMove := false
            }
        }
        if (canMove)
        {
            figure.Move(x - 1, y)
        }
    }
	RightArrowKey()
    {
        figure := this.m_currFigureInfo.GetFigure()
        x := figure.GetPositionX()
        y := figure.GetPositionY()
        canMove := true
        loop FIGURE_NUM
        {
            sq := figure.GetSquare(A_Index)
            r := sq.GetRow() + figure.GetPositionY()
            c := sq.GetCol() + figure.GetPositionX()
            if (!(c < COL_NUM - 1) || (r >= 0 && this.m_Grid[r + 1][c + 1 + 1] == 1))
            {
                canMove := false
            }
        }
        if (canMove)
        {
            figure.Move(x + 1, y)
        }
    }
	SpaceKey()
    {
        while (this.CanMoveDown())
        {
            this.DownArrowKey()
        }
        this.MergeFigureToGrid()
    }
	Timer()
    {	
        this.DownArrowKey()
    }
	CanMoveDown()
    {
        figure := this.m_currFigureInfo.GetFigure()
        loop FIGURE_NUM
        {
            sq := figure.GetSquare(A_Index)
            r := sq.GetRow() + figure.GetPositionY()
            c := sq.GetCol() + figure.GetPositionX()
            if (r >= -1 && (r >= ROW_NUM - 1 || this.m_Grid[r + 1 + 1][c + 1] == 1))
            {
                return false
            }
        }
        return true
    }
	MergeFigureToGrid()
    {
        figure := this.m_currFigureInfo.GetFigure()
        loop FIGURE_NUM
        {
            sq := figure.GetSquare(A_Index)
            r := sq.GetRow() + figure.GetPositionY()
            c := sq.GetCol() + figure.GetPositionX()
            if (r >= 0)
            {
                this.m_Grid[r + 1][c + 1] := 1
            }
        }
        this.RemoveGridLine()
        if (this.CheckGameOver())
        {
            this.m_isOver := true
        }
        else
        {
            this.ReinitFigureInfo()
        }
    }
	GameOver()
    {	
        return this.m_isOver
    }
	IncreaseScore()
    {
        this.m_iLines += 1
        this.m_iScore += 10
        this.m_iLevel := Integer(this.m_iScore / 1000 + 1)
    }
	ReinitFigureInfo()
    {
        this.m_currFigureInfo := deepclone(this.m_nextFigureInfo)

        this.m_currFigureInfo.GetFigure().Move(0, 0)

        this.m_currFigureInfo.SetIndex(Random(1, FIGURE_NUM))

        y := this.m_currFigureInfo.GetFigure().GetBottomY()

        this.m_currFigureInfo.GetFigure().Move((COL_NUM - 1) / 2, 0 - y)
        this.m_nextFigureInfo := create_figure(Random(1, FIGURE_NUM))
    }
	RemoveGridLine()
    {
        loop ROW_NUM
        {
            isFull := true
            r := A_Index
            loop COL_NUM
            {
                c := A_Index
                if(this.m_Grid[r][c] == 0)
                {
                    isFull := false
                    break
                }
            }
            if(isFull)
            {
                this.IncreaseScore()
                loop r
                {
                    z := r - A_Index + 1
                    if(z < 2)
                        break
                    loop COL_NUM
                    {

                        this.m_Grid[z][A_Index] := this.m_Grid[z - 1][A_Index]
                    }
                }
            }
        }
    }
	CheckGameOver()
    {
        ret := false
        loop COL_NUM
        {
            if(this.m_Grid[1][A_Index] == 1)
            {
                ret := true
                break
            }
        }
        return ret
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
        m_rectNextFigure := D2D1_RECT_F([])
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
        this.m_rectNextFigure := D2D1_RECT_F([this.m_rectNextText.left + this.m_fCell_x,
                                                this.m_rectNextText.bottom + this.m_fCell_y * 0.67,
                                                this.m_rectNextText.left + (this.m_fCell_x + this.m_fMargin_x) * 5.0,
                                                this.m_rectNextText.bottom + this.m_fCell_y * 2.67])
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
                if(pGrid[i][j] == 1)
                    this.m_pBrush.SetColor(FORECOLOR)
                else
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
	DrawCurrentFigure(figure)
    {	
        this.m_pBrush.SetColor(FORECOLOR)

        loop FIGURE_NUM
        {
            i := A_Index
            col := figure.GetPositionX() + (figure.GetSquare(i)).GetCol()
            row := figure.GetPositionY() + (figure.GetSquare(i)).GetRow()
            if (row < 0)
            {
                continue
            }
            left := this.m_rectGrid.left + (this.m_fMargin_x + this.m_fCell_x) * col + this.m_fMargin_x
            top := this.m_rectGrid.top + (this.m_fMargin_y + this.m_fCell_y) * row + this.m_fMargin_y
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
	DrawNextFigure(figure)
    {
	    this.m_pBrush.SetColor(GRIDCOLOR)
        loop ROW_NUM_FIGURE
        {
            i := A_Index
            loop COL_NUM_FIGURE
            {
                j := A_Index

                left := this.m_rectNextFigure.left + (this.m_fMargin_x + this.m_fCell_x) * (j - 1) + this.m_fMargin_x
                top := this.m_rectNextFigure.top + (this.m_fMargin_y + this.m_fCell_y) * (i -1) + this.m_fMargin_y
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

        x := figure.GetLeftX()
        y := figure.GetTopY()

        a := x < 0 ? 0 - x : x
        b := y < 0 ? 0 - y : y
        figure.Move(figure.GetPositionX() + a, figure.GetPositionY() + b)
        ;figure.Move(1, 1)
	    this.m_pBrush.SetColor(FORECOLOR)
        loop FIGURE_NUM
        {
            i := A_Index
            col := figure.GetPositionX() + (figure.GetSquare(i)).GetCol()
            row := figure.GetPositionY() + (figure.GetSquare(i)).GetRow()
            left := this.m_rectNextFigure.left + (this.m_fMargin_x + this.m_fCell_x) * col + this.m_fMargin_x
            top := this.m_rectNextFigure.top + (this.m_fMargin_y + this.m_fCell_y) * row + this.m_fMargin_y
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
	DrawScore(score)
    {
    	this.m_pLcdScore.DrawLCDNumber(score, this.m_pBrush, FORECOLOR, GRIDCOLOR)
    }
	DrawRemoveLine(lines)
    {
	    this.m_pLcdRemoveLine.DrawLCDNumber(lines, this.m_pBrush, FORECOLOR, GRIDCOLOR)
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
	    this.SetTextFormat(GetRectHeight(this.m_rectRemoveLineText))
	    this.m_pRenderTarget.DrawText('清除行', this.m_pTextFormat, this.m_rectRemoveLineText, this.m_pBrush)
	    this.SetTextFormat(GetRectHeight(this.m_rectLevelText))
	    this.m_pRenderTarget.DrawText('级别', this.m_pTextFormat, this.m_rectLevelText, this.m_pBrush)
	    this.SetTextFormat(GetRectHeight(this.m_rectNextText))
	    this.m_pRenderTarget.DrawText('下一个', this.m_pTextFormat, this.m_rectNextText, this.m_pBrush)
    }
}

class Figure
{
    __New() 
    {
        this.position := [0, 0]
	    this.cell := [Square(), Square(), Square(), Square()]
    }
    static construct_list(i1, j1, i2, j2, i3, j3, i4, j4)
    {
        o := Figure()
        o.cell := [Square(i1, j1), Square(i2, j2), Square(i3, j3), Square(i4, j4)]
        return o
    }
    static construct_copy(fg)
    {
        o := Figure()
        o.position[1] := fg.position[1]
        o.position[2] := fg.position[2]
        loop FIGURE_NUM
        {
            o.cell[A_Index].SetRow(fg.cell[A_Index].GetRow())
            o.cell[A_Index].SetCol(fg.cell[A_Index].GetCol())
        }
        return o
    }
    __Delete() 
    {
        
    }
	Move(x, y)
    {
        this.position[1] := Integer(x)
        this.position[2] := Integer(y)
    }
	GetSquare(idx)
    {
	    return this.cell[idx]
    }
	GetPositionX()
    {
    	return this.position[1]
    }
	GetPositionY()
    {	
        return this.position[2]
    }
	GetLeftX()
    {
        left := 0
        loop FIGURE_NUM
        {
            if(this.cell[A_Index].GetCol() < left)
            {
                left := this.cell[A_Index].GetCol()
            }
        }
        return Integer(left + this.GetPositionX())
    }
	GetRightX()
    {
        right := 0
        loop FIGURE_NUM
        {
            if(this.cell[A_Index].GetCol() > right)
            {
                right := this.cell[A_Index].GetCol()
            }
        }
        return Integer(right + this.GetPositionX())
    }
	GetTopY()
    {
        top := 0
        loop FIGURE_NUM
        {
            if(this.cell[A_Index].GetRow() < top)
            {
                top := this.cell[A_Index].GetRow()
            }
        }
        return Integer(top + this.GetPositionY())
    }
	GetBottomY()
    {
        bottom := 0
        loop FIGURE_NUM
        {
            if(this.cell[A_Index].GetRow() > bottom)
            {
                bottom := this.cell[A_Index].GetRow()
            }
        }
        return Integer(bottom+ this.GetPositionY())
    }
}

class FigureInfo
{
    __New() 
    {
        this.m_figures := []
        loop FIGURE_NUM
            this.m_figures.Push(Figure())
        this.m_idx := 1
    }
    static construct_copy(info)
    {
        o := FigureInfo()
        o.m_figures[1] := info[1]
        o.m_figures[2] := info[2]
        o.m_figures[3] := info[3]
        o.m_figures[4] := info[4]
    }
    static construct_from_figure(f0, f1, f2, f3)
    {
        o := FigureInfo()
        o.m_figures[1] := f0
        o.m_figures[2] := f1
        o.m_figures[3] := f2
        o.m_figures[4] := f3
        return o
    }
    GetFigure()
    {
	    return this.m_figures[this.m_idx]
    }
    GetPrevFigure()
    {
        this.m_idx := (this.m_idx == 1) ? FIGURE_NUM : this.m_idx - 1
        return this.m_figures[this.m_idx]
    }
    GetNextFigure()
    {
        this.m_idx := Mod(this.m_idx -1 + 1, FIGURE_NUM) + 1
        return this.m_figures[this.m_idx]
    }
    SetIndex(i)
    {
        if (i >= 1 && i <= FIGURE_NUM)
            m_idx := i
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

WM_PAINT(wParam, lParam, msg, hwnd)
{
    Critical
    PaintStruct := Buffer(A_PtrSize + 60, 0)
    hdc := DllCall('User32\BeginPaint', 'ptr', hwnd, 'ptr', PaintStruct, 'ptr')
    DllCall('User32\EndPaint', 'ptr', hWnd, 'ptr', PaintStruct, 'int')
    pGame.UpdateView()
}

WM_LBUTTONDOWN(wParam, lParam, msg, hwnd)
{
	PostMessage 0xA1, 2
}

WM_KEYDOWN(wParam, lParam, msg, hwnd)
{
    if (!pGame.GameOver())
    {
		switch(wParam)
        {
            case VK_UP := 0x26: 
            {
				pGame.UpArrowKey()
            }
            case VK_DOWN := 0x28:
            {
				if (pGame.CanMoveDown())
					pGame.DownArrowKey()
				else
					pGame.MergeFigureToGrid()
            }
            case VK_LEFT := 0x25:
            {
				pGame.LeftArrowKey()
            }
            case VK_RIGHT := 0x27:
            {
				pGame.RightArrowKey()
            }
            case VK_SPACE := 0x20:
            {
				while (pGame.CanMoveDown())
				{
					pGame.DownArrowKey()
					pGame.UpdateView()
				}
				pGame.MergeFigureToGrid()
            }
        }
		pGame.UpdateView()
    }
}

WM_SIZE(wParam, lParam, msg, hwnd)
{
    Critical
    width := lParam & 0xffff
    height := (lParam >> 16) & 0xffff
	pView.Resize(width, height)

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

create_figure(n)
{
    figureO := FigureInfo.construct_from_figure(Figure.construct_list(0,0,0,1,1,1,1,0), 
                                                Figure.construct_list(0,0,0,1,1,1,1,0),
                                                Figure.construct_list(0,0,0,1,1,1,1,0),
                                                Figure.construct_list(0,0,0,1,1,1,1,0))

    figureI := FigureInfo.construct_from_figure(Figure.construct_list(0,0,-1,0,1,0,2,0), 
                                                Figure.construct_list(0,0,0,-1,0,1,0,2),
                                                Figure.construct_list(0,0,-1,0,1,0,2,0),
                                                Figure.construct_list(0,0,0,-1,0,1,0,2))

    figureZ1 := FigureInfo.construct_from_figure(Figure.construct_list(0,0,-1,0,0,1,1,1), 
                                                Figure.construct_list(0,0,1,-1,1,0,0,1),
                                                Figure.construct_list(0,0,-1,0,0,1,1,1),
                                                Figure.construct_list(0,0,1,-1,1,0,0,1))

    figureZ2 := FigureInfo.construct_from_figure(Figure.construct_list(0,0,1,-1,0,-1,-1,0), 
                                                Figure.construct_list(0,0,0,-1,1,0,1,1),
                                                Figure.construct_list(0,0,1,-1,0,-1,-1,0),
                                                Figure.construct_list(0,0,0,-1,1,0,1,1))

    figureT := FigureInfo.construct_from_figure(Figure.construct_list(0,0,-1,0,0,-1,1,0), 
                                                Figure.construct_list(0,0,0,-1,-1,0,0,1),
                                                Figure.construct_list(0,0,-1,0,0,1,1,0),
                                                Figure.construct_list(0,0,0,-1,1,0,0,1))

    figureL1 := FigureInfo.construct_from_figure(Figure.construct_list(0,0,0,-1,1,0,2,0), 
                                                Figure.construct_list(0,0,0,-2,0,-1,-1,0),
                                                Figure.construct_list(0,0,-2,0,-1,0,0,1),
                                                Figure.construct_list(0,0,1,0,0,1,0,2))

    figureL2 := FigureInfo.construct_from_figure(Figure.construct_list(0,0,1,0,2,0,0,1), 
                                                Figure.construct_list(0,0,0,-2,0,-1,1,0),
                                                Figure.construct_list(0,0,0,-1,-2,0,-1,0),
                                                Figure.construct_list(0,0,-1,0,0,1,0,2))
    switch n 
    {
        case 1:
            return figureO
        case 2:
            return figureI
        case 3:
            return figureZ1
        case 4:
            return figureZ2
        case 5:
            return figureT
        case 6:
            return figureL1
        case 7:
            return figureL2
        default:
            MsgBox('Figure number error!')
    }
}