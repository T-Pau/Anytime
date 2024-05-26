; clock-mega65.s -- clock driver for MEGA65 computer
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

.cpu "45gs02"

MEGA65_RTC = $0ffd7110

.macro store_32 address, value {
    lda #<value
    sta address
    lda #>value
    sta address + 1
    lda #<(value >> 16)
    sta address + 2
    lda #>(value >> 16)
    sta address + 3
}

.section code

; -------------------------------------------------------
; Clock driver API
; -------------------------------------------------------

; Detect BackBit cartridge and register as clock if found.
; Arguments: -
; Returns: -
.public clock_mega65_detect {
    lda #CLOCK_PARAMETER_NONE
    load_word clock_mega65_name
    jsr display_scanning
    jsr mega65_detect
    bne :+
    load_word clock_mega65_info
    jsr clock_register
:   rts
}


; Read clock.
; Arguments:
;   A: clock parameter (not used)
;   X: clock index
; Returns: -
clock_mega65_read {
    store_32 quad_ptr, MEGA65_RTC
    ldz #0
    jsr read_register
    sta clock_second
    jsr read_register
    sta clock_minute
    jsr read_register
    bmi hours_24
    tay
    and #$1f
    sta clock_hour
    tya
    and #$20
    sta clock_am_pm
    jmp hour_done
hours_24:
    and #$2f
    sta clock_hour
    lda #0
    sta clock_am_pm
hour_done:
    jsr read_register
    sta clock_day
    jsr read_register
    sta clock_month
    jsr read_register
    sta clock_year
    jsr read_register
    sta clock_weekday
    lda #$20
    sta clock_century
    lda #0
    sta clock_status
    rts
}

; -------------------------------------------------------
; helper routines
; -------------------------------------------------------

; Check if running on MEGA65.
; Arguments: -
; Returns:
;   Z: clear if MEGA65 detected
; Preserves: X, Y
mega65_detect {
    lda #1
    sta VIC_SPRITE_0_X
    lda #VIC_KNOCK_IV_1
    sta VIC_KEY
    lda #VIC_KNOCK_IV_2
    sta VIC_KEY
    lda #0
    sta VIC_PALETTE_RED
    lda VIC_SPRITE_0_X
    cmp #1
    rts
}


; Read and debounce clock register from [quad_ptr] and increments Z.
read_register {
:   lda [quad_ptr],z
    cmp [quad_ptr],z
    bne :-
    cmp [quad_ptr],z
    bne :-
    inz
    rts
}


.section data

clock_mega65_info {
    .data $ff ; parameter
    .data CLOCK_FLAG_CENTURY ; flags ; weekday doesn't work, disable for now | CLOCK_FLAG_WEEKDAY
    .data clock_mega65_name
    .data $0000 ; open
    .data clock_mega65_read ; read
    .data $0000 ; close
}

clock_mega65_name {
    .data "MEGA65":screen, 0
}

.section zero_page

quad_ptr .reserve 4
