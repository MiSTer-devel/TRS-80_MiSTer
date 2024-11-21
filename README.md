# [TRS-80](https://en.wikipedia.org/wiki/TRS-80) for MiSTer Platform
## Model I Support ##
This is a port of [HT1080Z MiST core](https://github.com/mist-devel/ht1080z) by Jozsef Laszlo to the MiSTer

To learn how to use the TRS-80, this is a quick tutorial:
https://www.classic-computers.org.nz/system-80/driving_instructions.htm

The TRS-80 with Disk Drives attached will boot to a screen of '@' symbols and will then only continue booting once you place a disk in the drive.  To bypass this and boot directly to BASIC to load a cassette game, press Escape immediately after selecting Reset in the OSD menu.

### To load a cassette game:
```
  return
  system
  <Then go to the OSD and load a cassette>
  [type the first letter of the file you want to load (e or g for the disk images provided)]
  / (to start once loaded)
```

### To load a CMD file:
Just select it in the OSD. Some CMD files won't work if they access disk rom routines and there is no disk in the drive. Sometimes a clean reboot is necessary before loading a CMD.

### To load files from DSK images:
There are three main TRS-80 image formats, which are JV1, JV3 and DMK and they all usually share the same DSK extension.  This MiSTer Core only supports the JV1 image format with upto 240 tracks, all tracks must currently hold 10 x 256 byte sectors.  To check what format a disk is in, and if it is compatible with the core, use the TRSTOOLS utility from Matthew Reed, available from: http://www.trs-80emulators.com/trstools/

The Disk emulation supports reading and writing to JV1 formatted disks, but disks cannot be formatted in the core because there is no Write Track support for JV1 images.  There are many different DOS versions for the TRS-80 with popular ones including TRSDOS, NEWDOS/80, LDOS and MULTIDOS.  For beginners it is recommended you use TRSDOS which is the original DOS produced by Radio Shack.  Instructions for using TRSDOS can be found in the following Wikipedia article: https://en.wikipedia.org/wiki/TRSDOS

## Features:
 * TRS-80 Model I with 48KB installed
 * Expansion interface with quad disk drives
 * Real Time Clock (RTC)
 * RS232-C Interface (IO ports $E8 to $EA)
 * White, Green and Amber Phosphor screen emulation
 * Sound output is supported (however cassette saving sound is suppressed)
 * Cassette loading is many times faster than the original 500 baud
 * Ctrl Key simulates shift-DownArrow
 
## Notes:
 * The included BOOT.ROM has been modified to take advantage of a special interface for loading cassettes; original BASIC ROMs are also supported
 * Simulates Percom Doubler and TRS-80DD, but the upcoming JV3 decoding will be required to use DD disk images (disabled for now)
 * Even though sector write operations are supported, formatting of disks is not.
 * Prefer keyboard "TRS80" mapping for games, and reserve "PC" mapping for desktop apps. The latter may misbehave when several keys are pushed at the same time.

## S80 improved keyin routine
 The included ROM contains Dick Smith System80 improved keyin routine at /12288; load with "SYSTEM" then "/12288" at the \*? prompt. Refer to the System80 manual for details about this.

## Hidden debugger in the ROM 
 * The debugger can be loaded with "SYSTEM" then "/12710" at the prompt; it is very primitive and cannot trace, step or break, it allows only to examine memory and registers, then jump somewhere.
 * commands are :
   * R : modify registers (next with X)
   * D : dump memory (up and down arrow to navigate, X to exit)
   * B : back to basic
   * M : modify memory
   * G : to jump to an address

## Technical:
Debug status line
 * The Debug Status line will only be visible in Partial or Full overscan modes
   * For monitoring Floppy Disk Controller (FDC)
   * Usess the following format: Ddddd,Ccc,Ttt,Sss,dnn,sSS,Xdxx \* where:
     * dddd - Drive select latch (1-4).  Only 2 drives are currently supported
     * cc   - FDC Command Register
     * tt   - FDC Track Register
     * ss   - FDC Sector Register
     * nn   - FDC Data Register
     * SS   - FDC Status Register
     * dxx  - d:  8=err data lost 4=err RNF 2=ctrl type 1=track mismatch
            - xx: max number of data lost by CPU (but recovered)
     * \*   - RTC Second Timer


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

 * Holmes Sprinter Interface
   * OUT 254, n - Even number = Override Turbo.  Odd number = Enable Turbo

Special memory mapped ports have been added as follows:

* TRS-80 DD Interface - Memory mapped interface
    * 0x37ec = 0x80 - Enable Double Density Mode  (disabled for now)
    * 0x37ec = 0xa0 - Disable Double Density Mode
