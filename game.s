; vim: set syntax=asm_ca65:

.include "addresses.inc"

; For more details on the iNES header format, see:
; - https://www.nesdev.org/wiki/NES_2.0
; - https://www.nesdev.org/wiki/INES

.segment "HEADER"
  .byte 'N', 'E', 'S', $1A             ; iNES magic number
  .byte $02                            ; 16 KB PRG-ROM
  .byte $01        	                   ; 08 KB CHR-ROM
  .byte $00000001                      ; Vertical mirroring
  .byte $0                             ; NROM
  .byte $0, $0, $0, $0, $0, $0, $0, $0 ; Unused padding

.segment "CODE"

.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  LDA #$00
  STA OAM_ADDR
  LDA #$02
  STA OAM_DMA

gravity:
  LDY $0200
  CPY #$d8
  BCS end_nmi

  TYA
  ADC #3
  STA $0200
  STA $0204
  STA $0208

  LDA $020c
  ADC #3
  STA $020c
  STA $0210
  STA $0214

end_nmi:
  RTI
.endproc

.proc reset_handler
  SEI
  CLD
  LDX #$00
  STX PPU_CTRL
  STX PPU_MASK
.endproc

.proc draw_flappybird
  LDX #$00
  draw_sprites:
    LDA flappybird_sprites,X
    STA $0200,X
    INX
    CPX #$18
    BNE draw_sprites
.endproc

.proc main

;
; write palettes
;

LDX PPU_STAT
LDX #$3f
STX PPU_ADDR
LDX #$00
STX PPU_ADDR

write_palette:
  LDA palettes,X
  STA PPU_DATA
  INX
  CPX #$20
  BNE write_palette

;
; Write the PPU name table 0
;

LDA PPU_STAT

LDA #$22
STA PPU_ADDR
LDA #$80
STA PPU_ADDR

LDX #$00

write_ppu_nametable_0_batch_0:
  LDA ppu_nametable_0_batch_0, X
  STA PPU_DATA
  INX
  BNE write_ppu_nametable_0_batch_0

write_ppu_nametable_0_batch_1:
  LDA ppu_nametable_0_batch_1,X
  STA PPU_DATA
  INX
  CPX #$40
  BNE write_ppu_nametable_0_batch_1

;
; Write the PPU nametable 1
;

LDA PPU_STAT

LDA #$26
STA PPU_ADDR
LDA #$80
STA PPU_ADDR

LDX #$00

write_ppu_nametable_1_batch_0:
  LDA ppu_nametable_1_batch_0,X
  STA PPU_DATA
  INX
  BNE write_ppu_nametable_1_batch_0

write_ppu_nametable_1_batch_1:
  LDA ppu_nametable_1_batch_1,X
  STA PPU_DATA
  INX
  CPX #$40
  BNE write_ppu_nametable_1_batch_1

;
; Write the PPU attribute table
;

LDA PPU_STAT

LDA #$23
STA PPU_ADDR
LDA #$e8
STA PPU_ADDR

LDX #$00

write_ppu_attribute_table:
  LDA ppu_attribute_table,X
  STA PPU_DATA
  INX
  CPX #$18
  BNE write_ppu_attribute_table

forever:
  JMP forever
.endproc

.segment "VECTORS"
.word nmi_handler
.word reset_handler
.word irq_handler

.segment "RODATA"

palettes:
  .byte $31, $3a, $29, $19 ; bg 0 #AECBE9 #B4DF98 #87C03A #3E6F1D
  .byte $31, $19, $27, $37 ; bg 1 #AECBE9 #87C03A #CA8A3A #DFC497
  .byte $31, $3a, $19, $3b ; bg 2 #AECBE9 #B4DF98 #3E6F1D #A8DFB7
  .byte $31, $20, $19, $31 ; bg 3 #AECBE9 #ECEEEC #3E6F1D #AECBE9

  .byte $31, $0d, $30, $38 ; fg 0 #AECBE9 #000000 #ECEEEC #CDD083
  .byte $31, $0d, $38, $16 ; fg 1 #AECBE9 #000000 #CDD083 #8C2C26
  .byte $31, $31, $31, $31 ; fg 2 #AECBE9 #AECBE9 #AECBE9 #AECBE9
  .byte $31, $31, $31, $31 ; fg 3 #AECBE9 #AECBE9 #AECBE9 #AECBE9

flappybird_sprites:
.byte $70, $00, $00, $70
.byte $70, $01, $00, $78
.byte $70, $02, $00, $80
.byte $78, $10, $00, $70
.byte $78, $11, $00, $78
.byte $78, $12, $01, $80
;       │    │    │    └── x-coord
;       │    │    └─────── sprite attributes
;       │    └──────────── tile number
;       └───────────────── y-coord

ppu_nametable_0_batch_0:
  .byte $1b, $1c, $00, $00, $00, $1b, $1c, $00, $00, $00, $1b, $1c, $00, $00, $00, $1b ; $228x
  .byte $1c, $00, $00, $00, $1b, $1c, $00, $00, $00, $1b, $1c, $00, $00, $00, $1b, $1c ; $229x
  .byte $15, $15, $1e, $0f, $1f, $15, $15, $1e, $0f, $1f, $15, $15, $1e, $0f, $1f, $15 ; $22ax
  .byte $15, $1e, $0f, $1f, $15, $15, $1e, $0f, $1f, $15, $15, $1e, $0f, $1f, $15, $15 ; $22bx
  .byte $15, $15, $06, $07, $08, $0e, $15, $06, $07, $08, $0e, $15, $06, $07, $08, $0e ; $22cx
  .byte $15, $06, $07, $08, $0e, $15, $06, $07, $08, $0e, $15, $06, $07, $08, $0e, $15 ; $22dx
  .byte $15, $16, $17, $18, $19, $1a, $16, $17, $18, $19, $1a, $16, $17, $18, $19, $1a ; $22ex
  .byte $16, $17, $18, $19, $1a, $16, $17, $18, $19, $1a, $16, $17, $18, $19, $1a, $16 ; $22fx
  .byte $09, $0a, $0b, $0c, $0d, $09, $0a, $0b, $0c, $0d, $09, $0a, $0b, $0c, $0d, $09 ; $230x
  .byte $0a, $0b, $0c, $0d, $09, $0a, $0b, $0c, $0d, $09, $0a, $0b, $0c, $0d, $09, $0a ; $231x
  .byte $04, $04, $04 ,$04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04 ; $232x
  .byte $04, $04, $04 ,$04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04 ; $233x
  .byte $05, $05, $05 ,$05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05 ; $234x
  .byte $05, $05, $05 ,$05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05 ; $235x
  .byte $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02 ; $236x
  .byte $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02 ; $237x

ppu_nametable_0_batch_1:
  .byte $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03 ; $238x
  .byte $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03 ; $239x
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04 ; $238x
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04 ; $239x

ppu_nametable_1_batch_0:
  .byte $00, $00, $00, $1b, $1c, $00, $00, $00, $1b, $1c, $00, $00, $00, $1b, $1c, $00 ; $268x
  .byte $00, $00, $1b, $1c, $00, $00, $00, $1b, $1c, $00, $00, $00, $1b, $1c, $00, $00 ; $269x
  .byte $1e, $0f, $1f, $15, $15, $1e, $0f, $1f, $15, $15, $1e, $0f, $1f, $15, $15, $1e ; $26ax
  .byte $0f, $1f, $15, $15, $1e, $0f, $1f, $15, $15, $1e, $0f, $1f, $15, $15, $1e, $0f ; $26bx
  .byte $06, $07, $08, $0e, $15, $06, $07, $08, $0e, $15, $06, $07, $08, $0e, $15, $06 ; $26cx
  .byte $07, $08, $0e, $15, $06, $07, $08, $0e, $15, $06, $07, $08, $0e, $15, $06, $07 ; $26dx
  .byte $17, $18, $19, $1a, $16, $17, $18, $19, $1a, $16, $17, $18, $19, $1a, $16, $17 ; $26ex
  .byte $18, $19, $1a, $16, $17, $18, $19, $1a, $16, $17, $18, $19, $1a, $16, $17, $18 ; $26fx
  .byte $0b, $0c, $0d, $09, $0a, $0b, $0c, $0d, $09, $0a, $0b, $0c, $0d, $09, $0a, $0b ; $270x
  .byte $0c, $0d, $09, $0a, $0b, $0c, $0d, $09, $0a, $0b, $0c, $0d, $09, $0a, $0b, $0c ; $271x
  .byte $04, $04, $04 ,$04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04 ; $272x
  .byte $04, $04, $04 ,$04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04 ; $273x
  .byte $05, $05, $05 ,$05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05 ; $274x
  .byte $05, $05, $05 ,$05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05 ; $275x
  .byte $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02 ; $276x
  .byte $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02 ; $277x

ppu_nametable_1_batch_1:
  .byte $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03 ; $278x
  .byte $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03 ; $279x
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04 ; $23ax
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04 ; $23bx


  ; 76 54 32 10
  ; || || || ||
  ; || || || ++-- top left palette
  ; || || ++----- top right palette
  ; || ++-------- bottom left palette
  ; ++----------- bottom right palette
  ;
  ; with:
  ;   - %00 → palette 0
  ;   - %01 → palette 1
  ;   - %10 → palette 2
  ;   - %11 → palette 3
  ;
  ; See: https://www.nesdev.org/wiki/PPU_attribute_tables

  .byte %11111111 ; $23e8
  .byte %11111111 ; $23e9
  .byte %11111111 ; $23ea
  .byte %11111111 ; $23eb
  .byte %11111111 ; $23ec
  .byte %11111111 ; $23ed
  .byte %11111111 ; $23ee
  .byte %11111111 ; $23ef

  .byte %00000000 ; $23f0
  .byte %00000000 ; $23f1
  .byte %00000000 ; $23f2
  .byte %00000000 ; $23f3
  .byte %00000000 ; $23f4
  .byte %00000000 ; $23f5
  .byte %00000000 ; $23f6
  .byte %00000000 ; $23f7

  .byte %01010101 ; $23f8
  .byte %01010101 ; $23f9
  .byte %01010101 ; $23fa
  .byte %01010101 ; $23fb
  .byte %01010101 ; $23fc
  .byte %01010101 ; $23fd
  .byte %01010101 ; $23fe
  .byte %01010101 ; $23ff

.segment "CHR"
.incbin "graphics.chr"

