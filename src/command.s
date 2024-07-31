; command.s -- handle keyboard commands
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

; Set command table.
; Arguments:
;   X/Y: table
;   A: size
command_set_table {
    stx command_ptr
    sty command_ptr + 1
    sta command_size
    rts
}

; Check keyboard and handle command
command_handle {
    jsr GETIN
    beq end
    sta command_key
    ldy #0
loop:
    cmp (command_ptr),y
    bne not
    iny
    lda (command_ptr),y
    iny
    sta command_call
    lda (command_ptr),y
    sta command_call + 1
    lda command_key
    jmp (command_call)
not:
    iny
    iny
    iny
    cpy command_size
    bcc loop
end:
    rts
}

.section zero_page

command_ptr .reserve 2

.section reserved

command_size .reserve 1

command_call .reserve 2
command_key .reserve 1