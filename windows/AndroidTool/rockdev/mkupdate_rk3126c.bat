Afptool -pack .\backupimage backupimage\backup.img
Afptool -pack ./ Image\update.img

RKImageMaker.exe -RK312A Image\MiniLoaderAll.bin Image\update.img update.img -os_type:androidos

rem update.img is new format, Image\update.img is old format, so delete older format
del  Image\update.img

pause 
