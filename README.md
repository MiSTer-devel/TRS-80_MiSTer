# HT1080Z_MiSTer
port of HT1080Z by Jozsef Laszlo to MiSTer

Mist homepage:
  http://joco.homeserver.hu/fpga/mist_ht1080z_en.html

To learn how to use the TRS-80, this is a quick tutorial:
https://www.classic-computers.org.nz/system-80/driving_instructions.htm

To load a cassette game:
```
  return
  system
  <Then go to the OSD and load a cassette>
  [type the first letter of the file you want to load (e or g for the disk images provided)]
  / 
```

## Features:
 * Simulates a TRS-80 Model I with 48KB installed (currently no expansion interface or disk drives)
 * Sound output is supported (however cassette saving sound is suppressed)
 * Cassette loading is many times faster than the original 500 baud
 

## Notes:
 * The included BOOT.ROM has been modified to take advantage of a special interface for loading cassettes; original BASIC ROMs are also supported

## Technical:
Special ports (i.e. Z-80 "OUT"/"IN" commands) have been added as follows:
 * VIDEO:
   * OUT 0, n (where n=(0-7)) -> change foreground color
   * OUT 1, n (where n=(0-7)) -> change bacgronund color
   * OUT 2, n (where n=(0-7)) -> change overscan color

 * Memory-mapped cassette:
   * OUT 6, n (where n=(0-255)) -> set address bits 23-16 of virtual memory pointer
   * OUT 5, n (where n=(0-255)) -> set address bits 15- 8 of virtual memory pointer
   * OUT 4, n (where n=(0-255)) -> set address bits  7- 0 of virtual memory pointer
   * A = INP(4)  -> read virtual memory at current virtual memory pointer and increment pointer
   * Note that cassette image is loaded at 0x010000, and no memory exists beyond 0x01ffff
