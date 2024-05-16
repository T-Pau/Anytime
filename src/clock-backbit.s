.section code

backbit_detect {
    lda BACKBIT_IDENTIFIER
    cmp #BACKBIT_IDENTIFIER_1
    bne end
    lda BACKBIT_IDENTIFIER + 1
    cmp #BACKBIT_IDENTIFIER_2
    bne end
    lda BACKBIT_IDENTIFIER + 2
    cmp #BACKBIT_IDENTIFIER_3
end:
    rts
}

read_ascii {
    lda BACKBIT_RTC,y
    iny
    asl
    asl
    asl
    asl
    sta fast_tmp
    lda BACKBIT_RTC,y
    iny
    and #$0f
    ora fast_tmp
    rts
}

.public clock_backbit_detect {
    jsr backbit_detect
    bne :+
    ldx #<clock_backbit_info
    ldy #>clock_backbit_info
    jsr clock_register
:   rts
}

.public clock_backbit_read {
    sta BACKBIT_GET_RTC
    sta BACKBIT_COMMAND_SUFFIX

    lda #$ff
    sta weekday,x
    ldy #0

:   jsr backbit_detect
    bne :-

    sei ; TODO: not needed with own irq routine
    jsr read_ascii
    sta century,x
    jsr read_ascii
    sta year,x
    jsr read_ascii
    sta month,x
    jsr read_ascii
    sta day,x
    lda BACKBIT_RTC_HOUR
    sta hour,x
    lda BACKBIT_RTC_MINUTE
    sta minute,x
    lda BACKBIT_RTC_SECOND
    sta second,x
    lda BACKBIT_RTC_SUB_SECOND
    sta sub_second,x
    cli; TODO: not needed with own irq routine
    rts
}

.section data

clock_backbit_info {
    .data $ff ; parameter
    .data CLOCK_SUB_SECOND ; flags
    .data clock_backbit_name
    .data $0000 ; open
    .data clock_backbit_read ; read
    .data $0000 ; close
}

clock_backbit_name {
    .data "backbit", 0
}

.section zero_page

fast_tmp .reserve 1