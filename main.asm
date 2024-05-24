;***************************ПОЛЕЗНЫЕ ССЫЛКИ***************************
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

.def end = r21
.def buff = r23
.def numb = r24
.def oper = r25

.macro lcd_out
   push r16
   ldi r16,@0
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
   movw numb,r0
   pop r16
.endm

.macro Set_cursor
   push r16 ;чтобы не думать о сохранности temp
   ldi r16,(1<<7)|(@0<<6)+@1;курсор строка @0(0-1) позиция @1(0-15)
   rcall LCD_command_4bit ;
   rcall Del_5ms
   pop r16
.endm

RESET:
   ldi r16,high(RAMEND)
   out SPH ,r16
   ldi r16,low(RAMEND)
   out SPL ,r16
   
   ldi r16,0
   out PORTD,r16
   sei

Main:
   rcall init_LCD 
   rcall LCD_mod_gui
loop:
   IN  r16,PIND
   
   SBRC r16,0
   rjmp line_A

   SBRC r16,1
   rjmp line_B

   SBRC r16,2
   rjmp line_C

   SBRC r16,3
   rjmp line_D
   
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
   ldi r16, 0b10100101 // Запускаем старт, TWINT, TWEN, TWIE - разрешаем интерфейс и прерывания,
   out TWCR, r16 // TWSTA - соответственно стартуем, остальные биты тут = 0
ret

TWI:
cli 
   in r16,TWSR 
   andi r16, 0xF8 

   cpi r16, 0x08 // Если 0x08 - Пришли после старта, далее нам надо выкинуть на шину
   breq SLAW_Adr 

   cpi r16, 0x18 // Если 0x18 - Пришли после посылки адреса микросхемы с записью, далее 
   breq TWI_SendByte  
rjmp TWI_Stop

SLAW_Adr:
   ldi r16, 0x40 // Адрес микросхемы+Запись, бит записи это 0 в самом правом бите
   out TWDR, r16 // Спуливаем на дата регистр
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
   SBRC r16,7
      rcall Bdel
   SBRC r16,6
      rcall B9
   SBRC r16,5
      rcall B8
   SBRC r16,4
      rcall B7
rjmp loop

line_B:
   SBRC r16,7
      rcall Bx
   SBRC r16,6
      rcall B6
   SBRC r16,5
      rcall B5
   SBRC r16,4
      rcall B4
rjmp loop

line_C:
   SBRC r16,7
      rcall Bmin
   SBRC r16,6
      rcall B3
   SBRC r16,5
      rcall B2
   SBRC r16,4
      rcall B1
rjmp loop

line_D:
   SBRC r16,7
      rcall Badd
   SBRC r16,6
      rcall Beq
   SBRC r16,5
      rcall B0
   SBRC r16,4
      rcall Bcl
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
lcd_out 'x'
ret

Bmin:
Bcl:
ret

Beq:
   SBRS oper,0
   rcall to2
   SBRC oper,0
   rcall to16
   ldi r16,0
ret

Badd:
ret

;A4-to2(1) B4-to16(0)
equal:


ret

to16:
ret

to2:
   ldi r26,0
   qwe123:
      SBRS numb,7
	 lcd_out '0'
      SBRC numb,7
	 lcd_out '1'
	 
      ldi r16,0b00000111
      EOR r16,r26
      BREQ to2_part2
     
	 
      LSL numb
      inc r26
   rjmp qwe123
   
   to2_part2:
      ldi numb,0
ret
;**************delay(для 4MHz)****************************************************
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