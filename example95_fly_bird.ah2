;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@%#%%######%@@@@%**++%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#%%#####%@@@@@@@@@% -@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*++%@@@
;@@@@@@#* =######::@@@@@@%:*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=.*###*=-%@@@@@@@@#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@* %@@@
;@@@@@@@@.#@@@@@@#*@@@@@@%:#@@@@@@@*=*#@@@@#*=*@@@@@@@@@@@@@@@@@*:@@@@@@:-@@@@@#***#@@@@@@@@%**+@@#***%@@@@%*****%#.%@@@
;@@@@@@@@.=**:-@@@@@@@@@@%:#@@@@@@@@=:@@@@@@=-@@@@@@@@@@@@@@@@@@*.*****--%@@@@@@@@--@@@@@@@@@@#.=*#@@#*@@@++#@@@%*:.%@@@
;@@@@@@@@.+%#-=@@@@@@@@@@%:*@@@@@@@@@+-@@@@=-@@@@@@@@@@@@@@@@@@@*.*%#%##+=%@@@@@@@=-@@@@@@@@@@%:#@@@@@@@@=:@@@@@@@*.%@@@
;@@@@@@@@.#@@@@@@@@@@@@@@%:#@@@@@@@@@@+-@@=-@@@@@@@@@@@@@@@@@@@@*:@@@@@@@::@@@@@@@==@@@@@@@@@@%:%@@@@@@@@+:@@@@@@@+.%@@@
;@@@@@@%# +%%%@@@@@@@@%%%#.+%%%%@@@@@@@*-=-@@@@@@@@@@@@@@@@@@@@%+ #%%%%#+:#@@@%%%%-:%%%%@@@@%%*.*%%%%@@@@@*=*%%%#+: *@@@
;@@@@@@#******@@@@@@@%*********#@@@@@@@@-:@@@@@@@@@@@@@@@@@@@@@*********#@@@@@#********#@@@@#*******#@@@@@@@#***#%@**%@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+-@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#include <wincapture>
#include <Direct2D>
#include <Gdip_All>

BACKCOLOR := D2D1_COLOR_F([0.62,0.68,0.53,1.0])
FORECOLOR := D2D1_COLOR_F([0.0,0.0,0.0,1.0])
main()


main()
{
    Gdip_Startup()
    dx := wincapture.DXGI()
    global ui := Gui('+AlwaysOnTop -DPIScale +Caption  +Border +LastFound -ToolWindow -Resize -HScroll  +SysMenu','按键: k')
    ui.show('x0 y0 w1000 h600')
	global pView := View()
    pView.Initial(ui)

    ;load pic
    ccc := BitmapBuffer.loadPicture(A_ScriptDir '\bird.png')
    props := D2D1_BITMAP_PROPERTIES([D2D1_PIXEL_FORMAT([87, 1]), 96 * 1, 96 * 1])
    global bird_image := pView.m_pRenderTarget.CreateBitmap(size := D2D1_SIZE_U([ccc.width, ccc.height]),
        ccc.ptr, ccc.pitch, props)

	global pGame := Game(pView)
    pGame.UpdateView()

    SubclassControl(ui.Hwnd, win_process)
    SetTimer(timer_handle.bind(ui), 45)
}

timer_handle(ui)
{
    PostMessage(WM_TIMER := 0x113, ,,, ui.Hwnd)
    ;更新定时器时间
    SetTimer , 45
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
        this.m_isOver := false

        ;开始自由落体的时间
        this.t_down := 0
        ;开始上升的时间
        this.t_up := 0
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
        this.m_pView.draw_pillar()
        this.m_pView.draw_bird()
        this.m_pView.EndDraw()
    }
	Timer()
    {	
        this.move()
    }
    move()
    {
        size := this.m_pView.m_pRenderTarget.GetSize()
        for k,v in this.m_pView.pillars
        {
            v.mover(-1, 0)
            if(v.x + v.width < 0)
            {
                rd := Random()
                h := (size.height - Pillar.clearance_height) * rd
                v.move(size.width,,h)
            }
        }
        if(GetKeyState('k'))
        {
            this.t_down := 0
            this.t_up++
            ; y = 0.4x + 20
            this.m_pView.bird.mover(-(-0.6 * this.t_up + 10))
        }
        else
        {
            this.t_up := 0
            this.t_down++
            this.m_pView.bird.mover((this.t_down / 4) **2)
        }
        ;碰撞检测
        ;小鸟的bottom不能低于下边界
        if(this.m_pView.bird.position.Bottom > size.height)
        {
            this.m_isOver := true
            return
        }
        ;小鸟的bottom和top不能触碰到柱子
        bird_position := this.m_pView.bird.position
        for k,v in this.m_pView.pillars
        {
            if((bird_position.Right > v.x && bird_position.Right < (v.x + v.width)) ||
                (bird_position.Left > v.x && bird_position.Left < (v.x + v.width) ))
            {
                if(!((bird_position.Top < (v.height + Pillar.clearance_height) && bird_position.Top > v.height) && 
                    (bird_position.Bottom < (v.height + Pillar.clearance_height) && bird_position.Bottom > v.height)))
                {
                    this.m_isOver := true
                    return
                }
            }
        }
    }
	GameOver()
    {	
        return this.m_isOver
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

        this.pillars := [Pillar(200, 200), Pillar(400, 250), Pillar(600, 150), Pillar(800, 130), Pillar(1000, 230)]

        this.bird := Bird()
    }
    draw_pillar()
    {
        this.m_pBrush.SetColor(FORECOLOR)
        size := this.m_pRenderTarget.GetSize()
        for k,v in this.pillars
        {
            this.m_pRenderTarget.DrawRectangle(D2D1_RECT_F([v.x, v.y, v.x + v.width, v.y + v.height]), this.m_pBrush, 2.0, 0)

            this.m_pRenderTarget.DrawRectangle(D2D1_RECT_F([v.x, v.y + v.height + Pillar.clearance_height, v.x + v.width, size.height]), this.m_pBrush, 2.0, 0)
        }
    }
    draw_bird()
    {
        this.m_pBrush.SetColor(FORECOLOR)
        ;this.m_pRenderTarget.DrawRectangle(this.bird.position, this.m_pBrush, 2.0, 0)
        this.m_pRenderTarget.DrawBitmap(bird_image, this.bird.position)
    }
    Initial(ui)
    {
	    this.m_pFactory := ID2D1Factory(), this.m_pWriteFactory := IDWriteFactory()
        ui.GetClientPos(&x, &y, &w, &h)
        hwnd_render_target_property := D2D1_HWND_RENDER_TARGET_PROPERTIES([ui.Hwnd, w, h, D2D1_PRESENT_OPTIONS_NONE := 0])
        this.m_pRenderTarget := this.m_pFactory.CreateHwndRenderTarget(D2D1_RENDER_TARGET_PROPERTIES([,,,96,96]), hwnd_render_target_property)
        this.m_pBrush := this.m_pRenderTarget.CreateSolidColorBrush(BACKCOLOR)
    }
    SetTextFormat(size)
    {
        this.m_pTextFormat := this.m_pWriteFactory.CreateTextFormat('Microsoft YaHei UI', 0, 
                                                                        DWRITE_FONT_WEIGHT_LIGHT := 300, 
                                                                        DWRITE_FONT_STYLE_NORMAL := 0, 
                                                                        DWRITE_FONT_STRETCH_NORMAL := 5, size, '')
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
    }
	CaculateLayout()
    {
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
}

class Pillar
{
    static clearance_height := 100
    __New(x := 100, h := 100) 
    {
        this.height := h
        this.width := 50
        this.x := x
        this.y := 0
    }
    mover(rx := 0, ry := 0)
    {
        this.x += rx
        this.y += ry
    }
    move(x := 0, y := 0, h := unset)
    {
        this.x := x
        this.y := y
        if(IsSet(h))
            this.height := h
    }
}

class Bird
{
    __New() 
    {
        this.position := D2D1_RECT_F([100, 100, 130 ,130])
    }
    mover(rh)
    {
        this.position.Top += rh
        this.position.Bottom += rh
    }
}

win_process(HWND, Msg, wParam, lParam, SubclassID, RefData)
{
    Critical
    static KEY_DOWN := GetKeyVK('j')
    static KEY_UP := GetKeyVK('k')
    switch Msg 
    {
        case WM_SIZE := 0x0005:
        {
            width := lParam & 0xffff
            height := (lParam >> 16) & 0xffff
            pView.Resize(width, height)
            pGame.UpdateView()
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
            switch(wParam)
            {
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