$hWnd = WinGetHandle("[CLASS:MSPaintApp]")
$coord = PixelSearch(0, 207, 1000, 600, 0x000000, 0, 1, $hWnd)
If @error = 0 then
    MsgBox(0, "", "Координата чёрной точки: x = " & $coord[0] & " y = " &
$coord[1])
else
    MsgBox(0, "", "Чёрная точка не найдена")
endif
