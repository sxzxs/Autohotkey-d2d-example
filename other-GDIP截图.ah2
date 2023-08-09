#include <Gdip_All>
#include <wincapture>

Gdip_Startup()
pbitmp := Gdip_BitmapFromScreen()
bb := BitmapBuffer.loadGpBitmap(pbitmp)
Gdip_DisposeImage(pbitmp)
bb.show()