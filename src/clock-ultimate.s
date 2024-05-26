; clock-ultimate.s -- clock driver for Ultimate 64 and Ultimate II+
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

; Detect Ultimate Command Interface and register as clock if found.
; Arguments: -
; Returns: -
.public clock_ultimate_detect {
    lda #CLOCK_PARAMETER_NONE
    load_word clock_ultimate_name
    jsr display_scanning
    jsr ultimate_ci_detect
    bne :+
    ldx #<clock_ultimate_info
    ldy #>clock_ultimate_info
    jsr clock_register
:   rts
}


; Read clock.
; Arguments:
;   A: clock parameter (not used)
;   X: clock index
; Returns: -
clock_ultimate_read {
    lda #CLOCK_STATUS_ERROR
    sta clock_status
    rts ; TODO: fix and reenable
    ldx #<ultimate_command
    ldy #>ultimate_command
    lda .sizeof(ultimate_command)
    clc
    jsr ultimate_ci_send_command
    jsr ultimate_ci_check_status
    beq :+
    lda #1
    ldx clocks_current
    sta clock_status
    rts
:   ldx #<ultimate_data
    ldy #>ultimate_data
    lda .sizeof(ultimate_data)
    clc
    jsr ultimate_ci_read_response
    ; TODO: check for end of data, correct length?

    lda #0
    sta clock_weekday ; TODO: convert weekday
    ldy #4
    jsr convert_ascii
    sta clock_century
    jsr convert_ascii
    sta clock_year
    iny
    jsr convert_ascii
    sta clock_month
    iny
    jsr convert_ascii
    sta clock_day
    iny
    jsr convert_ascii
    sta clock_hour
    iny
    jsr convert_ascii
    sta clock_minute
    iny
    jsr convert_ascii
    sta clock_second
    rts
}

; -------------------------------------------------------
; helper routines
; -------------------------------------------------------

convert_ascii {
    lda ultimate_data,y
    iny
    asl
    asl
    asl
    asl
    sta fast_tmp
    lda ultimate_data,y
    iny
    and #$0f
    ora fast_tmp
    rts
}

.section data

clock_ultimate_info {
    .data $ff ; parameter
    .data CLOCK_FLAG_CENTURY | CLOCK_FLAG_24_HOURS | CLOCK_FLAG_WEEKDAY ; flags
    .data clock_ultimate_name
    .data $0000 ; open
    .data clock_ultimate_read ; read
    .data $0000 ; close
}

clock_ultimate_name {
    .data "ultimate":screen, 0
}

ultimate_command {
    .data ULTIMATE_CI_TARGET_DOS, ULTIMATE_CI_DOS_COMMAND_GET_TIME, 1
}

.section reserved

ultimate_data .reserve 24