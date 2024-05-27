; screens.s -- library to access Ultimate Command Interface
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

.visibility public

ULTIMATE_CI_TARGET_DOS = $01
ULTIMATE_CI_TARGET_DOS_2 = $02

ULTIMATE_CI_DOS_COMMAND_IDENTIFY = $01
ULTIMATE_CI_DOS_COMMAND_OPEN_FILE = $02
ULTIMATE_CI_DOS_COMMAND_CLOSE_FILE = $03
ULTIMATE_CI_DOS_COMMAND_READ_DATA = $04
ULTIMATE_CI_DOS_COMMAND_WRITE_DATA = $05
ULTIMATE_CI_DOS_COMMAND_FILE_SEEK = $06
ULTIMATE_CI_DOS_COMMAND_FILE_INFO = $07
ULTIMATE_CI_DOS_COMMAND_FILE_STAT = $08
ULTIMATE_CI_DOS_COMMAND_DELETE_FILE = $09
ULTIMATE_CI_DOS_COMMAND_RENAME_FILE = $0a
ULTIMATE_CI_DOS_COMMAND_COPY_FILE = $0b
ULTIMATE_CI_DOS_COMMAND_CHANGE_DIR = $11
ULTIMATE_CI_DOS_COMMAND_GET_PATH = $12
ULTIMATE_CI_DOS_COMMAND_OPEN_DIR = $13
ULTIMATE_CI_DOS_COMMAND_READ_DIR = $14
ULTIMATE_CI_DOS_COMMAND_COPY_US_PATH = $15
ULTIMATE_CI_DOS_COMMAND_CREATE_DIR = $16
ULTIMATE_CI_DOS_COMMAND_COPY_HOME_PATH = $17
ULTIMATE_CI_DOS_COMMAND_LOAD_REU = $21
ULTIMATE_CI_DOS_COMMAND_SAVE_REU = $22
ULTIMATE_CI_DOS_COMMAND_MOUNT_DISK = $23
ULTIMATE_CI_DOS_COMMAND_UMOUNT_DISK = $24
ULTIMATE_CI_DOS_COMMAND_SWAP_DISK = $25
ULTIMATE_CI_DOS_COMMAND_GET_TIME = $26
ULTIMATE_CI_DOS_COMMAND_SET_TIME = $27
ULTIMATE_CI_DOS_COMMAND_ECHO = $f0

ULTIMATE_CI_CONTROL = $df1c
  ULTIMATE_CI_CLEAR_ERROR = $08
  ULTIMATE_CI_ABORT = $04
  ULTIMATE_CI_DATA_ACC = $02
  ULTIMATE_CI_PUSH_COMMAND = $01
ULTIMATE_CI_STATUS = $df1c
  ULTIMATE_CI_DATA_AVAILABLE = $80
  ULTIMATE_CI_STATUS_AVAILABLE = $40
  ULTIMATE_CI_STATE(b) = (b & $3) << 4
  ULTIMATE_CI_STATE_MASK = ULTIMATE_CI_STATE($3)
  ULTIMATE_CI_STATE_IDLE = ULTIMATE_CI_STATE(0)
  ULTIMATE_CI_STATE_COMMAND_BUSY = ULTIMATE_CI_STATE(1)
  ULTIMATE_CI_STATE_DATA_LAST = ULTIMATE_CI_STATE(2)
  ULTIMATE_CI_STATE_DATA_MORE = ULTIMATE_CI_STATE(3)
  ULTIMATE_CI_ERROR = $08
  ULTIMATE_CI_COMMAND_BUSY = $01
ULTIMATE_CI_COMMAND = $df1d
ULTIMATE_CI_IDENTIFICATION = $df1d
  ULTIMATE_CI_IDENTIFICATION_VALUE = $c9
ULTIMATE_CI_RESPONSE_DATA = $df1e
ULTIMATE_CI_STATUS_DATA = $df1f

.visibility private

.section code

; Detects if Ultimate Command Interafce is avaialble
; Returns:
;   Z: clear if detected
.public ultimate_ci_detect {
    lda ULTIMATE_CI_IDENTIFICATION
    cmp #ULTIMATE_CI_IDENTIFICATION_VALUE
    bne end
    lda ULTIMATE_CI_STATUS
    and #ULTIMATE_CI_ERROR
    beq :+
    lda #ULTIMATE_CI_CLEAR_ERROR
    sta ULTIMATE_CI_CONTROL
:   lda ULTIMATE_CI_STATUS
    and #ULTIMATE_CI_STATE_MASK
    beq :+
    lda #ULTIMATE_CI_ABORT
    sta ULTIMATE_CI_CONTROL
    ldx #0
:   nop
    lda ULTIMATE_CI_STATUS
    and #ULTIMATE_CI_ABORT
    beq aborted
    dex
    bne :-
    beq end
aborted:
    lda ULTIMATE_CI_STATUS
end:
    rts
}

; Sends command to CI and read status.
; Arguments:
;   A/C: length
;   X/Y: pointer to command
.public ultimate_ci_send_command {
    jsr setup_buffer
loop:
    lda (ptr),y
    sta ULTIMATE_CI_COMMAND
    ldx ptr + 1
    iny
    bne :+
    inx
    stx ptr + 1
:   cpx buffer_end + 1
    bne loop
    cpy buffer_end
    bne loop

    lda #ULTIMATE_CI_PUSH_COMMAND
    sta ULTIMATE_CI_CONTROL

:   lda ULTIMATE_CI_STATUS
    and #ULTIMATE_CI_STATE_MASK
    cmp #ULTIMATE_CI_STATE_COMMAND_BUSY
    beq :-

    ldy #0
:   lda ULTIMATE_CI_STATUS
    and #ULTIMATE_CI_STATUS_AVAILABLE
    beq done
    lda ULTIMATE_CI_STATUS_DATA
    sta ultimate_ci_status,y
    iny
    bne :-
    ldy #255
done:
    lda #0
    sta ultimate_ci_status,y
    sty ultimate_ci_status_length
    rts
}


; Check if status represents success.
; Returns:
;   Z: clear if okay
.public ultimate_ci_check_status {
    lda ultimate_ci_status_length
    beq end
    lda ultimate_ci_status
    cmp #'0'
    bne end
    ldx #1
:   lda ultimate_ci_status,x
    cmp #','
    beq end
    cmp #'0'
    bne end
    inx
    cpx ultimate_ci_status_length
    beq end
    bne :-

end:
    rts
}


; Read resposne data.
; Arguments:
;   A/C: length of buffer
;   X/Y: pointer to buffer
; Returns:
;   A: 0 if more data available
;   X/Y: bytes read
.public ultimate_ci_read_response {
    stx buffer_start
    sty buffer_start + 1
    jsr setup_buffer

    lda #1
    sta end_of_data

    lda ULTIMATE_CI_STATUS
    and #ULTIMATE_CI_STATE_MASK
    beq end

loop:
    lda ULTIMATE_CI_STATUS
    bpl end_packet
    lda ULTIMATE_CI_RESPONSE_DATA
    sta (ptr),y
    ldx ptr + 1
    iny
    bne :+
    inx
    stx ptr + 1
:   cpx buffer_end + 1
    bne loop
    cpy buffer_end
    bne loop
    lda #1
    sta end_of_data
    bne end

end_packet:
    lda #ULTIMATE_CI_DATA_ACC
    sta ULTIMATE_CI_CONTROL

:   lda ULTIMATE_CI_CONTROL
    and #ULTIMATE_CI_STATE_MASK
    beq end
    cmp #ULTIMATE_CI_STATE_COMMAND_BUSY
    beq :-
    bne loop

end:
    tya
    sec
    sbc buffer_start
    tax
    lda ptr + 1
    sbc buffer_start + 1
    tay
    lda end_of_data
    rts
}

; Set up buffer for transfer
; Arguments:
;   A/C: length
;   X/Y: pointer to command
; Returns:
;   Y: low byte of buffer address
setup_buffer {
    stx ptr
    sty ptr + 1
    sta buffer_end
    lda #0
    adc #0
    sta buffer_end + 1
    txa
    adc buffer_end
    sta buffer_end
    tya
    adc buffer_end + 1
    sta buffer_end + 1
    ldy ptr
    lda #0
    sta ptr
    rts
}

.section reserved

.public ultimate_ci_status .reserve 257
.public ultimate_ci_status_length .reserve 1

buffer_start .reserve 2
buffer_end .reserve 2
end_of_data .reserve 1