powershell .\get_var.ps1 ..\\localisation\\%1.coco %3 %4 %5 %6 %7 > var.tmp
set /p %2= < var.tmp
del /q var.tmp