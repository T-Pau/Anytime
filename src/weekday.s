.section code

weekday_calculate {
    ; year + year / 4
    lda clock_year
    jsr unbcd
    bcc :+
invalid:
    lda #8
    rts
:   sta weekday
    and #3
    sta leap
    lda weekday
    lsr
    lsr
    clc
    adc weekday
    sta weekday

    ; month offset
    lda clock_month
    cmp #$13
    bcs invalid
    cmp #$03
    bcs :+
    ldx #0
    stx leap
:   tax
    lda weekday_month,x
    clc
    adc weekday
    sta weekday

    ; day
    lda clock_day
    cmp #$32
    bcs invalid
    jsr unbcd
    bcs invalid
    adc weekday
    sta weekday

    ; century offset
    lda clock_century
    cmp #$19
    bcc invalid
    cmp #$24
    bcs invalid
    sei
    sed
    sec
    sbc #$19
    cld
    cli
    tax
    lda weekday_century,x
    clc
    ldx leap
    beq :+
    sec
:   adc weekday

    ; modulo 7
:   cmp #70
    bcc done_70
    sbc #70
    bcs :-
done_70:
    cmp #7
    bcc done
    sbc #7
    bcs :-
done:
    rts
}

; Convert BCD in A to binary.
; Arguments:
;   A: BCD number
; Returns:
;   A: binary number
;   C: set if BCD invalid
unbcd {
    cmp #$a0
    bcs end
    tay
    lsr
    lsr
    lsr
    lsr
    tax
    lda tens_value,x
    sta add + 1
    tya
    and #$f
    cmp #$a
    bcs end
add:
    adc #$00
end:
    rts
}

.section data

tens_value {
    .repeat i, 10 {
        .data i * 10
    }
}

weekday_month {
    ;     0, J, F, M, A, M, J, J, A, S, a, b, c, d, e, f, O, N, D
    .data 0, 0, 3, 3, 6, 1, 4, 6, 2, 5, 0, 0, 0, 0, 0, 0, 0, 3, 5
}

weekday_century {
    .data 0, 6, 4, 2
}

.section reserved

leap .reserve 1
weekday .reserve 1
