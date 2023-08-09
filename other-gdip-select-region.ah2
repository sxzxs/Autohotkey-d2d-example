#include <Gdip_All>
If !pToken := Gdip_Startup()
{
    FileAppend('error', "*")
	ExitApp
}
OnExit ExitFunc
bk := back_screen()
Area := SelectScreenRegion("LButton", "Red", 30)
bk.Destroy()
if(Area != false)
    FileAppend( Area.x ' ' Area.y ' ' Area.w ' ' Area.h, "*")
else
    FileAppend('error', "*")
ExitApp

SelectScreenRegion(Key, Color := "Lime", Transparent:= 80)
{
	CoordMode("Mouse", "Screen")
    loop
    {
        ToolTip("请按下: " Key)
        sleep(50)
        if(GetKeyState("Esc"))
        {
            ToolTip
            return false
        }
    }until (GetKeyState(key))
	MouseGetPos(&sX, &sY)
	ssrGui := Gui("+AlwaysOnTop -caption +Border +ToolWindow +LastFound -DPIScale", 'section gui')
	WinSetTransparent(Transparent)
	ssrGui.BackColor := Color
	Loop 
	{
		Sleep 10
		MouseGetPos(&eX, &eY)
		W := Abs(sX - eX), H := Abs(sY - eY)
		X := Min(sX, eX), Y := Min(sY, eY)
		ssrGui.Show("x" X " y" Y " w" W " h" H)
	} Until !GetKeyState(Key, "p")
	ssrGui.Destroy()
    ToolTip
	Return { X: X, Y: Y, W: W, H: H, X2: X + W, Y2: Y + H }
}
back_screen()
{
    Gui1 := Gui("-Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs")
    Gui1.Show("NA")
    hwnd1 := WinExist()
    pBitmap := Gdip_BitmapFromScreen()
    If !pBitmap
    {
        MsgBox "Could not load 'background.png'"
        ExitApp
    }
    Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)
    hbm := CreateDIBSection(Width, Height)
    hdc := CreateCompatibleDC()
    obm := SelectObject(hdc, hbm)
    G := Gdip_GraphicsFromHDC(hdc)
    Gdip_SetInterpolationMode(G, 7)
    Gdip_DrawImage(G, pBitmap, 0, 0, Width, Height, 0, 0, Width, Height)
    UpdateLayeredWindow(hwnd1, hdc, 0, 0, Width, Height)
    SelectObject(hdc, obm)
    DeleteObject(hbm)
    DeleteDC(hdc)
    Gdip_DeleteGraphics(G)
    Gdip_DisposeImage(pBitmap)
    Return Gui1
}
ExitFunc(ExitReason, ExitCode)
{
   global
   ; gdi+ may now be shutdown on exiting the program
   Gdip_Shutdown(pToken)
}

