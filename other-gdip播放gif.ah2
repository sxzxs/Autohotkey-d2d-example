;translate from https://www.autohotkey.com/boards/viewtopic.php?t=83358
#include <Gdip_All>
#include <wincapture>

Gdip_Startup()

filePath := A_ScriptDir "\gg.gif" ; specify the file path to gif
exStyles := (WS_EX_COMPOSITED := 0x02000000) | (WS_EX_LAYERED := 0x80000)
mygui := Gui('+E' exStyles)
mygui.Add('Button', 'xp y+10 w80 h24', 'play').OnEvent('Click', play_pause)
my_pic := mygui.Add('Picture', 'y10', filePath)

gif1 := Gif(filePath, my_pic.Hwnd)
mygui.Show('AutoSize')

play_pause(*)
{
    isPlaying := gif1.isPlaying
    if(!isPlaying)
        gif1.Play()
    else
        gif1.Pause()
}

class Gif
{
   __New(file, hwnd, cycle := true)
   {
      this.file := file
      this.hwnd := hwnd
      this.cycle := cycle
      this.pBitmap := Gdip_CreateBitmapFromFile(this.file)
      Gdip_GetImageDimensions(this.pBitmap, &width, &height)
      this.width := width, this.height := height
      this.isPlaying := false
      
      DllCall("Gdiplus\GdipImageGetFrameDimensionsCount", "ptr", this.pBitmap, "uptr*", &frameDimensions := 0)
      this.dimensionIDs := Buffer(16*frameDimensions)
      DllCall("Gdiplus\GdipImageGetFrameDimensionsList", "ptr", this.pBitmap, "uptr", this.dimensionIDs, "int", frameDimensions)
      DllCall("Gdiplus\GdipImageGetFrameCount", "ptr", this.pBitmap, "uptr", this.dimensionIDs, "int*", &count := 0)
      this.frameCount := count
      this.frameCurrent := -1
      this.frameDelay := this.GetFrameDelay(this.pBitmap)
      this._Play("")
      this._fn := this._Play.Bind(this)
   }
   ; Return a zero-based array, containing the frames delay (in milliseconds)
    GetFrameDelay(pImage) 
    {
        static PropertyTagFrameDelay := 0x5100

        DllCall("Gdiplus\GdipGetPropertyItemSize", "Ptr", pImage, "UInt", PropertyTagFrameDelay, "UInt*", &ItemSize := 0)
        Item := Buffer(ItemSize)
        DllCall("Gdiplus\GdipGetPropertyItem", "Ptr", pImage, "UInt", PropertyTagFrameDelay, "UInt", ItemSize, "Ptr", Item)

        PropLen := NumGet(Item, 4, "UInt")
        PropVal := NumGet(Item, 8 + A_PtrSize, "UPtr")

        outArray := []
        loop(PropLen//4)
        {
            if( !n := NumGet(PropVal, (A_Index-1)*4, "UInt"))
                n := 10
            outArray.Push(n*10)
        }
        return outArray
    }
    Play()
    {
        this.isPlaying := true
        SetTimer(this._fn, -1)
    }
    Pause()
    {
        this.isPlaying := false
        fn := this._fn
        SetTimer(this._fn, 0)
    }
   _Play(mode := "set")
   {
        this.frameCurrent := mod(++this.frameCurrent, this.frameCount)
        DllCall("Gdiplus\GdipImageSelectActiveFrame", "ptr", this.pBitmap, "uptr", this.dimensionIDs, "int", this.frameCurrent)
        hBitmap := Gdip_CreateHBITMAPFromBitmap(this.pBitmap)
        SetImage(this.hwnd, hBitmap)
        DeleteObject(hBitmap)
        if (mode = "set" && this.frameCurrent < (this.cycle ? 0xFFFFFFFF : this.frameCount - 1)) 
        {
            SetTimer(this._fn, -1 * this.frameDelay[this.frameCurrent + 1])
        }
   }
   __Delete()
   {
      Gdip_DisposeImage(this.pBitmap)
   }
}