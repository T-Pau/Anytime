
DS3231_ADDRESS = $68
DS3231_SIZE = 7


.section code

; -------------------------------------------------------
; Clock driver API
; -------------------------------------------------------

; Detect DS3231 at user port register as clock if found.
; Arguments: -
; Returns: -
.public clock_ds3231_detect {
    lda #1
    jsr detect_ds3231
    lda #2
    jsr detect_ds3231
end:
    rts
}


; Read clock.
; Arguments:
;   A: clock parameter (bits used for I2C)
;   X: clock index
; Returns: -
clock_ds3231_read {
    jsr set_ds3231_pins
    jsr read_ds3231
    beq :+
    ldx clocks_current
    lda #CLOCK_STATUS_ERROR
    sta status,x
    rts

:   ldx clocks_current
    lda ds3231_data
    and #$7f
    sta second,x
    lda ds3231_data + 1
    sta minute,x
    lda ds3231_data + 2
    and #$40
    beq hours_24
    lda ds3231_data + 2
    and #$1f
    sta hour,x
    lda ds3231_data + 2
    and #$20
    sta am_pm,x
    bne hour_done
hours_24:
    lda ds3231_data + 2
    and #$2f
    sta hour,x
    lda #0
    sta am_pm,x
hour_done:
    lda ds3231_data + 3
    sta day,x
    lda ds3231_data + 4
    sta month,x
    lda ds3231_data + 5
    sec
    sbc #1
    sta weekday,x
    ldy #$19
    lda ds3231_data + 6
    sta year,x
    lda ds3231_data + 6
    bpl :+
    iny
:   tya
    sta century,x
    rts
}

; -------------------------------------------------------
; Helper Routines
; -------------------------------------------------------

; Set correct I2C pins
; Read clock data from DS3231 into ds3231_data
; Arguments:
;   A: parameter (bits used for I2C)
set_ds3231_pins {
    tax
    dex
    lda ds3231_sda,x
    ldy ds3231_scl,x
    jmp i2c_set_bits
}

; Read clock data from DS3231 into ds3231_data
; Returns:
;   Z: set on success
read_ds3231 {
    ldx #<ds3231_data
    ldy #>ds3231_data
    lda #DS3231_SIZE
    jsr i2c_prep_rw

    lda #DS3231_ADDRESS
    ldy #0
    clc
    jmp i2c_readreg
}

detect_ds3231 {
    sta clock_ds3231_info
    jsr set_ds3231_pins
    jsr i2c_init
    bne end
    lda clock_ds3231_info
    jsr ds3231_read_clock
    bne end
    ldx #<clock_ds3231_info
    ldy #>clock_ds3231_info
    jmp clock_register
end:
    rts
}

.section data

clock_ds3231_name {
    .data "ds3231":screen, 0
}

clock_ds3231_info {
    .data $01 ; parameter
    .data CLOCK_FLAG_WEEKDAY | CLOCK_FLAG_CENTURY ; flags
    .data clock_ds3231_name
    .data $0000 ; open
    .data clock_ds3231_read ; read
    .data $0000 ; close
}

ds3231_sda {
    .byte $04, $01
}

ds3231_scl {
    .byte $08, $02
}

.section reserved

ds3231_data .reserve DS3231_SIZE
