; vim: set syntax=asm_ca65:

.include "palette.inc"
.include "addresses.inc"

; For more details on the iNES header format, see:
; - https://www.nesdev.org/wiki/NES_2.0
; - https://www.nesdev.org/wiki/INES

.segment "HEADER"
  .byte 'N', 'E', 'S', $1A             ; iNES magic number
  .byte $02                            ; 16 KB PRG-ROM
  .byte $01        	                   ; 08 KB CHR-ROM
  .byte $0                             ; Horizontal mirroring
  .byte $0                             ; NROM
  .byte $0, $0, $0, $0, $0, $0, $0, $0 ; Unused padding

.segment "CODE"

.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  ; Initiate a high-speed transfer of the 256 bytes from $0200 to $02ff into OAM
  LDA #$00
  STA OAM_ADDR
  LDA #$02
  STA OAM_DMA

  LDX $20
  INX
  STX $20

  RTI
.endproc

.proc reset_handler
  SEI
  CLD
  LDX #$00
  STX PPU_CTRL
  STX PPU_MASK
.endproc

.proc main
preload_bg_palette:
  LDX PPU_STAT
  LDX #$3f ; BG_PALETTE_0 high nibble
  STX PPU_ADDR
  LDX #$00 ; BG_PALETTE_0 low nibble
  STX PPU_ADDR

load_bg_palette:
  LDA bg_palettes,X
  STA PPU_DATA
  INX
  CPX #$0f
  BNE load_bg_palette

preload_fg_palette:
  LDX PPU_STAT
  LDX #$3f ; FG_PALETTE_0 high nibble
  STX PPU_ADDR
  LDX #$10 ; FG_PALETTE_0 low nibble
  STX PPU_ADDR
  LDX #$00

load_fg_palette:
  LDA fg_palettes,X
  STA PPU_DATA
  INX
  CPX #$08
  BNE load_fg_palette

vblankwait:
  BIT PPU_STAT
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPU_CTRL
  LDA #%00011110  ; turn on screen
  STA PPU_MASK

initial_position:
  LDX #70
  STX $20

  LDX #78
  STX $21

LDX #$00

loop:

render_flappy_bird_sprite_top_0:
LDX $20
STX $0200

LDX $00
flappybird_top_0:
  LDA flappybird_sprite_top_0,X
  STA $0201,X
  INX
  CPX #$03
  BNE flappybird_top_0

LDX $20
STX $0204

LDX $00
flappybird_top_1:
  LDA flappybird_sprite_top_1,X
  STA $0205,X
  INX
  CPX #$03
  BNE flappybird_top_1

LDX $20
STX $0208

LDX $00
flappybird_top_2:
  LDA flappybird_sprite_top_2,X
  STA $0209,X
  INX
  CPX #$03
  BNE flappybird_top_2

JMP loop
.endproc

.segment "VECTORS"
.word nmi_handler
.word reset_handler
.word irq_handler

.segment "RODATA"
bg_palettes:
.byte AZURE_3, BLACK_4, GRAY_3,   YELLOW_3 ; bg palette 0
.byte AZURE_3, BLACK_4, YELLOW_3, RED_1    ; bg palette 1
.byte AZURE_3, AZURE_3, AZURE_3,  AZURE_3  ; bg palette 2
.byte AZURE_3, AZURE_3, AZURE_3,  AZURE_3  ; bg palette 3

fg_palettes:
.byte AZURE_3, BLACK_4, GRAY_3,   YELLOW_3 ; fg palette 0
.byte AZURE_3, BLACK_4, YELLOW_3, RED_1    ; fg palette 1
.byte AZURE_3, AZURE_3, AZURE_3,  AZURE_3  ; fg palette 2
.byte AZURE_3, AZURE_3, AZURE_3,  AZURE_3  ; fg palette 3

flappybird_sprite_top_0:
.byte $00, $00, $70

flappybird_sprite_top_1:
.byte $01, $00, $78

flappybird_sprite_top_2:
.byte $02, $00, $80

;       │    │    │    └── x-coord
;       │    │    └─────── sprite attributes
;       │    └──────────── tile number
;       └───────────────── y-coord (dynamic)

flappy_bird_bottom:
.byte       $10, $00, $70
.byte       $11, $00, $78
.byte       $12, $01, $80
;       │    │    │    └── x-coord
;       │    │    └─────── sprite attributes
;       │    └──────────── tile number
;       └───────────────── y-coord (dynamic)

.segment "CHR"
.incbin "graphics.chr"

