#include <log>
TextBackgroundColor := 0xFFBBBB  ; BGR 格式的自定义颜色.
TextBackgroundBrush := DllCall("CreateSolidBrush", "UInt", TextBackgroundColor)

MyGui := Gui('+Resize ')
Text := MyGui.Add("Text",, "Here is some text that is given`na custom background color.")

; 64 位脚本必须调用 SetWindowLongPtr 代替 SetWindowLong:
SetWindowLong := A_PtrSize=8 ? "SetWindowLongPtr" : "SetWindowLong"

WindowProcNew := CallbackCreate(WindowProc)  ; 避免子类化中使用快速模式.
WindowProcOld := DllCall(SetWindowLong, "Ptr", MyGui.Hwnd, "Int", -4  ; -4 为 GWL_WNDPROC
    , "Ptr", WindowProcNew, "Ptr") ; 返回值必须设置为 "Ptr" 或 "UPtr" 而不是 "Int".

MyGui.Show

WindowProc(hwnd, uMsg, wParam, lParam)
{
    Critical
    logger.info(hwnd, uMsg, wParam, lParam)
    ; 否则(因为上面没有返回), 将所有的未处理事件传递给原来的 WindowProc.
    switch uMsg
    {
        case 0x0005:
        {
            width := lParam & 0xffff
            height := (lParam >> 16) & 0xffff
            logger.info('w ' width ' h ' height)
        }
        case 0x0100:
        {
            logger.info(wParam)
        }
        default:
    }
	;pView.Resize(width, height)
    return DllCall("CallWindowProc", "Ptr", WindowProcOld, "Ptr", hwnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam)
}
