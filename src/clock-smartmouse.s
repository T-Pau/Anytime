; clock-smartmouse.s -- clock driver for CMD SmartMouse and SmartTrack
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

.section code

; -------------------------------------------------------
; Clock driver API
; -------------------------------------------------------

; Detect SmartMosue in either controller port and register as clock if found.
; Arguments: -
; Returns: -
.public clock_smartmouse_detect {
    lda #1
    jsr detect_smartmouse
    lda #2
    jsr detect_smartmouse
    rts
}


; Read clock.
; Arguments:
;   A: clock parameter (controller port)
;   X: clock index
; Returns: -
clock_smartmouse_read {
    ldx #<smartmouse_data
    stx ptr
    ldx #>smartmouse_data
    stx ptr + 1
    jsr smartmouse_read_clock

    ldx clocks_current
    lda smartmouse_data + SMARTMOUSE_CLOCK_SECOND
    and #$7f
    sta second,x
    lda smartmouse_data + SMARTMOUSE_CLOCK_MINUTE
    sta minute,x
    lda smartmouse_data + SMARTMOUSE_CLOCK_HOUR
    bpl hours_24
    and #SMARTMOUSE_CLOCK_PM
    sta am_pm,x
    lda smartmouse_data + SMARTMOUSE_CLOCK_HOUR
    and #$1f
    sta hour,x
    jmp hour_done
 hours_24:
    and #$3f
    sta hour,x
    lda #0
    sta am_pm,x
hour_done:
    lda smartmouse_data + SMARTMOUSE_CLOCK_DAY
    sta day,x
    lda smartmouse_data + SMARTMOUSE_CLOCK_MONTH
    sta month,x
    lda smartmouse_data + SMARTMOUSE_CLOCK_WEEKDAY
    sec
    sbc #1
    sta weekday,x
    lda smartmouse_data + SMARTMOUSE_CLOCK_YEAR
    sta year,x
    lda #0
    sta status,x
    rts
}


detect_smartmouse {
    ldx #<smartmouse_data
    stx ptr
    ldx #>smartmouse_data
    stx ptr + 1
    sta clock_smartmouse_info
    jsr smartmouse_read_clock
    ldx #SMARTMOUSE_CLOCK_SIZE - 1
:   lda smartmouse_data,x
    cmp #$ff
    bne found
    dex
    bpl :-
    rts
found:
    ldx #<clock_smartmouse_info
    ldy #>clock_smartmouse_info
    jmp clock_register
}

.section data

clock_smartmouse_name {
    .data "smartmouse":screen, 0
}

clock_smartmouse_info {
    .data $01 ; parameter
    .data CLOCK_FLAG_WEEKDAY ; flags
    .data clock_smartmouse_name
    .data $0000 ; open
    .data clock_smartmouse_read ; read
    .data $0000 ; close
}

.section reserved

smartmouse_data .reserve SMARTMOUSE_CLOCK_SIZE
