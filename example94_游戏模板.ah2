#include <wincapture>
#include <Direct2D>
#include <Gdip_All>
#include <log>

BACKCOLOR := D2D1_COLOR_F([0.62,0.68,0.53,1.0])
FORECOLOR := D2D1_COLOR_F([0.0,0.0,0.0,1.0])
main()
main()
{

    Gdip_Startup()
    dx := wincapture.DXGI()
    global ui := Gui('+AlwaysOnTop -DPIScale +Caption  +Border +LastFound -ToolWindow +Resize -HScroll  +SysMenu','上k下j左h右l')
    ui.show('x0 y0 w500 h600')
	global pView := View()
    pView.Initial(ui)
	global pGame := Game(pView)
    pGame.UpdateView()

    SubclassControl(ui.Hwnd, win_process)
    SetTimer(timer_handle.bind(ui), 1000)
}

timer_handle(ui)
{
    PostMessage(WM_TIMER := 0x113, ,,, ui.Hwnd)
    ;更新定时器时间
    SetTimer , 1000
    /*
    if(pGame.GameOver())
    {
        rtn := MsgBox('GAME over! restart?',,'YesNo')
        if(rtn = "Yes")
            Reload
        else
            ExitApp
    }
    */
}

class Game
{
    __New(pView) 
    {
        this.m_pView :=  pView
        this.m_isOver := false
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
        this.m_pView.EndDraw()
    }
	Timer()
    {	
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
            ;pGame.UpdateView()
        }
        case WM_KEYDOWN := 0x0100:
        {
            switch(wParam)
            {
                case KEY_UP: 
                {
                }
                case KEY_DOWN:
                {
                }
            }
            ;pGame.UpdateView()
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