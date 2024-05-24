; iec.s -- IEC helper routines

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
; API
; -------------------------------------------------------


; Open IEC device's command channel.
; Arguments:
;   A: logical file number
;   X: device id
; Returns:
;   A: status, 0 on success
.public iec_command_open {
    txa
    ldy #15
    jsr SETLFS
    ldx #<iec_empty_name
    ldy #>iec_empty_name
    lda #0
    jsr SETNAM
    jsr OPEN
    jsr READST
    rts
}

; Close IEC device's command channel.
; Arguments:
;   A: logical file number
; Returns:
;   C: set on error
.public iec_command_close = CLOSE


; Send command to IEC device and read response into iec_response, storing it's length in iec_response_length.
; Arguments:
;   A: logical file number
;   X/Y: address of command message
; Returns:
;   C: set on error
.public iec_command_send {
    sta iec_current_file
    stx ptr
    sty ptr + 1

    tax
    jsr CHKOUT
    bcs end
    jsr iec_print_message
    bcs end
    jsr CLRCHN

    ldx iec_current_file
    jsr CHKIN
    bcs end

    lda #<iec_response
    sta ptr
    lda #>iec_response
    sta ptr + 1
    jsr iec_read_message
    bcs end
    jsr CLRCHN
    clc
end:
    rts
}

; -------------------------------------------------------
; Helper Routines
; -------------------------------------------------------

; Print message at ptr to active output channel.
; Arguments: -
; Returns:
;   C: set on error
iec_print_message {
    ldy #0
:   lda (ptr),y
    beq done
    jsr CHROUT
    bcs end
    iny
    bne :-
done:
    clc
end:
    rts
}

; Print message at ptr1 to active output channel.
; Arguments: -
; Returns:
;   C: set on error
iec_read_message {
    ldy #0
:   jsr CHRIN
    bcs end
    cmp #$0d ; TODO: detect end of message
    beq done
    sta (ptr),y
    iny
    bne :-
done:
    sty iec_response_length
    clc
end:
    rts
}

.section data

iec_empty_name {
    .data 0
}

.section reserved

.public iec_response .reserve 256
.public iec_response_length .reserve 1
iec_current_file .reserve 1
