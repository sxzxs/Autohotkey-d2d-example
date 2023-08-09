#include <log>

main_ui := Gui('-DPIScale')
main_ui.Add('Button', 'w100 h50 x0 y0', 'button')


sub_ui := Gui('+AlwaysOnTop -DPIScale -Caption -Border +LastFound ToolWindow -Resize -HScroll +E0x08000000 -SysMenu')
sub_ui.Add('Button', 'w100 h50 x0 y0', 'sub button')
sub_ui.Opt('+Parent' main_ui.Hwnd)
sub_ui.Show('x100 y100')

main_ui.Show('w500 h500')