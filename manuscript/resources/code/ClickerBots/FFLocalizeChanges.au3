#include "FastFind.au3"

Sleep(5 * 1000)
FFSnapShot (0, 0, 0, 0, 0)

MsgBox(0, "Info", "Измените изображение")

Sleep(5 * 1000)
FFSnapShot (0, 0, 0, 0, 1)

$coords = FFLocalizeChanges(0, 1, 10)

if not @error then
    MsgBox(0, "Coords", "x1 = " & $coords[0] & ", y1 = " & $coords[1] & _
           " x2 = " & $coords[2] & ", y2 = " & $coords[3])
else
    MsgBox(0, "Coords", "Изменения не обнаружены")
endif
