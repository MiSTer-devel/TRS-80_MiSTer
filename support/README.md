
# Support files for TRS-80_MiSTer

## MrUnzip.CMD (v1.1 for TRSDOS, v1.0 for CP/M Omikron Mapper)

### Object

Based on the public domain version of CPM UNZIP version 1.5.7 https://github.com/agn453/UNZIP-CPM-Z80/blob/master/README.md
This version runs on TRSDOS (and others) and can UnZip files that are injected masquerading as cassette files (\*.CAS)

### How does it work ?

* step 1 : generate ZIP files with files meant to be read by the TRS80. Name the ZIP files SOME_NAME.<b>Z80.CAS</b>
* step 2 : insure that the file is not bigger than 64K and contains only TRS80 files with correct names.
* step 3 : load the Zip file in the core with the OSD "Load .CAS" command
* step 4 : run MrUnzip/cmdi (or MrUnzip.com under CP/M) on the TRS80 using the DSK file provided. Do NOT use the OSD "Load CMD" command ...

### CP/M Version
The directory support/CPM contains a LIGHT version of UNZIP157.COM without the unshrinking algorithm, so it fits into the Omikron Mapper memory.
It also contains a Omikron CP/M version of MrUnzip.com, the same light version with the input file replaced by the MiSTer cassette buffer, so you can import zip file contents directly from the MiSTer SD card into the CP/M virtual drives.

### Notes

* The extension .Z80.CAS is not needed, just the ".CAS" part is important. But it will look prettier like this I believe. You cannot use "ZIP" as this will confuse MiSTer.
* The zip compress algorithm "(un)shrinking" has been removed because of lack of memory. Hopefully most ZIP versions uses deflate by default, and fall back to storing if deflate was disapointing. So it should be compatible enough
* use 12x clock for the TRS, or else it's gonna be slow.
* unzipping does overwrite files. You've been warned.
* Files starting with a number will have their names modified like this : 0->A 1->B 2->C etc ... The First file I tried in my tests was 3D-TicTacToe "3DTTTSQ1/BAS" , well, ... you see.

### License

 The original license of UNZIP CPM apply, (i.e. none).
 https://github.com/agn453/UNZIP-CPM-Z80/blob/master/LICENSE

