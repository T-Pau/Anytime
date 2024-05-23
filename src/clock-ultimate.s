.section code

; -------------------------------------------------------
; Clock driver API
; -------------------------------------------------------

; Detect Ultimate Command Interface and register as clock if found.
; Arguments: -
; Returns: -
.public clock_ultimate_detect {
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
    sta status,x
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
    sta status,x
    rts
:   ldx #<ultimate_data
    ldy #>ultimate_data
    lda .sizeof(ultimate_data)
    clc
    jsr ultimate_ci_read_response
    ; TODO: check for end of data, correct length?

    lda #0
    sta weekday,x ; TODO: convert weekday
    ldy #4
    jsr convert_ascii
    sta century,x
    jsr convert_ascii
    sta year,x
    iny
    jsr convert_ascii
    sta month,x
    iny
    jsr convert_ascii
    sta day,x
    iny
    jsr convert_ascii
    sta hour,x
    iny
    jsr convert_ascii
    sta minute,x
    iny
    jsr convert_ascii
    sta second,x
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