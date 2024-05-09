.device ATmega8
.include "m8def.inc"
.ORG 0x00 rjmp RESET
.ORG 0x011 rjmp TWI

.equ E = 2
.equ RS = 1


.def data = r22
.def end = r21
.def Razr0 = r17 
.def Razr1= r18 
.def Razr2 = r19 
.def buff = r23
.def numb = r24
.def oper = r25

RESET:
   ldi r16,high(RAMEND)
   out SPH ,r16
   ldi r16,low(RAMEND)
   out SPL ,r16
   
   ldi r16,0
out PORTD,r16
   sei

Proga: // Основная программа
 rcall init_LCD
 
 ldi r16,'1'
 st Z+,r16
 rcall LCD_data
 rcall Del_5ms
 
ldi r16,'2'
 st Z+,r16
 rcall LCD_data
 rjmp loop



init_LCD:
	cbr data,E
	SBR data,RS
	rcall TWI_Start 
	rcall waitEnd
	rcall Del_500ms
	
	ldi r16, 0b00000011
	rcall LCD_command
	rcall Del_5ms
	
	ldi r16, 0b00000010
	rcall LCD_command	
	rcall Del_5ms
	
	ldi r16,0b00101000  
	rcall LCD_command_4bit	
	rcall Del_5ms
	
	ldi r16,0b00001000 
	rcall LCD_command_4bit 	
	rcall Del_5ms
	
	ldi r16,0b00000001 
	rcall LCD_command_4bit 
	rcall Del_5ms
	
	ldi r16,0b00000110 
	rcall LCD_command_4bit 
	rcall Del_5ms

	ldi r16,0b00001100 
	rcall LCD_command_4bit 
	rcall Del_5ms

	ldi r16,0b10000000 
	rcall LCD_command_4bit ;
	rcall Del_5ms
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
	

Del_150mks:
cli 
	push	Razr0
	ldi	Razr0,200 ;
Del_50: 	dec Razr0
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


   ;https://radioparty.ru/programming/avr/c/258-lcd-avr-lesson1

TWI:
   cli 
   in r16,TWSR 
   andi r16, 0xF8 

   cpi r16, 0x08 // Если 0x08 - Пришли после старта, далее нам надо выкинуть на шину
   breq SLAW_Adr 

   cpi r16, 0x18 // Если 0x18 - Пришли после посылки адреса микросхемы с записью, далее 
   breq EEADR  // выкинем на шину адрес по которому будем записывать в микросхему

   rjmp Stop // заберем последний байт и сгенерим стоп
   
   Vix:
      sei // Разрешаем прерывания
      reti // Выходим из прерывания  
   
TWI_Start: // Посылаем старт
   ldi end,0
   ldi r16, 0b10100101 // Запускаем старт, TWINT, TWEN, TWIE - разрешаем интерфейс и прерывания,
   out TWCR, r16 // TWSTA - соответственно стартуем, остальные биты тут = 0
ret
 
EEADR: 
   ldi r16, 0b00100000   // Записали адрес
   rcall TWI_SendByte // Отправили на шину с Ack
   rjmp Vix

SLAW_Adr:
   ldi r16, 0x40 // Адрес микросхемы+Запись, бит записи это 0 в самом правом бите
   out TWDR, r16 // Спуливаем на дата регистр
   ldi r16, 0b10000101 
   out TWCR, r16
   rjmp Vix

TWI_SendByte:
   out TWDR, data // Спуливаем на дата регистр
   ldi r16, 0b10000101 
   out TWCR, r16
ret

Stop:
   ldi r16, 0b00010100
   out TWCR, r16
   ldi end,1
   rjmp Vix
   
   
waitEnd:
SBRS end,0
rjmp waitEnd
RET



.macro Set_cursor
push r16 ;чтобы не думать о сохранности temp
ldi r16,(1<<7)|(@0<<6)+@1;курсор строка @0(0-1) позиция @1(0-15)
rcall LCD_command_4bit ;
rcall Del_5ms
pop r16
.endm


// keybord

.macro lcd_out
   ldi r16,@0
   st Z+,r16
   rcall LCD_data
   rcall wait_end_out
.endm


wait_end_out:
IN r16,PIND
ORI r16,0
BRNE wait_end_out
ret

loop:
IN  r16,PIND
SBRC r16,0
rjmp b789del

SBRC r16,1
rcall b456x

SBRC r16,2
rcall b123min

SBRC r16,3
rcall bcl0eqAdd

rjmp loop

b789del:
   SBRC r16,7
      rcall Bdel
   SBRC r16,6
      rcall B9
   SBRC r16,5
      rcall B8
   SBRC r16,4
      rcall B7
rjmp loop

b456x:
   SBRC r16,7
      rcall Bx
   SBRC r16,6
      rcall B6
   SBRC r16,5
      rcall B5
   SBRC r16,4
      rcall B4
rjmp loop

b123min:
   SBRC r16,7
      rcall Bmin
   SBRC r16,6
      rcall B3
   SBRC r16,5
      rcall B2
   SBRC r16,4
      rcall B1
rjmp loop

bcl0eqAdd:
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
ret

B1:
   lcd_out '1'
ret

B2:
B3:
ret

B4:
   lcd_out '4'
ret

B5:
   lcd_out '5'
ret


B6:
   lcd_out '6'
ret

B7:
   lcd_out '7'
ret


B8:
   lcd_out '8'
ret

B9:
   lcd_out '9'
   rjmp loop
   
Bdel:
   lcd_out ' '
   rcall Del_5ms
   lcd_out '/'
   rcall Del_5ms
   Set_cursor 1,0
ret


Bx:
lcd_out 'x'
ret

Bmin:
Bcl:
Beq:
Badd:

ret



;1- add 2- mibus 3- x 4- del
equal:
ret