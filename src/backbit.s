.pre_if .defined(VIC20)
BACKBIT_CODE = $9800
BACKBIT_DATA = $9C00
.pre_else
BACKBIT_CODE = $DE00
BACKBIT_DATA = $DF00
.pre_end
BACKBIT_CONTROL = BACKBIT_CODE
BACKBIT_PARAMETERS = BACKBIT_DATA

; read access
BACKBIT_IDENTIFIER = BACKBIT_CONTROL
  BACKBIT_IDENTIFIER_1 = $ba
  BACKBIT_IDENTIFIER_2 = $cb
  BACKBIT_IDENTIFIER_3 = $17
BACKBIT_DEVICE_NUMBER_FILTER = BACKBIT_CONTROL + $ff

; ASCII
BACKBIT_RTC = BACKBIT_DATA
BACKBIT_RTC_YEAR = BACKBIT_RTC
BACKBIT_RTC_MONTH = BACKBIT_RTC + $04
BACKBIT_RTC_DAY = BACKBIT_RTC + $06
; BCD
BACKBIT_RTC_SUB_SECOND = BACKBIT_RTC + $08
BACKBIT_RTC_SECOND = BACKBIT_RTC + $09
BACKBIT_RTC_MINUTE = BACKBIT_RTC + $0a
BACKBIT_RTC_HOUR = BACKBIT_RTC + $0b
; signed
BACKBIT_RTC_TIMEZONE = BACKBIT_RTC + $0c

; write access
BACKBIT_DISABLE = BACKBIT_CONTROL + $00
BACKBIT_ENABLE = BACKBIT_CONTROL + $01
BACKBIT_MENU = BACKBIT_CONTROL + $02
BACKBIT_LED = BACKBIT_CONTROL + $03
BACKBIT_SET_RTC = BACKBIT_CONTROL + $04
BACKBIT_GET_RTC = BACKBIT_CONTROL + $05
BACKBIT_ROTATE_DISKS = BACKBIT_CONTROL + $06
BACKBIT_MOUNT_CRT = BACKBIT_CONTROL + $07
BACKBIT_READ_SECTOR = BACKBIT_CONTROL + $10
BACKBIT_WRITE_SECTOR = BACKBIT_CONTROL + $11
BACKBIT_WRITE_SECTOR_CONTINUE = BACKBIT_CONTROL + $12
BACKBIT_READ_DATA_8 = BACKBIT_CONTROL + $D0
BACKBIT_READ_DATA_16 = BACKBIT_CONTROL + $D1
BACKBIT_READ_DATA_24 = BACKBIT_CONTROL + $D2
BACKBIT_READ_DATA_32 = BACKBIT_CONTROL + $D3
BACKBIT_WRITE_DATA_OFFSET = BACKBIT_CONTROL + $D4
BACKBIT_WRITE_DATA = BACKBIT_CONTROL + $D5

BACKBIT_COMMAND_SUFFIX = BACKBIT_DATA + $BB
