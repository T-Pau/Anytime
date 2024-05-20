
;mtime($1300).asm

;(mouse time routines for ds1202)

startadr = $1300


 .org startadr
 .obj 'mtime($1300).obj'

mport = $dc01
mpddr = $dc03

mtptr = $fb ;/$fc



;-------------------------------------
;(jump table)
;-------------------------------------
;note: all register contents undefined
;upon return from these routines except
;where noted.


;(rdall/wrall)------------------------
;read/write all 32 bytes of clk & ram
;to buffer @ mtptr. (set mtptr before
;using these routines). wrall
;automatically disables & re-enable
;write protect as required.

 jmp rdall
 jmp wrall

;(rdclk/wrclk)------------------------
;read/write all 8 bytes of clk
;to buffer @ mtptr. (set mtptr before
;using these routines). wrclk
;automatically disables & re-enable
;write protect as required.

 jmp rdclk
 jmp wrclk


;(rdram/wrram)------------------------
;read/write all 24 bytes of ram
;to buffer @ mtptr. (set mtptr before
;using these routines). wrram
;automatically disables & re-enable
;write protect as required.

 jmp rdram
 jmp wrram


;(rdclk1)-----------------------------
;read a single clk byte. call
;with clk byte address (0-7) in .x.
;clk byte is returned in .a

 jmp rdclk1

;(wrclk1)-----------------------------
;write a single clk byte. call
;with clk byte address (0-7) in .x,
;clk byte in .a.
;auto-disables/enables wp

 jmp wrclk1


;(rdram1)-----------------------------
;read a single ram byte. call
;with ram byte address (0-23) in .x.
;ram byte is returned in .a

 jmp rdram1

;(wrram1)-----------------------------
;write a single ram byte. call
;with ram byte address (0-23) in .x,
;ram byte in .a.
;auto-disables/enables wp

 jmp wrram1


;(wpon/wpoff)-------------------------
;use to manually set/clear the write-
;protect bit.

 jmp wpon
 jmp wpoff


;-------------------------------------
;(variables)
;-------------------------------------

*=startadr+$0030

portsv .byt 0
ddrsv .byt 0
iobyt .byt 0
bnum .byt 0
xsave .byt 0


;-------------------------------------
;(application callable routines)
;-------------------------------------


;(main rd/wr routines)

rdall jsr setup
 jsr brclk
 jsr bmp8  ;bmp mtptr +8
 jsr brram
 jsr dec8  ;fix ptr
 jmp exit


wrall jsr setup
 jsr bwclk
 jsr bmp8  ;bmp mtptr +8
 jsr bwram
 jsr dec8 ;fix ptr
 jmp exit


bmp8 lda mtptr
 clc
 adc #08
 sta mtptr
 bcc +
 inc mtptr+1
+ rts

dec8 lda mtptr
 sec
 sbc #08
 sta mtptr
 bcs +
 dec mtptr+1
+ rts


;(read/write 8 clk bytes)-------------

rdclk jsr setup
 jsr brclk
 jmp exit

wrclk jsr setup
 jsr bwclk
 jmp exit


;(read/write 24 ram bytes)------------

rdram jsr setup
 jsr brram
 jmp exit

wrram jsr setup
 jsr bwram
 jmp exit


;(single byte rd/wr commands)---------

rdclk1 jsr setup
 jsr rd1clk
 jmp exit

rdram1 jsr setup
 jsr rd1ram
 jmp exit

wrclk1 jsr setup
 jsr wr1clk
 jmp exit

wrram1 jsr setup
 jsr wr1ram
 jmp exit


;(write protect commands)-------------

wpon jsr setup
 jsr sndwp1
 jmp exit

wpoff jsr setup
 jsr sndwp0
 jmp exit


;-------------------------------------
;(burst read subs)
;-------------------------------------
;have to call setup first


;(read 8 clk bytes)

brclk lda #$bf  ;burst rd clk cmd
 jsr smcom ;send it
 lda #08
 jmp gbyts ;get 8 clk bytes


;(write 8 clk bytes)

bwclk jsr sndwp0;send wpoff cmd
 lda #$be  ;burst wr clk cmd
 jsr smcom ;send it
 lda #08
 jsr sbyts ;write 8 clk byts
 jmp sndwp1;send wpon cmd


;(read 24 ram bytes)

brram lda #$ff  ;burst rd ram cmd
 jsr smcom ;send it
 lda #24
 jmp gbyts ;get 24 ram bytes


;(write 24 ram bytes)

bwram jsr sndwp0;send wpoff cmd
 lda #$fe  ;burst wr ram cmd
 jsr smcom ;send it
 lda #24
 jsr sbyts ;send 24 ram byts
 jmp sndwp1;send wpon cmd


;-------------------------------------
;(read single byte subs)
;-------------------------------------
;enter w/address in .x
;exits w/byte in .a


rd1clk lda #%10000001
 .byt $2c
rd1ram lda #%11000001
 stx xsave
 jsr snd1cm
 jsr gbmb
 pha
 jsr rsthi
 ldx xsave
 pla
 rts

;-------------------------------------
;(write single byte subs)
;-------------------------------------
;enter w/address in .x
;and byte in .a

wr1clk pha
 lda #%10000000
 bne +
wr1ram pha
 lda #%11000000
+ stx xsave
 pha
 jsr sndwp0
 pla
 ldx xsave
 jsr snd1cm
 jsr ioout
 pla
 pha
 jsr sbmb
 jsr rsthi
 jsr ioin
 jsr sndwp1
 ldx xsave
 pla
 rts


snd1cm sta iobyt
 txa
 asl a
 and #%00111110
 ora iobyt
 jmp smcom

;-------------------------------------
;(write protect routines)
;-------------------------------------
;call setup first


sndwp0 lda #$00
 .byt $2c
sndwp1 lda #$80
sndwp pha
 lda #$8e
 jsr smcom
 jsr ioout
 pla
 jsr slbyt
 jmp rsthi


;-------------------------------------
;(low-level routines)
;-------------------------------------

;(send command byte)-------------------
;call 'setup' before using this routine


smcom pha
 jsr rdycom ;ioout
 pla
slbyt jsr sbmb
 jmp ioin


;(read burst mode bytes from ds1202)--
;# of bytes to read in .a.
;call 'smcom' w/approp. cmd
;before using these routines

gbyts sta bnum
 ldy #00
gtt jsr gbmb
 sta (mtptr),y
 iny
 cpy bnum
 bcc gtt

 jmp rsthi


;(send burst mode bytes to ds1202)----
;# of bytes to read in .a.
;call 'smcom' w/approp. cmd
;before using these routines

sbyts sta bnum
 ldy #00
 jsr ioout

stt lda (mtptr),y
 jsr sbmb
 iny
 cpy bnum
 bcc stt

 jsr rsthi
 jmp ioin


;(read single byte frm ds1202)--------
;call 'smcom' w/appropriate command
;first.


gbmb ldx #08
- jsr clklo
 lda mport
 lsr a
 lsr a
 lsr a
 ror iobyt
 jsr clkhi
 dex
 bne -

 lda iobyt
 rts


;(send single byte to ds1202)---------
;call 'smcom' w/appropriate command
;first.

sbmb sta iobyt
 ldx #08
- jsr clklo
 lda #00
 ror iobyt
 rol a
 asl a
 asl a
 ora #%11110001 ;set io bit
 sta mport
 jsr clkhi
 dex
 bne -
 rts


;(get ready for command seq.)---------
;called from 'smcom'


rdycom jsr ioout
 jsr clklo

rstlo lda #%11110111
 .byt $2c
clklo lda #%11111101
 and mport
 sta mport
 rts


;(lowlev port control)----------------
;called from various routines


rsthi lda #%00001000
 .byt $2c
clkhi lda #%00000010
 ora mport
 sta mport
 rts


ioout lda #%00001110
 .byt $2c
ioin lda #%00001010
 sta mpddr
 rts


;(setup ports for ds1202 i/o)---------
;call here as first step to any ds1202
;access.

setup php
 sei
 sta iobyt
 pla
 sta stasav
 lda mport
 sta portsv
 lda mpddr
 sta ddrsv
 lda #%11111111
 sta mport
 lda #%00001010
 sta mpddr
 lda iobyt
 rts

stasav .byt 0

;(exit routine)-----------------------
;jmp here to return to calling program

exit sta iobyt
 lda portsv
 sta mport
 lda ddrsv
 sta mpddr
 lda stasav
 pha
 lda iobyt
 plp
 rts


.end


