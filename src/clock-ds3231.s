; clock-ds3231.s -- clock driver for user port DS3231 module
;
; Copyright (C) Dieter Baron
;
; This file is part of Anytime, a program to manage real time clocks for C64.
; The authors can be contacted at <anytime@tpau.group>.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions
; are met:
; 1. Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
; 2. The names of the authors may not be used to endorse or promote
;    products derived from this software without specific prior
;    written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE AUTHORS "AS IS" AND ANY EXPRESS
; OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
; GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
; IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
; OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
; IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


DS3231_ADDRESS = $68
DS3231_SIZE = 7

DS3231_SECOND = 0
DS3231_MINUTE = 1
DS3231_HOUR = 2
  DS3231_HOURS_12 = $40
  DS3231_PM = $20
DS3231_WEEKDAY = 3
DS3231_DAY = 4
DS3231_MONTH = 5
  DS3231_CENTURY = $80
DS3231_YEAR = 6


.section code

; -------------------------------------------------------
; Clock driver API
; -------------------------------------------------------

; Detect DS3231 at user port register as clock if found.
; Arguments: -
; Returns: -
.public clock_ds3231_detect {
    lda #1
    jsr detect_ds3231
    lda #2
    jsr detect_ds3231
end:
    rts
}


; Read clock.
; Arguments:
;   A: clock parameter (bits used for I2C)
;   X: clock index
; Returns: -
clock_ds3231_read {
    jsr set_ds3231_pins
    jsr read_ds3231
    beq :+
    lda #CLOCK_STATUS_ERROR
    sta clock_status
    rts

:   lda ds3231_data + DS3231_SECOND
    sta clock_second
    lda ds3231_data + DS3231_MINUTE
    sta clock_minute
    lda ds3231_data + DS3231_HOUR
    and #DS3231_HOURS_12
    beq hours_24
    lda ds3231_data + DS3231_HOUR
    and #$1f
    sta clock_hour
    lda ds3231_data + DS3231_HOUR
    and #DS3231_PM
    sta clock_am_pm
    jmp hour_done
hours_24:
    lda ds3231_data + DS3231_HOUR
    and #$3f
    sta clock_hour
    lda #0
    sta clock_am_pm
hour_done:
    lda ds3231_data + DS3231_WEEKDAY
    sec
    sbc #1
    sta clock_weekday
    lda ds3231_data + DS3231_DAY
    sta clock_day
    lda ds3231_data + DS3231_MONTH
    and #$7f
    sta clock_month
    lda ds3231_data + DS3231_YEAR
    sta clock_year
    lda #0
    sta clock_status
    rts
}

; -------------------------------------------------------
; Helper Routines
; -------------------------------------------------------

; Set correct I2C pins
; Read clock data from DS3231 into ds3231_data
; Arguments:
;   A: parameter (bits used for I2C)
set_ds3231_pins {
    tax
    dex
    lda ds3231_sda,x
    ldy ds3231_scl,x
    jmp i2c_set_bits
}

; Read clock data from DS3231 into ds3231_data
; Returns:
;   Z: set on success
read_ds3231 {
    ldx #<ds3231_data
    ldy #>ds3231_data
    lda #DS3231_SIZE
    jsr i2c_prep_rw

    lda #DS3231_ADDRESS
    ldy #0
    clc
    jmp i2c_readreg
}

detect_ds3231 {
    sta clock_ds3231_info
    load_word clock_ds3231_name
    jsr display_scanning
    sta clock_ds3231_info
    jsr set_ds3231_pins
    jsr i2c_init
    bne end
    lda clock_ds3231_info
    jsr read_ds3231
    bne end
    ldx #<clock_ds3231_info
    ldy #>clock_ds3231_info
    jmp clock_register
end:
    rts
}

.section data

clock_ds3231_name {
    .data "ds3231":screen, 0
}

clock_ds3231_info {
    .data $01 ; parameter
    .data CLOCK_FLAG_WEEKDAY ; flags
    .data clock_ds3231_name
    .data $0000 ; open
    .data clock_ds3231_read ; read
    .data $0000 ; close
}

ds3231_sda {
    .data $04, $01
}

ds3231_scl {
    .data $08, $02
}

.section reserved

ds3231_data .reserve DS3231_SIZE
