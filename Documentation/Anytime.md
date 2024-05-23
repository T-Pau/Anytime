# Anytime

This program automatically detects supported real time clocks connected to your Commodore 64 and continuously displays them.

## Loading the Program

Load the program from the disc image with `LOAD"*",8,1`. On C128 and MEGA65, switch to 64 mode before loading.

## Supported Devices

- BackBit Cartridge
- CMD FD-2000 with Real Time Clock module
- CMD FD-4000
- CMD HD
- CMD RAMLink
- CMD SmartMouse and SmartTrack
- IDE64
- MEGA65
- SD2IEC with Real Time Clock
- User Port DS3231 Real Time Clock Module

### BackBit Cartridge

BackBit connects to the cartridge port. 

Its clock stores the year as four digits, including century but not the current weekday.

### CMD FD-2000 and FD-4000

These floppy drives connect to the IEC bus. The real time clock module is optional on the FD-2000.

Their clocks store the current weekday and the year as two digits without century.

### CMD FD-HD

This hard drive connects to the IEC bus.

Its clock stores the current weekday and the year as two digits without century.

### CMD RAMLink

This RAM disk connects to cartridge port.

Its clock stores the current weekday and the year as two digits without century.

### CMD SmartMouse and SmartTrack 

These mice or trackballs connect to either controller port.

Their clocks store the current weekday and the year as two digits without century.

### IDE64

This hard disk connects to cartridge port.

Its clock stores the current weekday and the year as two digits without century.

### MEGA65

This computer has a built-in clock.

It stores the year as two digits without century. 

### SD2IEC

This drive connects to the IEC bus. Most models don't include a real time clock.

Its clock stores the current weekday and the year as two digits without century.

### User Port DS3231 Real Time Clock Module

This module connects to the user port.

There are two variants supported: 

- #1 can be used together with an RS-232 serial port; it uses pins E and F.

- #2 is compatible with GEOS; it uses pins C and D.

Its clock stores the current weekday and the year as two digits without century.
