IEC_FIRST_DEVICE = 8
IEC_LAST_DEVICE = 16

.section code

; -------------------------------------------------------
; Clock driver API
; -------------------------------------------------------

; Detect and register IEC devices with RTC.
; Arguments: -
; Returns: -
.public clock_iec_detect {
    ldx #IEC_FIRST_DEVICE
loop:
    stx clock_iec_info
    txa
    jsr iec_command_open
    cmp #0
    bne :+
    lda clock_iec_info
    jsr check_iec_device
    lda clock_iec_info
    jsr iec_command_close
:   ldx clock_iec_info
    inx
    cpx #IEC_LAST_DEVICE + 1
    bcc loop
    rts
}

; Open clock.
; Arguments:
;   A: clock parameter (device id)
;   X: clock index
; Returns: -
.public clock_iec_open {
    tax
    jmp iec_command_open
}


; Close clock.
; Arguments:
;   A: clock parameter (device id)
;   X: clock index
; Returns: -
.public clock_iec_close = iec_command_close


; Read clock.
; Arguments:
;   A: clock parameter (device id)
;   X: clock index
; Returns: -
.public clock_iec_read {
    ldx #<iec_command_read
    ldy #>iec_command_read
    jsr iec_command_send
    ldx clocks_current
    bcc :+
error:
    lda #CLOCK_STATUS_ERROR
    sta status,x
    rts
:   lda iec_response_length
    cmp #8
    bne error

    lda iec_response
    sta weekday,x
    lda iec_response + 1
    sta year,x
    lda iec_response + 2
    sta month,x
    lda iec_response + 3
    sta day,x
    lda iec_response + 4
    sta hour,x
    lda iec_response + 5
    sta minute,x
    lda iec_response + 6
    sta second,x
    lda iec_response + 7
    sta am_pm,x
    rts
}

; -------------------------------------------------------
; helper routines
; -------------------------------------------------------


; Check if IEC device has an RTC and register as clock if it does.
; Arguments:
;   A: device id
; Returns: -
; Preserves: -
check_iec_device {
    ldx #<iec_command_read
    ldy #>iec_command_read
    jsr iec_command_send
    bcs end
    lda iec_response_length
    cmp #8
    beq :+
end:
    rts
:   ldx #<iec_command_ui
    ldy #>iec_command_ui
    lda clock_iec_info
    jsr iec_command_send
    bcs no_name

    ldx #0
cmp_name:
    lda identities,x
    sta ptr
    lda identities + 1,x
    sta ptr + 1
    ldy #0
cmp_char:
    lda (ptr),y
    bne :+
    lda names,x
    ldy names + 1,x
    tax
    jmp register
:   cmp iec_response + 3,y
    bne :+
    iny
    bne cmp_char
:   inx
    inx
    cpx names_count * 2
    bne cmp_name

no_name:
    ldx #<name_unknown
    ldy #>name_unknown
register:
    stx clock_iec_info + 2
    sty clock_iec_info + 3
    ldx #<clock_iec_info
    ldy #>clock_iec_info
    jmp clock_register
}


.section data

empty_name {
    .data 0
}

iec_command_ui {
    .data "ui", $d, 0
}
iec_command_read {
    .data "t-rb", $d, 0
}

identities {
    .data identity_cmd_fd
    .data identity_cmd_hd
    .data identity_ide64
    .data identity_sd2iec
}

identity_cmd_fd {
    .data "cmd fd",0
}

identity_cmd_hd {
    .data "cmd hd",0
}

identity_ide64 {
    .data "ide64",0
}

identity_sd2iec {
    .data "sd2iec",0
}

names {
    .data name_cmd_fd
    .data name_cmd_hd
    .data name_ide64
    .data name_sd2iec
}

names_count = .sizeof(names) / 2

name_unknown {
    .data "Drive":screen, 0
}

name_cmd_fd {
    .data "CMD FD":screen, 0
}

name_cmd_hd {
    .data "CMD HD":screen, 0
}

name_ide64 {
    .data "IDE64":screen, 0
}

name_sd2iec {
    .data "SD2IEC":screen, 0
}

clock_iec_info {
    .data $08 ; parameter
    .data CLOCK_FLAG_WEEKDAY ; flags
    .data name_unknown ; name
    .data clock_iec_open ; open
    .data clock_iec_read ; read
    .data clock_iec_close ; close
}

.section reserved

iec_tmp .reserve 1

.section zero_page

ptr .reserve 2
ptr2 .reserve 2
