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
    w := 400, h := 500
    ;WS_EX_LAYERED E0x80000 异形窗口
    ;WS_EX_TRANSPARENT E0x20 窗口穿透
    clickthrough := false
    global ui := Gui('+E0x80000 -DPIScale -Caption -Border +Alwaysontop +toolwindow -SysMenu' (clickthrough ? " +E0x20" : ""), '异形窗口')
    SubclassControl(ui.Hwnd, win_process)
    ShowWindow(ui.Hwnd, (clickThrough ? 8 : 1)) ;8表示 SW_SHOWNA = NA

    ;设置窗口属性，支持异形窗口
    ;非client区域扩展到clinet区域
	margins := Buffer(16,0)
    NumPut("int",-1,margins,0), NumPut("int",-1,margins,4), NumPut("int",-1,margins,8), NumPut("int",-1,margins,12)
    ext := DllCall("dwmapi\DwmExtendFrameIntoClientArea","Uptr", ui.hwnd,"ptr",margins,"uint")
	DllCall("SetLayeredWindowAttributes","Uptr",ui.hwnd,"Uint",0,"char",255,"uint",2)

    pFactory := ID2D1Factory(), pWriteFactory := IDWriteFactory()
    hwnd_render_target_property := D2D1_HWND_RENDER_TARGET_PROPERTIES([ui.Hwnd, w, h, D2D1_PRESENT_OPTIONS_NONE := 0])
    pRenderTarget := pFactory.CreateHwndRenderTarget(D2D1_RENDER_TARGET_PROPERTIES([,,1,96,96]), hwnd_render_target_property)
    pBrush := pRenderTarget.CreateSolidColorBrush(BACKCOLOR)

    MoveWindow(ui.Hwnd, 0, 0, w, h, true)
    SetTimer(draw.Bind(pRenderTarget, w, h, pBrush), 10)
}

draw(pRenderTarget, w, h, pBrush)
{
    Critical
    pRenderTarget.BeginDraw()
    pRenderTarget.Clear()
    pRenderTarget.FillRoundedRectangle(D2D1_ROUNDED_RECT([D2D1_RECT_F([0, 0, w, h]), 10, 10]) ,pBrush)
    pRenderTarget.EndDraw()
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
        }
        case WM_PAINT := 0x000F:
        {
            PaintStruct := Buffer(A_PtrSize + 60, 0)
            hdc := DllCall('User32\BeginPaint', 'ptr', hwnd, 'ptr', PaintStruct, 'ptr')
            DllCall('User32\EndPaint', 'ptr', hWnd, 'ptr', PaintStruct, 'int')
        }
        case WM_LBUTTONDOWN := 0x201:
        {
	        PostMessage(0xA1, 2,,, HWND)
        }
        case WM_KEYDOWN := 0x0100:
        {
        }
        case WM_TIMER := 0x113:
        {
        }
        default:
    }
    Return DllCall("Comctl32.dll\DefSubclassProc", "Ptr", HWND, "UInt", Msg, "Ptr", wParam, "Ptr", lParam)
}

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