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

.segment "ZEROPAGE"
  flappybird_y_coord: .res 1

.segment "CODE"

.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  LDA #$00
  STA OAM_ADDR
  LDA #$02
  STA OAM_DMA

  JSR update_flappybird

  RTI
.endproc

.proc reset_handler
  SEI
  CLD
  LDX #$00
  STX PPU_CTRL
  STX PPU_MASK

  ;
  ; Initialize zero-page
  ;

  LDA #$70
  STA flappybird_y_coord

  JMP main
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
LDA #$40
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
  CPX #$80
  BNE write_ppu_nametable_0_batch_1

;
; Write the PPU nametable 1
;

LDA PPU_STAT

LDA #$26
STA PPU_ADDR
LDA #$40
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
  CPX #$80
  BNE write_ppu_nametable_1_batch_1

;
; Write the PPU attribute table
;

LDA PPU_STAT

LDA #$23
STA PPU_ADDR
LDA #$e0
STA PPU_ADDR

LDX #$00

write_ppu_attribute_table_namespace_0:
  LDA ppu_attribute_table,X
  STA PPU_DATA
  INX
  CPX #$20
  BNE write_ppu_attribute_table_namespace_0

LDA PPU_STAT

LDA #$27
STA PPU_ADDR
LDA #$e0
STA PPU_ADDR

LDX #$00

write_ppu_attribute_table_namespace_1:
  LDA ppu_attribute_table,X
  STA PPU_DATA
  INX
  CPX #$20
  BNE write_ppu_attribute_table_namespace_1

JSR draw_flappybird

vblank_wait:       ; wait for another vblank before continuing
  BIT PPU_STAT
  BPL vblank_wait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPU_CTRL
  LDA #%00011110  ; turn on screen
  STA PPU_MASK

forever:
  JMP forever
.endproc

.proc draw_flappybird
  PHP
  PHA
  TXA
  PHA;
  TYA
  PHA;

  ;       xx00 xx01 xx02 xx03
  ; $02xx $70  $03  $00  $70
  ;
  ;       xx04 xx05 xx06 xx07
  ; $02xx $70  $01  $00  $78
  ;
  ;       xx08 xx09 xx0a xx0b
  ; $02xx $70  $02  $00  $80
  ;
  ;       xx0c xx0d xx0e xx0f
  ; $02xx $78  $10  $00  $70
  ;
  ;       xx10 xx11 xx12 xx13
  ; $02xx $78  $11  $00  $78
  ;
  ;       xx14 xx15 xx16 xx17
  ; $02xx $78  $12  $01  $80
  ;
  ;       │    │    │    └── x-coord
  ;       │    │    └─────── sprite attributes
  ;       │    └──────────── tile number
  ;       └───────────────── y-coord
  ;

  ;
  ; Write FlappyBird y-coordinates
  ;


  LDA flappybird_y_coord

  STA $0200 ; tile 0
  STA $0204 ; tile 1
  STA $0208 ; tile 2

  CLC
  ADC #$08

  STA $020c ; tile 3
  STA $0210 ; tile 4
  STA $0214 ; tile 5

  ;
  ; Write FlappyBird tile numbers
  ;

  LDA #$03
  STA $0201 ; tile 0

  LDA #$01
  STA $0205 ; tile 1

  LDA #$02
  STA $0209 ; tile 2

  LDA #$10
  STA $020d ; tile 3

  LDA #$11
  STA $0211 ; tile 4

  LDA #$12
  STA $0215 ; tile 5

  ;
  ; Write FlappyBird sprite attributes
  ;

  LDA #$00  ; palette 0

  STA $0202 ; tile 0
  STA $0206 ; tile 1
  STA $020a ; tile 2
  STA $020e ; tile 3
  STA $0212 ; tile 4

  LDA #$01  ; palette 1

  STA $0216 ; tile 5

  ;
  ; Write FlappyBird x-coordinates
  ;

  LDA #$70

  STA $0203 ; tile 0
  STA $020f ; tile 3

  LDA #$78

  STA $0207 ; tile 1
  STA $0213 ; tile 4

  LDA #$80

  STA $020b ; tile 2
  STA $0217 ; tile 5

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTS
.endproc

.proc update_flappybird
  PHP
  PHA
  TXA
  PHA;
  TYA
  PHA;

  LDA flappybird_y_coord

  CMP #$bd
  BCS exit_routine ; Exit routine if FlappyBird hit the floor

  CLC
  ADC #$02

  STA flappybird_y_coord

  STA $0200 ; update tile 0
  STA $0204 ; update tile 1
  STA $0208 ; update tile 2

  CLC
  ADC #$08

  STA $020c ; update tile 3
  STA $0210 ; update tile 4
  STA $0214 ; update tile 5

exit_routine:

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTS
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
  .byte $31, $20, $19, $3a ; bg 3 #AECBE9 #ECEEEC #3E6F1D #B4DF98

  .byte $31, $0d, $30, $38 ; fg 0 #AECBE9 #000000 #ECEEEC #CDD083
  .byte $31, $0d, $38, $16 ; fg 1 #AECBE9 #000000 #CDD083 #8C2C26
  .byte $31, $31, $31, $31 ; fg 2 #AECBE9 #AECBE9 #AECBE9 #AECBE9
  .byte $31, $31, $31, $31 ; fg 3 #AECBE9 #AECBE9 #AECBE9 #AECBE9

ppu_nametable_0_batch_0:
  .byte $1b, $1c, $00, $00, $00, $1b, $1c, $00, $00, $00, $1b, $1c, $00, $00, $00, $1b
  .byte $1c, $00, $00, $00, $1b, $1c, $00, $00, $00, $1b, $1c, $00, $00, $00, $1b, $1c
  .byte $15, $15, $1e, $0f, $1f, $15, $15, $1e, $0f, $1f, $15, $15, $1e, $0f, $1f, $15
  .byte $15, $1e, $0f, $1f, $15, $15, $1e, $0f, $1f, $15, $15, $1e, $0f, $1f, $15, $15
  .byte $15, $15, $06, $07, $08, $0e, $15, $06, $07, $08, $0e, $15, $06, $07, $08, $0e
  .byte $15, $06, $07, $08, $0e, $15, $06, $07, $08, $0e, $15, $06, $07, $08, $0e, $15
  .byte $15, $16, $17, $18, $19, $1a, $16, $17, $18, $19, $1a, $16, $17, $18, $19, $1a
  .byte $16, $17, $18, $19, $1a, $16, $17, $18, $19, $1a, $16, $17, $18, $19, $1a, $16
  .byte $09, $0a, $0b, $0c, $0d, $09, $0a, $0b, $0c, $0d, $09, $0a, $0b, $0c, $0d, $09
  .byte $0a, $0b, $0c, $0d, $09, $0a, $0b, $0c, $0d, $09, $0a, $0b, $0c, $0d, $09, $0a
  .byte $04, $04, $04 ,$04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $04, $04, $04 ,$04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $05, $05, $05 ,$05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
  .byte $05, $05, $05 ,$05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
  .byte $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02
  .byte $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02

ppu_nametable_0_batch_1:
  .byte $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03
  .byte $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04

ppu_nametable_1_batch_0:
  .byte $00, $00, $00, $1b, $1c, $00, $00, $00, $1b, $1c, $00, $00, $00, $1b, $1c, $00
  .byte $00, $00, $1b, $1c, $00, $00, $00, $1b, $1c, $00, $00, $00, $1b, $1c, $00, $00
  .byte $1e, $0f, $1f, $15, $15, $1e, $0f, $1f, $15, $15, $1e, $0f, $1f, $15, $15, $1e
  .byte $0f, $1f, $15, $15, $1e, $0f, $1f, $15, $15, $1e, $0f, $1f, $15, $15, $1e, $0f
  .byte $06, $07, $08, $0e, $15, $06, $07, $08, $0e, $15, $06, $07, $08, $0e, $15, $06
  .byte $07, $08, $0e, $15, $06, $07, $08, $0e, $15, $06, $07, $08, $0e, $15, $06, $07
  .byte $17, $18, $19, $1a, $16, $17, $18, $19, $1a, $16, $17, $18, $19, $1a, $16, $17
  .byte $18, $19, $1a, $16, $17, $18, $19, $1a, $16, $17, $18, $19, $1a, $16, $17, $18
  .byte $0b, $0c, $0d, $09, $0a, $0b, $0c, $0d, $09, $0a, $0b, $0c, $0d, $09, $0a, $0b
  .byte $0c, $0d, $09, $0a, $0b, $0c, $0d, $09, $0a, $0b, $0c, $0d, $09, $0a, $0b, $0c
  .byte $04, $04, $04 ,$04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $04, $04, $04 ,$04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $05, $05, $05 ,$05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
  .byte $05, $05, $05 ,$05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
  .byte $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02
  .byte $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02

ppu_nametable_1_batch_1:
  .byte $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03
  .byte $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04


ppu_attribute_table:
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
  ;
  .byte %11110000
  .byte %11110000
  .byte %11110000
  .byte %11110000
  .byte %11110000
  .byte %11110000
  .byte %11110000
  .byte %11110000

  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111

  .byte %01010000
  .byte %01010000
  .byte %01010000
  .byte %01010000
  .byte %01010000
  .byte %01010000
  .byte %01010000
  .byte %01010000

  .byte %01010101
  .byte %01010101
  .byte %01010101
  .byte %01010101
  .byte %01010101
  .byte %01010101
  .byte %01010101
  .byte %01010101

.segment "CHR"
.incbin "graphics.chr"

