MAX_CLOCKS = 6

.section code

; X: clock index
; preserves X
clock_normalize {
    lda status,x
    bne end
    lda century,x
    bpl century_ok
    ldy #$20
    lda year,x
    cmp #$70
    bcc :+
    ldy #$19
:   tya
    sta century,x
century_ok:
    lda am_pm,x
    beq end
    lda hour,x
    clc
    sei
    sed
    adc #$12
    cld
    cli
    sta hour,x
end:
    rts
}

.section data

weekday {
    .data 3, 3, 3, 3, 3, 3
}
century {
    .data $20, $20, $20, $20, $20, $20
}

year {
    .data $24, $24, $24, $24, $24, $24
}

month {
    .data $05, $05, $05, $05, $05, $05
}

day {
    .data $15, $15, $15, $15, $15, $15
}

hour {
    .data $13, $12, $13, $13, $13, $13
}

minute {
    .data $05, $45, $05, $05, $05, $05
}

second {
    .data $01, $02, $03, $04, $05, $06
}

.section reserved

am_pm .reserve MAX_CLOCKS
status .reserve MAX_CLOCKS
