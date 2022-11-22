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
  flappybird_y_coord:  .res 1
  ppu_ctrl_settings:   .res 1
  scroll:              .res 1
  pipe_position:       .res 1
  pipe_height:         .res 1
  pipe_height_counter: .res 1

.segment "CODE"

.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  LDA #$00
  STA OAM_ADDR
  LDA #$02
  STA OAM_DMA

  JSR read_controller
  JSR update_flappybird
  JSR scroll_screen

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

  LDA #%10010000
  STA ppu_ctrl_settings

  LDA #$00
  STA scroll

  LDA #$a0
  STA pipe_position

  LDA #$06
  STA pipe_height

  LDA #$00
  STA pipe_height_counter

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

JSR draw_floor_tiles
JSR write_attribute_table

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

.proc spawn_pipe
  PHP
  PHA
  TXA
  PHA;
  TYA
  PHA;

  ;
  ; pipe top sprite 0
  ;

  LDA #$c5
  TAX ; store the calculation on the X register to reuse it later...

  LDY #$00
  STY pipe_height_counter

pipe_height_loop:
  INC pipe_height_counter

  TXA
  SEC
  SBC #$08

  TAX ; store the calculation on the X register to reuse it later...

  ;
  ; pipe base sprite 0
  ;

  STA PIPE_ADDR,Y   ; y-coord
  INY

  LDA #$24          ; tile number
  STA PIPE_ADDR,Y
  INY

  LDA #%00000010    ; sprite attributes
  STA PIPE_ADDR,Y
  INY

  LDA pipe_position ; x-coord
  STA PIPE_ADDR,Y
  INY

  ;
  ; pipe base sprite 1
  ;

  TXA
  STA PIPE_ADDR,Y    ; y-coord
  INY

  LDA #$25
  STA PIPE_ADDR,Y    ; tile number
  INY

  LDA #%00000010
  STA PIPE_ADDR,Y    ; sprite attributes
  INY

  LDA pipe_position
  CLC
  ADC #$08
  STA PIPE_ADDR,Y    ; x-coord
  INY

  ;
  ; pipe base sprite 2
  ;

  TXA
  STA PIPE_ADDR,Y   ; y-coord
  INY

  LDA #$26          ; tile number
  STA PIPE_ADDR,Y
  INY

  LDA #%00000010    ; sprite attributes
  STA PIPE_ADDR,Y
  INY

  LDA pipe_position ; x-coord
  CLC
  ADC #$10
  STA PIPE_ADDR,Y
  INY

  LDA pipe_height_counter
  CMP pipe_height
  BNE pipe_height_loop

  ;
  ; pipe middle sprite 0
  ;

  TXA
  SEC
  SBC #$08
  TAX ; store the calculation on the X register to reuse it later...

  STA $0224         ; y-coord

  LDA #$14          ; tile number
  STA $0225

  LDA #%00000010    ; sprite attributes
  STA $0226

  LDA pipe_position ; x-coord
  STA $0227

  ;
  ; pipe middle sprite 1
  ;

  TXA               ; y-coord
  STA $0228

  LDA #$15          ; tile number
  STA $0229

  LDA #%00000010    ; sprite attributes
  STA $022a

  LDA pipe_position ; x-coord
  CLC
  ADC #$08
  STA $022b

  ;
  ; pipe middle sprite 2
  ;

  TXA               ; y-coord
  STA $022c

  LDA #$16          ; tile number
  STA $022d

  LDA #%00000010    ; sprite attributes
  STA $022e

  LDA pipe_position ; x-coord
  CLC
  ADC #$10
  STA $022f

  ;
  ; pipe top sprite 0
  ;

  TXA
  SEC
  SBC #$08
  TAX

  STA $0218         ; y-coord

  LDA #$04          ; tile number
  STA $0219

  LDA #%00000010    ; sprite attributes
  STA $021a

  LDA pipe_position ; x-coord
  STA $021b

  ;
  ; pipe top sprite 1
  ;

  TXA
  STA $021c         ; y-coord

  LDA #$05          ; tile number
  STA $021d

  LDA #%00000010    ; sprite attributes
  STA $021e

  LDA pipe_position ; x-coord
  CLC
  ADC #$08
  STA $021f

  ;
  ; pipe top sprite 2
  ;

  TXA               ; y-coord
  STA $0220

  LDA #$06          ; tile number
  STA $0221

  LDA #%00000010    ; sprite attributes
  STA $0222

  LDA pipe_position ; x-coord
  CLC
  ADC #$10
  STA $0223

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTS
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
  CMP #$04
  BCS update_flappybird_y_coord

  LDA #$04
  STA flappybird_y_coord

  JMP exit_routine

update_flappybird_y_coord:
  CMP #$b8
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

.proc scroll_screen
  PHP
  PHA
  TXA
  PHA;
  TYA
  PHA;

  ; LDA flappybird_y_coord
  ; CMP #$b8
  ; BCS end_of_scroll_subroutine ; Stop scrolling if FlappyBird hits the floor

  LDA scroll
  CMP #$ff
  BNE set_scroll

flip_nametable:
  LDA ppu_ctrl_settings
  EOR #%00000001
  STA ppu_ctrl_settings

  LDA #$00
  STA scroll

set_scroll:
  INC scroll

  ; set x-scroll
  LDA scroll
  STA PPU_SCROLL

  ; set y-scroll
  LDA #$00
  STA PPU_SCROLL

  LDA ppu_ctrl_settings
  STA PPU_CTRL

end_of_scroll_subroutine:
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTS
.endproc

.proc read_controller
  PHP
  PHA
  TXA
  PHA;
  TYA
  PHA;

  LDA #$01
  STA JOY_1
  LDA #$00
  STA JOY_1

read_a_button:
  LDA JOY_1
  AND #%00000001
  BEQ read_b_button

  LDA flappybird_y_coord
  CLC
  SBC #$03
  STA flappybird_y_coord

read_b_button:
  LDA JOY_1

read_select_button:
  LDA JOY_1

read_start_button:
  LDA JOY_1

read_up_button:
  LDA JOY_1

read_down_button:
  LDA JOY_1

read_left_button:
  LDA JOY_1

read_right_button:
  LDA JOY_1

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTS
.endproc

.proc draw_floor_tiles
  PHP
  PHA
  TXA
  PHA;
  TYA
  PHA;

  LDA PPU_STAT

  LDA #$23
  STA PPU_ADDR
  LDA #$00
  STA PPU_ADDR

  LDX #$00

write_nametable_0:
  LDA floor_tiles,X
  STA PPU_DATA
  INX
  CPX #$c0
  BNE write_nametable_0

  LDA PPU_STAT

  LDA #$27
  STA PPU_ADDR
  LDA #$00
  STA PPU_ADDR

  LDX #$00

write_nametable_1:
  LDA floor_tiles,X
  STA PPU_DATA
  INX
  CPX #$c0
  BNE write_nametable_1

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTS
.endproc

.proc write_attribute_table
  PHP
  PHA
  TXA
  PHA;
  TYA
  PHA;

  LDA PPU_STAT

  LDA #$23
  STA PPU_ADDR
  LDA #$c0
  STA PPU_ADDR

  LDX #$00

write_nametable_0_attributes:
  LDA attribute_table,X
  STA PPU_DATA
  INX
  CPX #$50
  BNE write_nametable_0_attributes

  LDA PPU_STAT

  LDA #$27
  STA PPU_ADDR
  LDA #$c0
  STA PPU_ADDR

  LDX #$00

write_nametable_1_attributes:
  LDA attribute_table,X
  STA PPU_DATA
  INX
  CPX #$50
  BNE write_nametable_1_attributes

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
  .byte $31, $39, $29, $19 ; fg 2 #AECBE9
  .byte $31, $31, $31, $31 ; fg 3 #AECBE9 #AECBE9 #AECBE9 #AECBE9

floor_tiles:
  .byte $05, $05, $05 ,$05, $10, $11, $12, $13, $05, $05, $05, $05, $05, $05, $05, $05
  .byte $05, $05, $05 ,$05, $10, $11, $12, $13, $05, $05, $05, $05, $05, $05, $05, $05

  .byte $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02
  .byte $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02

  .byte $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03
  .byte $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03

  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04

  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04

  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
  .byte $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04

attribute_table:
  ; xx xx xx xx
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
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

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

