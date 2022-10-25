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
  RTI
.endproc

.proc reset_handler
  SEI
  CLD
  LDX #$00
  STX PPU_CTRL
  STX PPU_MASK
vblankwait:
  BIT PPU_STAT
  BPL vblankwait
  JMP main
.endproc

.proc main

set_bg:
  LDX PPU_STAT

  LDX #BG_COLOR_HI
  STX PPU_ADDR

  LDX #BG_COLOR_LO
  STX PPU_ADDR

  LDA #AZURE_3
  STA PPU_DATA

  LDA #%00011110
  STA PPU_MASK

forever:
  JMP forever
.endproc

.segment "VECTORS"
.word nmi_handler
.word reset_handler
.word irq_handler

.segment "CHR"
.incbin "graphics.chr"

