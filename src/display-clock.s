.section code

.public display_clock {
    lda #$20
    ldy #13
    sta (screen_ptr),y
    iny
    sta (screen_ptr),y
    ldy #0
    sta (screen_ptr),y
    iny
    sta (screen_ptr),y
    iny
    jmp display_clock_common
}
.private display_clock_common {
    lda day,x
    jsr display_bcd
    lda #$2d
    sta (screen_ptr),y
    iny
    lda month,x
    jsr display_bcd
    lda #$2d
    sta (screen_ptr),y
    iny
    lda century,x
    jsr display_bcd
    lda year,x
    jsr display_bcd

    ldy #43
    lda hour,x
    jsr display_bcd
    lda #$3a
    sta (screen_ptr),y
    iny
    lda minute,x
    jsr display_bcd
    lda #$3a
    sta (screen_ptr),y
    iny
    lda second,x
    jmp display_bcd
}

.public display_clock_weekday {
    stx display_tmp
    ldy #0
    lda weekday,x
    asl
    asl
    tax
    lda weekdays,x
    sta (screen_ptr),y
    iny
    lda weekdays + 1,x
    sta (screen_ptr),y
    iny
    lda weekdays + 2,x
    sta (screen_ptr),y
    iny
    iny
    ldx display_tmp
    jmp display_clock_common
}

.public display_bcd {
    sta display_tmp
    lsr
    lsr
    lsr
    lsr
    ora #$30
    sta (screen_ptr),y
    iny
    lda display_tmp
    and #$0f
    ora #$30
    sta (screen_ptr),y
    iny
    rts
}

.section data

weekdays {
    .data "sun":screen, 0
    .data "mon":screen, 0
    .data "tue":screen, 0
    .data "wed":screen, 0
    .data "thu":screen, 0
    .data "fri":screen, 0
    .data "sat":screen, 0
    .data "sun":screen, 0
}

.section zero_page

display_tmp .reserve 1