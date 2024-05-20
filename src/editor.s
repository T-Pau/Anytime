.section code

.public start {
    ldx #VIC_VIDEO_ADDRESS($400, $2000)
    stx VIC_VIDEO_ADDRESS
    rts
}

.include "charset.s"

.pin charset $2000
.pin charset_inverted $2400
