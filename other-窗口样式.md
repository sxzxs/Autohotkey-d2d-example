#窗口样式

https://learn.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles

;异形窗口
WS_EX_LAYERED
0x00080000
The window is a layered window. This style cannot be used if the window has a class style of either CS_OWNDC or CS_CLASSDC.
Windows 8: The WS_EX_LAYERED style is supported for top-level windows and child windows. Previous Windows versions support WS_EX_LAYERED only for top-level windows.

;鼠标穿透
WS_EX_TRANSPARENT
0x00000020L
The window should not be painted until siblings beneath the window (that were created by the same thread) have been painted. The window appears transparent because the bits of underlying sibling windows have already been painted.
To achieve transparency without these restrictions, use the SetWindowRgn function.