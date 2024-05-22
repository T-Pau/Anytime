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
    lda smartmouse_data
    and #$7f
    sta second,x
    lda smartmouse_data + 1
    sta minute,x
    lda smartmouse_data + 2
    bpl hours_24
    and #$20
    sta am_pm,x
    lda smartmouse_data + 2
    and #$1f
    sta hour,x
    bne hour_done
hours_24:
    and #$2f
    sta hour,x
    lda #0
    sta am_pm,x
hour_done:
    lda smartmouse_data + 3
    sta day,x
    lda smartmouse_data + 4
    sta month,x
    lda smartmouse_data + 5
    sec
    sbc #1
    sta weekday,x
    lda smartmouse_data + 6
    sta year,x
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
