.section code

; X: clock index
; A: device ID
.public iec_open {
    txa
    ora #8
    tax
    ldy #15
    jsr SETLFS
    ldx #<empty_name
    ldy #>empty_name
    lda #0
    jsr SETNAM
    jmp OPEN
}

; X: clock index
.public iec_close {
    txa
    ora #8
    jmp CLOSE
}

; X: clock index
; preserves X
.public iec_read {
    stx iec_tmp
    txa
    ora #8
    tax
    jsr CHKOUT
    bcc :+
error:
    lda #1
    sta status,x
    rts
:   ldx #<iec_command_read
    ldy #>iec_command_read
    jsr print_message
    jsr CLRCHN

    lda iec_tmp
    ora #8
    tax
    jsr CHKIN
    bcs error
    ldx iec_tmp
    jsr CHRIN
    sta weekday,x
    lda #$ff
    sta century
    jsr CHRIN
    sta year,x
    jsr CHRIN
    sta month,x
    jsr CHRIN
    sta day,x
    jsr CHRIN
    sta hour,x
    jsr CHRIN
    sta minute,x
    jsr CHRIN
    sta second,x
    jsr CHRIN
    sta am_pm,x
    jsr CHRIN
    eor #$0d
    sta status,x
    jsr CLRCHN
    ldx iec_tmp
    rts
}

print_message {
    stx ptr
    sty ptr + 1
    ldy #0
:   lda (ptr),y
    beq end
    jsr CHROUT
    iny
    bne :-
end:
    rts
}

.section data

empty_name {
    .data 0
}

iec_command_read {
    .data "t-rb", $d, 0
}

.section reserved

iec_tmp .reserve 1

.section zero_page

ptr .reserve 2