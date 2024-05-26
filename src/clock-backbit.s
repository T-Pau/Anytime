; clock-backbit.s -- clock driver for BackBit cartridge
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

; Detect BackBit cartridge and register as clock if found.
; Arguments: -
; Returns: -
.public clock_backbit_detect {
    lda #CLOCK_PARAMETER_NONE
    load_word clock_backbit_name
    jsr display_scanning
    jsr backbit_detect
    bne :+
    load_word clock_backbit_info
    jsr clock_register
:   rts
}


; Read clock.
; Arguments:
;   A: clock parameter (not used)
;   X: clock index
; Returns: -
clock_backbit_read {
    sei
    sta BACKBIT_COMMAND_SUFFIX
    sta BACKBIT_GET_RTC

    ldy #0

:   jsr backbit_detect
    bne :-

    jsr read_ascii
    sta clock_century
    jsr read_ascii
    sta clock_year
    jsr read_ascii
    sta clock_month
    jsr read_ascii
    sta clock_day
    lda BACKBIT_RTC_HOUR
    and #$1f
    sta clock_hour
    lda BACKBIT_RTC_HOUR
    and #$80
    sta clock_am_pm
    lda BACKBIT_RTC_MINUTE
    sta clock_minute
    lda BACKBIT_RTC_SECOND
    sta clock_second
    cli
    lda #0
    sta clock_status
    rts
}

; -------------------------------------------------------
; helper routines
; -------------------------------------------------------

; Check if BackBit Cartridge is present.
; Arguments: -
; Returns:
;   Z: clear if BackBit detected
; Preserves: X, Y
backbit_detect {
    lda BACKBIT_IDENTIFIER
    cmp #BACKBIT_IDENTIFIER_1
    bne end
    lda BACKBIT_IDENTIFIER + 1
    cmp #BACKBIT_IDENTIFIER_2
    bne end
    lda BACKBIT_IDENTIFIER + 2
    cmp #BACKBIT_IDENTIFIER_3
end:
    rts
}

read_ascii {
    lda BACKBIT_RTC,y
    iny
    asl
    asl
    asl
    asl
    sta fast_tmp
    lda BACKBIT_RTC,y
    iny
    and #$0f
    ora fast_tmp
    rts
}



.section data

clock_backbit_info {
    .data $ff ; parameter
    .data CLOCK_FLAG_CENTURY ; flags
    .data clock_backbit_name
    .data $0000 ; open
    .data clock_backbit_read ; read
    .data $0000 ; close
}

clock_backbit_name {
    .data "backbit":screen, 0
}

.section zero_page

fast_tmp .reserve 1