#include <Gdip_All>
#include <wincapture>

dx := wincapture.DXGI()
Gdip_Startup()
pbitmp := Gdip_BitmapFromScreen()
bb := BitmapBuffer.loadGpBitmap(pbitmp)
Gdip_DisposeImage(pbitmp)
bb := bb.threshold()
if(my_select_region(&x, &y, &w, &h))
{
    text := ''
    loop h
    {
        y0 := A_Index - 1
        loop w
        {
            x0 := A_Index - 1
            x1 := x + x0
            y1 := y + y0
            v := bb[x1, y1] == 0 ? '0' : '_'
            text .= v
        }
        text .= '`n'
    }
    A_Clipboard := text
}
MsgBox text

my_select_region(&x, &y, &w, &h)
{
    rtn := ReadProcessStdOut(A_ScriptDir '\get_region.exe')
    if(rtn != 'error')
    {
        word_array := StrSplit(rtn, A_Space, ".")  ; 忽略句点.
        x := word_array[1], y := word_array[2]
        w := word_array[3], h := word_array[4]
    }
    else
    {
        return false
    }
    return true
}
ReadProcessStdOut(cmd, stdin := "", encoding := "cp0", is_wait := true) 
{
    sa := Buffer(24)
    NumPut("uint", sa.Size, sa)
    NumPut("ptr", 0, "uint", 1, sa, 8)

    if !DllCall("CreatePipe", "ptr*", &hReadPipeOut := 0, "ptr*", &hWritePipeOut := 0, "ptr", sa, "uint", 0)
        throw OSError()
    DllCall("SetHandleInformation", "ptr", hReadPipeOut, "uint", 1, "uint", 0)

    si := Buffer(104, 0)
    NumPut("uint", si.Size, si)
    NumPut("uint", 0x101, si, 60)
    NumPut("ptr", hWritePipeOut, si, 88)

    if stdin !== "" {
        if !DllCall("CreatePipe", "ptr*", &hReadPipeIn := 0, "ptr*", &hWritePipeIn := 0, "ptr", sa, "uint", 0)
            throw OSError()
        DllCall("SetHandleInformation", "ptr", hWritePipeIn, "uint", 1, "uint", 0)
        NumPut("ptr", hReadPipeIn, si, 80)
    }

    if !DllCall("CreateProcessW", "ptr", 0, "str", cmd, "ptr", 0, "ptr", 0, "int", true, "uint", 0, "ptr", 0, "ptr", 0, "ptr", si, "ptr", pi := Buffer(24)) {
        DllCall("CloseHandle", "ptr", hWritePipeOut)
        DllCall("CloseHandle", "ptr", hReadPipeOut)
        throw OSError()
    }
    DllCall("CloseHandle", "ptr", NumGet(pi, "ptr"))
    DllCall("CloseHandle", "ptr", NumGet(pi, 8, "ptr"))
    DllCall("CloseHandle", "ptr", hWritePipeOut)


    if stdin !== "" {
        DllCall("CloseHandle", "ptr", hReadPipeIn)
        if !DllCall("WriteFile", "ptr", hWritePipeIn, "astr", stdin, "uint", StrPut(stdin, encoding) - 1, "uint*", &lpNumberOfBytesWritten := 0, "ptr", 0){
            DllCall("CloseHandle", "ptr", hWritePipeIn)
            throw OSError()
        }
        DllCall("CloseHandle", "ptr", hWritePipeIn)
    }

	if(!is_wait)
		return

    stdout := ""
    while DllCall("ReadFile", "ptr", hReadPipeOut, "ptr", buf := Buffer(4096), "uint", buf.Size, "uint*", &lpNumberOfBytesRead := 0, "ptr", 0) && lpNumberOfBytesRead
        stdout .= StrGet(buf, lpNumberOfBytesRead, encoding)
    DllCall("CloseHandle", "ptr", hReadPipeOut)

    return stdout
}