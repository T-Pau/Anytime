.cpu "45gs02"

MEGA65_RTC = $0ffd7110

.macro store_32 address, value {
    lda #<value
    sta address
    lda #>value
    sta address + 1
    lda #<(value >> 16)
    sta address + 2
    lda #>(value >> 16)
    sta address + 3
}

.section code

; -------------------------------------------------------
; Clock driver API
; -------------------------------------------------------

; Detect BackBit cartridge and register as clock if found.
; Arguments: -
; Returns: -
.public clock_mega65_detect {
    jsr mega65_detect
    bne :+
    ldx #<clock_mega65_info
    ldy #>clock_mega65_info
    jsr clock_register
:   rts
}


; Read clock.
; Arguments:
;   A: clock parameter (not used)
;   X: clock index
; Returns: -
clock_mega65_read {
    store_32 quad_ptr, MEGA65_RTC
    ldz #0
    jsr read_register
    sta second,x
    jsr read_register
    sta minute,x
    jsr read_register
    bmi hours_24
    tay
    and #$1f
    sta hour,x
    tya
    and #$20
    sta am_pm,x
    jmp hour_done
hours_24:
    and #$2f
    sta hour,x
    lda #0
    sta am_pm,x
hour_done:
    jsr read_register
    sta day,x
    jsr read_register
    sta month,x
    jsr read_register
    sta year,x
    jsr read_register
    sta weekday,x
    lda #$20
    sta century,x
    lda #0
    sta status,x
    rts
}

; -------------------------------------------------------
; helper routines
; -------------------------------------------------------

; Check if running on MEGA65.
; Arguments: -
; Returns:
;   Z: clear if MEGA65 detected
; Preserves: X, Y
mega65_detect {
    lda #1
    sta VIC_SPRITE_0_X
    lda #VIC_KNOCK_IV_1
    sta VIC_KEY
    lda #VIC_KNOCK_IV_2
    sta VIC_KEY
    lda #0
    sta VIC_PALETTE_RED
    lda VIC_SPRITE_0_X
    cmp #1
    rts
}


; Read and debounce clock register from [quad_ptr] and increments Z.
read_register {
:   lda [quad_ptr],z
    cmp [quad_ptr],z
    bne :-
    cmp [quad_ptr],z
    bne :-
    inz
    rts
}


.section data

clock_mega65_info {
    .data $ff ; parameter
    .data CLOCK_FLAG_CENTURY ; flags ; weekday doesn't work, disable for now | CLOCK_FLAG_WEEKDAY
    .data clock_mega65_name
    .data $0000 ; open
    .data clock_mega65_read ; read
    .data $0000 ; close
}

clock_mega65_name {
    .data "MEGA65":screen, 0
}

.section zero_page

quad_ptr .reserve 4
