;目前有问题，这个工具不支持stdout输出
#include <Gdip_All>
#include <wincapture>
#Include <Advapi32>

dx := wincapture.DXGI()
Gdip_Startup()

src := '屏幕' ; || '文件'
rtn := MsgBox('从屏幕获取图像?',,'YesNoCancel')
if(rtn = "No")
{
    rtn := MsgBox('从图像文件获取?',,'YesNoCancel')
    if(rtn = 'no' || rtn = 'Cancel')
        ExitApp
    else
        src := '文件'

}
else if(rtn = 'Cancel')
    ExitApp

if(src = '文件')
{
    SelectedFile := FileSelect(3, , "选择图片", "")
    if SelectedFile = ""
        ExitApp
}
else
{
    pbitmp := Gdip_BitmapFromScreen()
    bb := BitmapBuffer.loadGpBitmap(pbitmp)
    Gdip_DisposeImage(pbitmp)
    if(my_select_region(&x, &y, &w, &h))
    {
        bb := bb.range(x, y, x + w, y + h, true)
        SelectedFile := A_ScriptDir '\tmp.bmp'
        bb.save(SelectedFile)
    }
    else
        ExitApp
}

MsgBox(A_ComSpec ' /c ""' A_ScriptDir '\ascii-image-converter.exe" "'  SelectedFile '"'  ' --save-txt ."')
a := RunWait(A_ComSpec ' /c ""' A_ScriptDir '\ascii-image-converter.exe" "'  SelectedFile '"'  ' --save-txt ."',,, &pid)
if(a == 0)
{
    SplitPath SelectedFile, &name, &dir, &ext, &name_no_ext, &drive
    out_file := A_ScriptDir '\' name_no_ext '-ascii-art.txt'
    text := FileRead(out_file)
    MsgBox(text)
    A_Clipboard := text
}

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