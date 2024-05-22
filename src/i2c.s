; i2c.s - I2C API for C64

; MIT License
; 
; Copyright (c) 2020 Gregory Naçu
; Adapted to Accelerate 2024 Dieter Baron
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

bufptr = $fb

client_timeout  = 50 ;wait time for client to ack the address

datareg  = CIA2_PRB
datadir  = CIA2_DDRB

.section reserved

sda_set .reserve 1
scl_set .reserve 1
sda_clear .reserve 1
scl_clear .reserve 1

i2c_status .reserve 1
i2c_data .reserve 1


; sda_p    = %00000100 ;CIA Port b2 (UP E)
; scl_p    = %00001000 ;CIA Port b3 (UP F)

.section code

; Set bits used by I2C bus.
; Arguments:
;   A: SDA
;   Y: SCL
.public i2c_set_bits {
    sta sda_set
    eor #$ff
    sta sda_clear
    tya
    sta scl_set
    eor #$ff
    sta scl_clear
    rts
}


;response codes
.public ret_ok   = 0 ;Not an error
.public ret_nok  = 1

.public err_sdalo = 2
.public err_scllo = 3

;i2c address flags
writebit = 0    ;in i2c address byte
readbit  = 1    ;in i2c address byte
purebyte = $ff  ;don't modify data byte

.section code 

;-----------------------
;--[ helpers ]----------
;-----------------------

; Delay for 22 cycles.
; Preserves: A, X, Y
delay {
    ; jsr ;6
    nop ;2
    nop ;2
    nop ;2
    nop ;2
    nop ;2
    rts ;6
}

;read/write size and buffer pointer

regsz .reserve 1
regbuf .reserve 2

;device address and register number

addr .reserve 1
reg .reserve 1

;-----------------------
;--[ set data direct ]--
;-----------------------

sda_out {
    lda datadir
    ora sda_set
    sta datadir
    rts
}

sda_in {
    lda datadir
    and sda_clear
    sta datadir
    rts
}    

both_out {
    lda datadir
    ora sda_set
    ora scl_set
    sta datadir
    rts
}

scl_out {
    lda datadir
    ora scl_set
    sta datadir
    rts
}

scl_in {
    lda datadir
    and scl_clear
    sta datadir
    rts
}

;-----------------------
;--[ bit reads ]--------
;-----------------------

; Read SDA.
; Returns:
;   C: bit
; Preserves: X, Y
sda_read {
    lda datareg
    and sda_set
    beq :+
    sec
    rts
:   clc
    rts
}

; Read SDA.
; Returns:
;   C: bit
; Preserves: X, Y
scl_read {
    lda datareg
    and scl_set
    beq :+
    sec
    rts
:   clc
    rts
}

;-----------------------
;--[ bit writes ]-------
;-----------------------

; Write SDA.
; Arguments:
;   C: bit
; Preserves: C, X, Y
sda_write {
    lda datareg
    bcc clr
    ora sda_set
    bne write
clr:
    and sda_clear
write:
    sta datareg
    rts
}


; Write SDA.
; Arguments:
;   C: bit
; Preserves: C, X, Y
scl_write {
    lda datareg
    bcc clr
    ora scl_set
    bne write
clr:
    and scl_clear
write:
    sta datareg
    rts
}

;-----------------------
;--[ bus management ]---
;-----------------------

; Init I2C bus.
; Returns:
;   A: response code
.public i2c_init {
    lda #ret_ok
    sta i2c_status

    ;TODO: does it make sense to
    ;write these before setting
    ;the bits as outputs?

    sec
    jsr sda_write
    jsr scl_write

    jsr both_out

    jsr delay

    jsr sda_in
    jsr scl_in

chksda:
    jsr sda_read
    bcs chkscl

    lda #err_sdalo
    sta i2c_status
    bne init

chkscl:
    jsr scl_read
    bcs init

    lda #err_scllo
    sta i2c_status

init:
    jsr both_out

    sec
    jsr sda_write
    jsr scl_write

    ;Send stop just in case...
    ;st2 = write_stop_bit();
    ;if (i2c_status == RET_OK)
    ;i2c_status = st2;

    lda i2c_status
    rts
}

.public i2c_reset {
    jsr both_out

    jsr delay

    clc
    jsr scl_write

    jsr delay

    sec
    jsr scl_write

    jmp i2c_stop
}

;-----------------------
;--[ bus signaling ]----
;-----------------------

i2c_start {
    jsr both_out

    ;make sure that
    ;sda and scl are high
    sec
    jsr sda_write
    jsr scl_write

    jsr delay

    ;pull down sda while
    ;scl is still high
    clc
    jsr sda_write

    jsr delay

    ;then pull down scl also
    jmp scl_write
}

; Returns:
;   A: ok/nok response
i2c_stop {
    jsr both_out

    clc
    jsr sda_write

    jsr delay

    sec
    jsr scl_write

    jsr delay

    sec
    jsr sda_write

    jsr delay

    jsr sda_in
    jsr scl_out ;TODO: needed?

    ;see if sda really went up or
    ;if client keeps sda low

    jsr sda_read
    bcs ok

    lda #ret_nok
    rts

ok:
    lda #ret_ok
    rts
}

; Send host acknowledge.
i2c_ack {
    jsr both_out

    clc
    jsr sda_write
    sec
    jsr scl_write

    jsr delay

    clc
    jmp scl_write
    ;note: sda and scl are left low
}

; Send host not-acknowledge.
i2c_nack {
    jsr both_out

    sec
    jsr sda_write
    jsr scl_write

    jsr delay

    clc
    jsr scl_write

    jsr delay

    jmp sda_write
    ;note: sda and scl are left low
}

;-----------------------
;--[ byte read ]--------
;-----------------------

; Read byte.
; Returns:
;   A: byte
i2c_readb {
    lda #0    ;initialize data byte
    sta i2c_data

    jsr sda_in
    jsr scl_out

    ldx #7

loop:
    jsr delay

    ;todo: should this be in the loop?
    ;this causes two delays in a row
    ;between loop iterations.

    sec
    jsr scl_write

    jsr delay

    jsr sda_read
    rol i2c_data

    ;carry low from rol
    jsr scl_write

    jsr delay
    dex
    bpl loop

    lda i2c_data
    rts
}

;-----------------------
;--[ byte write ]-------
;-----------------------

;0000000 0 General Call
;0000000 1 Start Byte
;0000001 X CBUS Addresses
;0000010 X Reserved for Diff Bus Formats
;0000011 X Reserved for future purposes
;00001XX X High-Speed Host Code
;11110XX X 10-bit Client Addressing
;11111XX X Reserved for future purposes

;==> Address is 7-bits long.

;List of reserved addresses:
;0,1,2,3,4,5,6,7
;0x78,0x79,0x7A,0x7B,0x7 ,0x7D,0x7E,0x7F

; Write byte.
; Arguments:
;   A: byte
;   X: r/w bit
; Returns:
;   A: ack status
i2c_writeb {
    sta i2c_data

    ;if should write an address,
    ;then rw_bit needs to be added.
    ;otherwise do not shift and no
    ;rw_bit to be added.

    txa
    bmi skiprw

    lsr a    ;rwbit -> c
    rol i2c_data ;data  <- c

skiprw:
    jsr both_out

    ldx #7

loop:
    rol i2c_data
    jsr sda_write

    jsr delay

    sec
    jsr scl_write

    jsr delay

    clc
    jsr scl_write

    jsr delay
    dex
    bpl loop

    ;get client acknowledge

    jsr sda_in
    jsr scl_out ;TODO: needed?

    sec
    jsr sda_write
    jsr scl_write

    ;some chips strangely pull sd low
    ;(client ack already before the clock)

    ;jmp gotack ;assume client ack

    ;TODO: are these necessary?
    ;The pins are already in this
    ;configuration.

    jsr sda_in
    jsr scl_out

    ldx #client_timeout

wait:
    jsr sda_read
    bcc gotack

    jsr delay

    dex
    bne wait

    ;error: wait timeout, no ack.
    lda #ret_nok
    rts

gotack:
    clc
    jsr scl_write

    sec
    jsr sda_write

    jsr both_out

    lda #ret_ok
    rts
}

;-----------------------
;--[ register r/w ]-----
;-----------------------

;call i2c_prep_rw before either a
;read register or a write register
;to setup the buffer pointer and the
;length of data to read or write

; Set buffer address and size.
; Arguments:
;   A: size
;   X/Y: address
.public i2c_prep_rw {
    stx regbuf
    sty regbuf+1

    sta regsz
    rts
}

; Read register.
;   Call i2c_prep_rw first.
; Arguments:
;   A: i2C address
;   Y: device register
;   C: set: skip register write
; Returns:
;   A: response code
.public i2c_readreg {
    sta addr
    sty reg
    bcs skipregw

    ;Some devices support
    ;sequential read with a
    ;pre-defined first address

    jsr i2c_start

    lda addr
    ldx #writebit
    jsr i2c_writeb

    beq :+
    rts ;A <- ret_nok

:   lda reg
    ldx #purebyte
    jsr i2c_writeb
skipregw:

    jsr i2c_start
    lda addr
    ldx #readbit
    jsr i2c_writeb

    ;backup bufptr
    lda bufptr
    pha
    lda bufptr+1
    pha

    ;bufptr <- regbuf
    lda regbuf
    sta bufptr
    lda regbuf+1
    sta bufptr+1

    ldy #0

loop:
    jsr i2c_readb
    sta (bufptr),y

    iny
    cpy regsz
    beq done

    jsr i2c_ack
    jsr delay

    sec
    jsr sda_write

    ;TODO: clock stretching

    bcs loop ;branch always


done:     ;restore bufptr
    pla
    sta bufptr+1
    pla
    sta bufptr

    jsr i2c_nack
    jmp i2c_stop
}


; Write register.
;   Call i2c_prep_rw first.
; Arguments:
;   A: i2C address
;   Y: device register
; Returns:
;   A: response code
i2c_writereg {
    sta addr
    sty reg

    lda #ret_ok
    sta i2c_status

    jsr i2c_start

    lda addr
    ldx #writebit
    jsr i2c_writeb

    lda reg
    ldx #purebyte
    jsr i2c_writeb

    ;backup bufptr
    lda bufptr
    pha
    lda bufptr+1
    pha

    ;bufptr <- regbuf
    lda regbuf
    sta bufptr
    lda regbuf+1
    sta bufptr+1

    ldy #0

loop:
    lda (bufptr),y
    ldx #purebyte
    jsr i2c_writeb

    ora i2c_status

    iny
    cpy regsz
    bne loop

    ;restore bufptr
    pla
    sta bufptr+1
    pla
    sta bufptr

    jsr i2c_stop
    lda i2c_status

    rts
}
