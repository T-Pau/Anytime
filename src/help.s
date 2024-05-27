; help.s -- Display help pages
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

HELP_SCREEN_TITLE_OFFSET = 1
HELP_SCREEN_TEXT_OFFSET = 81

HELP_KEY_RETURN = $5f
HELP_KEY_NEXT_1 = $20
HELP_KEY_NEXT_2 = $2b
HELP_KEY_PREVIOUS = $2d

.section reserved

help_current_page .reserve 1

.section code

help {
    jsr display_help
    ldx #0
    jsr help_display_page
    load_word help_commands
    lda #.sizeof(help_commands)
    jsr command_set_table
loop:
    jsr command_handle
    jmp loop
}


; Return to program.
help_return {
    ; We won't return.
    pla
    pla
    jmp main
}

; Display help page.
; Arguments:
;   X: page to display
help_display_page {
    stx help_current_page
    txa
    asl
    tax
    lda help_screens,x
    sta source_ptr
    lda help_screens + 1,x
    sta source_ptr + 1
    store_word destination_ptr, screen + HELP_SCREEN_TITLE_OFFSET
    jsr rl_expand
    store_word destination_ptr, screen + HELP_SCREEN_TEXT_OFFSET
    jmp rl_expand
}

; Go to next help page.
help_next_page {
    ldx help_current_page
    inx
    cpx help_screens_count
    bne :+
    ldx #0
:   jmp help_display_page
}

; Go to previous help page.
help_previous_page {
    ldx help_current_page
    dex
    cpx #$ff
    bne :+
    ldx help_screens_count
    dex
:   jmp help_display_page
}

.section data

help_commands {
    .data $5f, help_return ; '←'
    .data $20, help_next_page ; ' '
    .data $2b, help_next_page ; '+'
    .data $2d, help_previous_page ; '-'
}