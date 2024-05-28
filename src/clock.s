; clock.s -- framework for handling clocks
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


CLOCK_WEEKDAY = 0
CLOCK_CENTURY = 1
CLOCK_YEAR = 2
CLOCK_MONTH = 3
CLOCK_DAY = 4
CLOCK_HOUR = 5
CLOCK_MINUTE = 6
CLOCK_SECOND = 7
CLOCK_AM_PM = 8
CLOCK_STATUS = 9
CLOCK_SIZE = 10

MAX_CLOCK_DISPLAYS = 6
MAX_CLOCKS = 16

CLOCK_FLAG_WEEKDAY = $80
CLOCK_FLAG_CENTURY = $40
CLOCK_FLAG_24_HOURS = $20

CLOCK_STATUS_ERROR = $80

CLOCK_PARAMETER_NONE = $ff

.section code

clocks_init {
    lda #0
    sta clocks_count
    sta clocks_active_start
    jsr clock_ultimate_detect
    jsr clock_mega65_detect
    jsr clock_backbit_detect
    jsr clock_iec_detect
    jsr clock_smartmouse_detect
    jsr clock_ds3231_detect

    lda clocks_count
    cmp #MAX_CLOCK_DISPLAYS
    bcc :+
    lda #MAX_CLOCK_DISPLAYS
:   sta clocks_active_count
    rts
}

clocks_init_display {
    lda clocks_count
    bne :+
    store_word source_ptr, no_clocks
    store_word destination_ptr, screen
    jmp rl_expand
:   ldx clocks_active_start
loop:
    cpx clocks_active_count
    bne :+
    rts
:   stx clocks_current
    jsr setup_clock_display
    ldx clocks_current
    lda clocks_open_high,x
    beq no_open
    sta open + 2
    lda clocks_open_low,x
    sta open + 1
    lda clocks_parameter,x
open:
    jsr $1000
no_open:
    ldx clocks_current
    inx
    bne loop
    rts
}

; Close clocks on current page.
; Arguments: -
; Returns: -
clocks_close {
    ldx clocks_active_start
loop:
    cpx clocks_active_count
    bne :+
    rts
:   stx clocks_current
    lda clocks_close_high,x
    beq no_close
    sta close + 2
    lda clocks_close_low,x
    sta close + 1
    lda clocks_parameter,x
close:
    jsr $1000
no_close:
    ldx clocks_current
    inx
    bne loop
    rts
}

clocks_update {
    ldx clocks_active_start
loop:
    cpx clocks_active_count
    bne :+
    rts
:   stx clocks_current
    lda clocks_read_low,x
    sta read + 1
    lda clocks_read_high,x
    sta read + 2
    lda clocks_parameter,x
read:
    jsr $1000
    ldx clocks_current
    jsr clock_normalize
    ldx clocks_current
    jsr display_clock
    ldx clocks_current
    inx
    bne loop
}

; Register clock
; Arguments:
;   X/Y: pointer to clock info
clock_register {
    stx ptr
    sty ptr + 1
    ldx clocks_count
    ldy #0
    lda (ptr),y
    iny
    sta clocks_parameter,x
    lda (ptr),y
    iny
    sta clocks_flags,x
    lda (ptr),y
    iny
    sta clocks_name_low,x
    lda (ptr),y
    iny
    sta clocks_name_high,x
    lda (ptr),y
    iny
    sta clocks_open_low,x
    lda (ptr),y
    iny
    sta clocks_open_high,x
    lda (ptr),y
    iny
    sta clocks_read_low,x
    lda (ptr),y
    iny
    sta clocks_read_high,x
    lda (ptr),y
    iny
    sta clocks_close_low,x
    lda (ptr),y
    iny
    sta clocks_close_high,x
    inx
    stx clocks_count
    rts
}

; Normalize clock based on flags
; Arguments:
;   X: clock index
clock_normalize {
    lda clock_status
    bne end
    lda clocks_flags,x
    and #CLOCK_FLAG_CENTURY
    bne century_ok
    ldy #$20
    lda clock_year
    cmp #$70
    bcc :+
    ldy #$19
:   tya
    sta clock_century
century_ok:
    lda clocks_flags,x
    and #CLOCK_FLAG_WEEKDAY
    bne :+
    jsr weekday_calculate
    bne store_weekday
:   lda clock_weekday
    cmp #7
    bcc :+
    lda #8
store_weekday:
    sta clock_weekday
:   lda clocks_flags,x
    and #CLOCK_FLAG_24_HOURS
    bne end
    lda clock_am_pm
    beq end
    lda clock_hour
    sei
    sed
    clc
    adc #$12
    cld
    cli
    sta clock_hour
end:
    rts
}

.section data

clock_screen_position(row, column) = screen + 40 * (row * 6 + 2) + column * 20 + 3

clocks_screen_position_low {
    .repeat row, 3 {
        .repeat column, 2 {
            .data <clock_screen_position(row, column)
        }
    }
}

clocks_screen_position_high {
    .repeat row, 3 {
        .repeat column, 2 {
            .data >clock_screen_position(row, column)
        }
    }
}

.section reserved

clocks_count .reserve 1
clocks_active_start .reserve 1
clocks_active_count .reserve 1
clocks_current .reserve 1
clocks_read_low .reserve MAX_CLOCKS
clocks_read_high .reserve MAX_CLOCKS
clocks_open_low .reserve MAX_CLOCKS
clocks_open_high .reserve MAX_CLOCKS
clocks_close_low .reserve MAX_CLOCKS
clocks_close_high .reserve MAX_CLOCKS
clocks_name_low .reserve MAX_CLOCKS
clocks_name_high .reserve MAX_CLOCKS
clocks_parameter .reserve MAX_CLOCKS
clocks_flags .reserve MAX_CLOCKS

clock .reserve CLOCK_SIZE
clock_weekday = clock + CLOCK_WEEKDAY
clock_century = clock + CLOCK_CENTURY
clock_year = clock + CLOCK_YEAR
clock_month = clock + CLOCK_MONTH
clock_day = clock + CLOCK_DAY
clock_hour = clock + CLOCK_HOUR
clock_minute = clock + CLOCK_MINUTE
clock_second = clock + CLOCK_SECOND
clock_am_pm = clock + CLOCK_AM_PM
clock_status = clock + CLOCK_STATUS
