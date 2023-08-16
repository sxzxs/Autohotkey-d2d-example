#include E:\我的AHK程序\imgui_autohotkey\autohotkey_v2\lib\imgui.ahk
#include <log>
#include <wincapture>
#include <Direct2D>
#include <Gdip_All>
#include <log>

BACKCOLOR := D2D1_COLOR_F([0.62,0.68,0.53,1.0])
FORECOLOR := D2D1_COLOR_F([0.0,0.0,0.0,1.0])

;class Global_data
;{
    ;static __New() 
    ;{
        ;this.__Item := Map()
        ;this.d2 := unset
        ;this.d2_hwnd := unset
        ;this.imgui_hwnd := unset
        ;this.imgui_main_hwnd := unset
    ;}
;}

Global_data := 
{
    __Item : Map(),
    d2 : unset, 
    d2_hwnd : unset,
    imgui_hwnd : unset,
    imgui_main_hwnd : unset
}

_ImGui_EnableViewports(true)
main()
main()
{
    static no_menu := false
    hwnd := _ImGui_GUICreate("AHK ImGui", 0, 0, -5000, -5000, 0, 0x80)
    WinHide(hwnd)
    WinSetAlwaysOnTop(1, hwnd)

    direct2d_window()
    SetTimer(attach, 200)

    style := _ImGui_GetStyle()
	style.WindowBorderSize := 0
	style.WindowTitleAlign := [0.5, 0.5]
	style.WindowMinSize := [200, 400]
	style.FramePadding := [8, 6]

	style.Colors[ImGuiCol_TitleBg] := [255, 101, 53, 255]
	style.Colors[ImGuiCol_TitleBgActive] := [255, 101, 53, 255]
	style.Colors[ImGuiCol_TitleBgCollapsed] := [0, 0, 0, 130]

	style.Colors[ImGuiCol_Button] := [31, 30, 31, 255]
	style.Colors[ImGuiCol_ButtonActive] := [41, 40, 41, 255]
	style.Colors[ImGuiCol_ButtonHovered] := [41, 40, 41, 255]

	style.Colors[ImGuiCol_Separator] := [70, 70, 70, 255]
	style.Colors[ImGuiCol_SeparatorActive] := [76, 76, 76, 255]
	style.Colors[ImGuiCol_SeparatorHovered] := [76, 76, 76, 255]

	style.Colors[ImGuiCol_FrameBg] := [37, 36, 37, 255]
	style.Colors[ImGuiCol_FrameBgActive] := [37, 36, 37, 255]
	style.Colors[ImGuiCol_FrameBgHovered] := [37, 36, 37, 255]

	style.Colors[ImGuiCol_Header] := [0, 0, 0, 0]
	style.Colors[ImGuiCol_HeaderActive] := [0, 0, 0, 0]
	style.Colors[ImGuiCol_HeaderHovered] := [46, 46, 46, 255]

    io := _ImGui_GetIO()
    _ImGui_SetWindowTitleAlign(0.5, 0.5)
    _ImGui_EnableDocking(True)
    static window_flags := 0
    io := _ImGui_GetIO()
    struct_io := Imgui_io(io)
    while(_ImGui_PeekMsg())
    {
        _ImGui_BeginFrame()
        _ImGui_SetNextWindowSize(200, 200)
        _ImGui_Begin("AHK2", 0, window_flags | ImGuiWindowFlags_NoResize)
        ;添加代码 =====================================
        _ImGui_Text('imgui frame:' struct_io.Framerate)
        _ImGui_Button('我是IMGUI按钮', 200, 50)
        static text := '100'
        _ImGui_InputText('text', &text)
        ;====================================

        _ImGui_End()
        _ImGui_EndFrame()
        sleep(20)
    }
    ExitApp()
    return
}

attach()
{
    target_hwnd := WinExist('异形窗口')
    imgui_hwnd := WinExist('AHK2')
    if(target_hwnd && imgui_hwnd)
    {
        WinGetPos &X, &Y, &W, &H, target_hwnd
        WinGetPos &X1, &Y1, &W1, &H1, imgui_hwnd
		dllcall("SetWindowLongPtr","Uptr",imgui_hwnd,"int",-8,"Uptr",target_hwnd)
		DllCall("MoveWindow","Uptr",imgui_hwnd,"int",X,"int",Y,"int",W1,"int",H1,"char",0)
        ;setparent(imgui_hwnd, target_hwnd)
    }
}

direct2d_window()
{
    Gdip_Startup()
    dx := wincapture.DXGI()
    w := 400, h := 500
    ;WS_EX_LAYERED E0x80000 异形窗口
    ;WS_EX_TRANSPARENT E0x20 窗口穿透
    clickthrough := false
    global ui := Gui('+E0x80000 -DPIScale -Caption -Border +Alwaysontop +toolwindow -SysMenu' (clickthrough ? " +E0x20" : ""), '异形窗口')
    Global_data.d2_hwnd := ui.Hwnd
    Global_data.d2 := ui
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
    WinGetPos &X, &Y, &W, &H, ui.Hwnd
    logger.info(x, y, w, h)

    if(target_hwnd := WinExist('异形窗口'))
    {
        WinGetPos &X, &Y, &W, &H, target_hwnd
        logger.info(x, y, w, h)
		;DllCall("MoveWindow","Uptr",imgui_hwnd,"int",X + W,"int",Y,"int",200,"int",200,"char",0)
    }
    
    SetTimer(draw.Bind(ui.Hwnd, pRenderTarget, w, h, pBrush), 20)
}

draw(hwnd, pRenderTarget, w, h, pBrush)
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
    global d2_width
    global d2_height
    switch Msg 
    {
        case WM_SIZE := 0x0005:
        {
            d2_width := lParam & 0xffff
            d2_height := (lParam >> 16) & 0xffff
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