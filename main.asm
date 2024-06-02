;***************************�������� ������***************************
;https://radioparty.ru/programming/avr/c/258-lcd-avr-lesson1 
;https://dims.petrsu.ru/posob/avrlab/avrasm-rus.htm
;*********************************************************************

.device ATmega8
.include "m8def.inc"
.ORG 0x00 rjmp RESET
.ORG 0x011 rjmp TWI

;constant for LCD display
.equ E = 2
.equ RS = 1

;define for LCD display
.def data = r22

;define for delay
.def Razr0 = r17 
.def Razr1= r18 
.def Razr2 = r19 

;define for logic
.def end = r21
.def buff = r23
.def numb = r24
.def oper = r25
.def result = r27

.macro lcd_out
   push r16
   ldi r16,@0
   rcall LCD_data

   wait_end_out:
      IN r16,PINC
      andi r16,0b00001111
      ORI r16,0
      BRNE wait_end_out
      
   rcall Del_5ms
   pop r16
.endm

.macro lcd_out_reg
   push r16
   mov r16,@0
   rcall LCD_data

   wait_end_out:
      IN r16,PIND
      ORI r16,0
      BRNE wait_end_out
      
   rcall Del_5ms
   pop r16
.endm

.macro multiplay10
   push r16
   ldi r16,10
   mul numb,r16
   mov numb,r0
   pop r16
.endm

.macro Set_cursor
   push r16 
   ldi r16,(1<<7)|(@0<<6)+@1;������ ������ @0(0-1) ������� @1(0-15)
   rcall LCD_command_4bit 
   rcall Del_5ms
   pop r16
.endm

RESET:
   ldi r16,high(RAMEND)
   out SPH ,r16
   ldi r16,low(RAMEND)
   out SPL ,r16
   
   ldi r16,0b00110000
   out PORTC,r16
   
   ldi r16,254
   out PORTD,r16
   
   ldi r16,0
   out DDRD,r16
  
   sei

Main:
   rcall init_LCD 
   rcall LCD_mod_gui
loop:
   IN r16,PINC
   mov r18,r16
   andi r18,0b00000011
   andi r16,0b00001100
   
   IN r17,PIND
   
   SBRC r17,0
   rjmp line_A

   ldi r17,1
   CPSE r17,r18
   rjmp chek1
   rcall line_B
   chek1:
   
   ldi r17,2
   CPSE r17,r18
   rjmp chek2
   rcall line_C
   chek2:
   
   ldi r17,3
   CPSE r17,r18
   rjmp chek3
   rcall line_D
   chek3:
   
rjmp loop




init_LCD:
   cbr data,E
   SBR data,RS
   
   rcall TWI_Start 
   rcall waitEnd
   rcall Del_500ms
	
   ldi r16, 0b00000011
   rcall LCD_command
	
   ldi r16, 0b00000010
   rcall LCD_command	
	
   ldi r16,0b00101000  
   rcall LCD_command_4bit	
	
   ldi r16,0b00001000 
   rcall LCD_command_4bit 	
	
   ldi r16,0b00000001 
   rcall LCD_command_4bit 
	
   ldi r16,0b00000110 
   rcall LCD_command_4bit 

   ldi r16,0b00001100 
   rcall LCD_command_4bit 

   ldi r16,0b10000000 
   rcall LCD_command_4bit 
ret

LCD_command:
   swap r16
   mov data, r16
   cbr data,RS
   sbr data,E
   rcall TWI_Start 
   rcall waitEnd
   nop
   nop
   nop
   nop
   cbr data,E
   rcall TWI_Start 
   rcall waitEnd
   rcall Del_5ms
ret

LCD_command_4bit:
   mov r20,r16
   mov data,r16
   cbr data,RS
   sbr data,E
   rcall TWI_Start 
   rcall waitEnd
   nop
   nop
   nop
   nop
   cbr data,E
   rcall TWI_Start 
   rcall waitEnd
   nop
   nop
   nop
   nop
   
   swap r20
   mov data,r20
   cbr data,RS
   sbr data,E
   rcall TWI_Start 
   rcall waitEnd
   nop
   nop
   nop
   nop
   cbr data,E
   rcall TWI_Start 
   rcall waitEnd
   rcall Del_5ms
ret


LCD_data:
   mov r20,r16
   mov data,r16
   sbr data,RS
   sbr data,E
   rcall TWI_Start 
   rcall waitEnd
   nop
   nop
   nop
   nop
   cbr data,E
   rcall TWI_Start 
   rcall waitEnd
   nop
   nop
   nop
   nop
   
   swap r20
   mov data, r20
   sbr data,RS
   Sbr data,E
   rcall TWI_Start 
   rcall waitEnd
   nop
   nop
   nop
   nop
   cbr data,E
   rcall TWI_Start 
   rcall waitEnd
   rcall Del_150mks
ret

LCD_mod_gui:
   ldi r16,0x01
   rcall LCD_command_4bit
   
   set_cursor 0,0
   lcd_out 'A'
   lcd_out '4'
   lcd_out '-'
   lcd_out 't'
   lcd_out 'o'
   lcd_out '2'
   lcd_out ' '
   lcd_out ' '
   lcd_out 'B'
   lcd_out '4'
   lcd_out '-'
   lcd_out 't'
   lcd_out 'o'
   lcd_out '1'
   lcd_out '6'  
ret


TWI_Start:
   ldi end,0
   ldi r16, 0b10100101 
   out TWCR, r16 
ret

TWI:
cli 
   in r16,TWSR 
   andi r16, 0xF8 

   cpi r16, 0x08 
   breq SLAW_Adr 

   cpi r16, 0x18 
   breq TWI_SendByte  
rjmp TWI_Stop

SLAW_Adr:
   ldi r16, 0x40 
   out TWDR, r16 
   ldi r16, 0b10000101 
   out TWCR, r16
sei 
reti 

TWI_Stop: 
   ldi r16, 0b00010100
   out TWCR, r16
   ldi end,1
sei 
reti 
  
TWI_SendByte:
   out TWDR, data
   ldi r16, 0b10000101 
   out TWCR, r16
sei 
reti 
   
waitEnd:
   SBRS end,0
   rjmp waitEnd
ret

;***********************************************************************************
;*********************************** KEYPAD*****************************************
;***********************************************************************************

line_A:
   ldi r17,0
   CPSE r17,r16
   rjmp chekB7
   rcall B7
   chekB7:
   
   ldi r17,0b00000100
   CPSE r17,r16
   rjmp chekB8
   rcall B8
   chekB8:
   
   ldi r17,0b00001000
   CPSE r17,r16
   rjmp chekB9
   rcall B9
   chekB9:
   
   ldi r17,0b00001100
   CPSE r17,r16
   rjmp chekBdel
   rcall Bdel
   chekBdel:
rjmp loop

line_B:
   ldi r17,0
   CPSE r17,r16
   rjmp chekB4
   rcall B4
   chekB4:
   
   ldi r17,0b00000100
   CPSE r17,r16
   rjmp chekB5
   rcall B5
   chekB5:
   
   ldi r17,0b00001000
   CPSE r17,r16
   rjmp chekB6
   rcall B6
   chekB6:
   
   ldi r17,0b00001100
   CPSE r17,r16
   rjmp chekBx
   rcall Bx
   chekBx:
   
 
rjmp loop

line_C:

   ldi r17,0
   CPSE r17,r16
   rjmp chekB1
   rcall B1
   chekB1:
   
   ldi r17,0b00000100
   CPSE r17,r16
   rjmp chekB2
   rcall B2
   chekB2:
   
   ldi r17,0b00001000
   CPSE r17,r16
   rjmp chekB3
   rcall B3
   chekB3:
   
   ldi r17,0b00001100
   CPSE r17,r16
   rjmp chekBmin
   rjmp Bmin
   chekBmin:
   
rjmp loop

line_D:
   ldi r17,0
   CPSE r17,r16
   rjmp chekBcl
   rcall Bcl
   chekBcl:
   ldi r17,0b00000100
   CPSE r17,r16
   rjmp chekB0
   rcall B0
   chekB0:
   ldi r17,0b00001000
   CPSE r17,r16   
   rjmp chekBeq
   rjmp Beq
   chekBeq:
   ldi r17,0b00001100
   CPSE r17,r16
   rjmp chekBadd
   rjmp Badd
   chekBadd:
rjmp loop


B0:
   lcd_out '0'
   multiplay10
ret

B1:
   lcd_out '1'
   multiplay10
   inc numb
ret

B2:
   lcd_out '2'
   multiplay10
   inc numb
   inc numb
ret
B3:
   lcd_out '3'
   multiplay10
   ldi r16,3
   add numb,r16
   ldi r16,0
ret

B4:
   lcd_out '4'
   multiplay10
   ldi r16,4
   add numb,r16
   ldi r16,0
ret

B5:
   lcd_out '5'
      multiplay10
   ldi r16,5
   add numb,r16
   ldi r16,0
ret


B6:
   lcd_out '6'
      multiplay10
   ldi r16,6
   add numb,r16
   ldi r16,0
ret

B7:
   lcd_out '7'
      multiplay10
   ldi r16,7
   add numb,r16
   ldi r16,0
ret


B8:
   lcd_out '8'
      multiplay10
   ldi r16,8
   add numb,r16
   ldi r16,0
ret

B9:
   lcd_out '9'
      multiplay10
   ldi r16,9
   add numb,r16
   ldi r16,0
ret
   
Bdel:
   ldi r16,0x01
   rcall LCD_command_4bit
   set_cursor 0,0
   ldi oper,0
   
ldi r16,0
ret

Bx:
   ldi r16,0x01
   rcall LCD_command_4bit
   set_cursor 0,0
   ldi oper,1
   
ldi r16,0
ret

Bmin:
   ldi r16,0x01
   rcall LCD_command_4bit
   Set_cursor 0,0

   lcd_out 'f'
   lcd_out 'r'
   lcd_out 'o'
   lcd_out 'm'
   lcd_out ' '
   lcd_out 't'
   lcd_out 'h'
   lcd_out 'e'
   lcd_out ' '
   lcd_out 'b'
   lcd_out 'u'
   lcd_out 'f'
   lcd_out 'f'
   lcd_out 'e'
   lcd_out 'r'
   lcd_out '#'

   rcall buf_loop
   ldi r16,0
   out PORTB,r16
   CBI PORTD,1

   mov r16,numb
   swap r16
   LSL numb
   LSL numb
   or numb,r16
   out DDRD,numb
   
rcall Del_5ms

   
   in r16,PIND
   in numb,PINB
   andi r16,0b00000010
   mov oper,r16
   LSR oper
   
   ldi r16,0
   out DDRD,r16
rjmp Beq


Bcl:
   ldi r16,0x01
   rcall LCD_command_4bit
   rcall LCD_mod_gui
   ldi numb,0
rjmp loop

Beq:
Set_cursor 1,0
lcd_out 'r'
lcd_out 'e'
lcd_out 's'
lcd_out 'u'
lcd_out 'l'
lcd_out 't'
lcd_out ':'
mov result,numb
   SBRS oper,0
      rjmp to2
   SBRC oper,0
      rjmp to16
rjmp loop

Badd:
   ldi r16,0x01
   rcall LCD_command_4bit
   Set_cursor 0,0
   lcd_out 'a'
   lcd_out 'd'
   lcd_out 'd'
   lcd_out ' '
   lcd_out 't'
   lcd_out 'o'
   lcd_out ' '
   lcd_out 'b'
   lcd_out 'u'
   lcd_out 'f'
   lcd_out 'f'
   lcd_out 'e'
   lcd_out 'r'
   lcd_out '#'
   
   rcall buf_loop
      ldi r16,255
      out PORTB ,r16
      out DDRB,result
      SBI PORTD,1

      mov r16,numb
      swap r16
      LSL r16
      LSL r16
      
      LSL numb
      LSL numb
      or numb,r16
      out DDRD,numb
      
      SBRC oper,0
      SBI DDRD,1

      SBRS oper,0
      CBI DDRD,1
      
      rcall Del_500ms
      
      ldi r16,0
      out DDRD,r16
      ldi r16,0
      out DDRB,r16
rjmp Bcl


buf_loop:
ldi numb,0
   loop2:
      in r16,PINC
      andi r16,0b00001111

      ldi r17,0b00001010
      CPSE r17,r16
      rjmp not3
         ldi numb,3
         rjmp finishLoop2
      not3:

      ldi r17,0b00000110
      CPSE r17,r16
      rjmp not2
         ldi numb,2
         rjmp finishLoop2
      not2:

      ldi r17,0b00000010
      CPSE r17,r16
      rjmp not1
         ldi numb,1
         rjmp finishLoop2
      not1:
   rjmp loop2
   finishLoop2:
ret

buf16:
   ldi r16,0
   chek_numb:
   mov r29,r30
      eor r29,r16
      BREQ out16_numb

      ldi r17,9
      eor r17,r16
      breq chek_but

      inc r16
   rjmp chek_numb

   chek_but:
      mov r29,r30
      eor r29,r16
      BREQ out16_but

      ldi r17,15
      eor r17,r16
      breq en

      inc r16
   rjmp chek_but
en:
ret

out16_numb:
   ldi r17,0b0110000
   add r17,r16
   lcd_out_reg r17
   
ret

out16_but:
   SUBI r16,9
   ldi r17,0b1100000
   add r17,r16
   lcd_out_reg r17
ret

to16:
   mov r30,numb
   ANDI r30,0b11110000
   swap r30
   rcall buf16

   mov r30,numb
   ANDI r30,0b00001111
   rcall buf16
rjmp loop

zero:
   lcd_out '0'
ret

first:
   lcd_out '1'
ret

to2:
   ldi r26,0
   qwe123:
      SBRS numb,7
	rcall zero

      SBRC numb,7
	 rcall first
   next:
      ldi r16,0b00000111
      EOR r16,r26
      BREQ to2_part2
     
      LSL numb
      inc r26
   rjmp qwe123
   
   to2_part2:
      ldi numb,0
rjmp loop

;**************delay(��� 4MHz)****************************************************
Del_150mks:
cli 
   push	Razr0
   ldi	Razr0,200 
Del_50: 	
   dec Razr0
   brne	Del_50
   pop	Razr0
sei 
ret

Del_5ms: 
cli 
   push	Razr0
   push	Razr1
ldi Razr1,high(5000) 
ldi Razr0,low(5000) 
R5_sub: 
 subi Razr0,1 
 sbci Razr1,0
brcc R5_sub
   pop	Razr1
   pop	Razr0
sei 
ret

Del_500ms: 
cli 
   push	Razr0
   push	Razr1
   push	Razr2
   ldi Razr2,byte3(400000) 
   ldi Razr1,high(400000) 
   ldi Razr0,low(400000) 
R200_sub: 
   subi Razr0,1 
   sbci Razr1,0
   sbci Razr2,0
   brcc R200_sub
   pop	Razr2
   pop	Razr1
   pop	Razr0
sei 
ret
;*******************************************************************************************