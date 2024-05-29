; clock-wic64.s -- clock driver for WiC64.
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

; Detect WiC64 module and register as clock if found.
; Arguments: -
; Returns: -
.public clock_wic64_detect {
    lda #CLOCK_PARAMETER_NONE
    load_word clock_wic64_name
    jsr display_scanning
    jsr wic64_detect
    bcs :+
    beq :+
    load_word clock_wic64_info
    jsr clock_register
:   rts
}


; Read clock.
; Arguments:
;   A: clock parameter (not used)
;   X: clock index
; Returns: -
clock_wic64_read {
    ; TODO: implement
    rts
}

; -------------------------------------------------------
; helper routines
; -------------------------------------------------------



.section data

clock_wic64_info {
    .data $ff ; parameter
    .data CLOCK_FLAG_CENTURY ; flags
    .data clock_wic64_name
    .data $0000 ; open
    .data clock_wic64_read ; read
    .data $0000 ; close
}

clock_wic64_name {
    .data "WiC64":screen, 0
}
