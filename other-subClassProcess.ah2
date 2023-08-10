#include <log>
;通过SetWindowSubclass处理windows消息 v2版本
ui := Gui('')
;editor := ui.Add('Edit', 'w100 h100', 'Kopier mich mal!')
ui.Show('w100 h100')
SubclassControl(ui.Hwnd, NotAllowed)
SetTimer(bc, 1000)

bc()
{
    ;logger.info()
    PostMessage(WM_TIMER := 0x113, ,,, ui.Hwnd)
}

NotAllowed(HWND, Msg, wParam, lParam, SubclassID, RefData) 
{
    Critical
    logger.info(Msg)
    ; WM_CUT = 0x0300, WM_COPY = 0x0301
    If (Msg = 0x0300) || (Msg = 0x0301) 
    {
        MsgBox('Kopieren ist hier verboten!')
        Return 0
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
#Include <Advapi32>