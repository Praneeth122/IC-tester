#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

; data segment
	
	jmp     start
	db      1024 dup(0)

	;keyboard  matrix
	
	prka	equ	20h
	prkb	equ	22h
	prkc	equ	24h
	cregk	equ	26h
	
	;input 8255 DISPLAY 7-seg
	
	prda	equ	40h
	prdb	equ	42h
	prdc	equ	44h
	cregd	equ	46h
	
	;socket
	
	prsa	equ	60h
	prsb	equ	62h
	prsc	equ	64h
	cregs	equ	66h 

	table_kb db 0eeh, 0edh, 0ebh, 0e7h, 0deh, 0ddh, 0dbh, 0d7h, 0beh, 0bdh, 0bbh, 0b7h, 07eh, 07dh, 07bh, 077h ; 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, enter, test, backspace,x ,x,x
	
	table_num db 10111111b, 10110000b, 11011011b, 11001111b, 11100110b, 11101101b, 11111101b, 00000111b, 11111111b, 11100111b ; 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
	
	table_letter db 11110001b,11110111b, 10110000b, 10111000b, 11110011b, 11101101b,10111001b,10110111b; F, A, I, L, P, S, C,N

	ic1 db 07h,04h,00h,00h			;nand
	ic2 db 07h,04h,00h,08h			;and
	ic3 db 07h,04h,03h,02h			;or
	ic4 db 07h,04h,08h,06h			;xor
	ic5 db 07h,04h,07h,02h,06h,06h	;xnor
	
    check1 db 00000000b
	check2 db 01010101b
	check3 db 10101010b
	check4 db 11111111b

	ic11 db 11110000b
	ic12 db 11110000b
	ic13 db 11110000b
	ic14 db 00000000b

	ic21 db 00000000b
	ic22 db 00000000b
	ic23 db 00000000b
	ic24 db 11110000b

	ic31 db 00000000b
	ic32 db 11110000b
	ic33 db 11110000b
	ic34 db 11110000b

	ic41 db 00000000b
	ic42 db 11110000b
	ic43 db 11110000b
	ic44 db 00000000b

	ic51 db 11110000b
	ic52 db 00000000b
	ic53 db 00000000b
	ic54 db 11110000b
	
	ntyped	db 1 dup(0h)				;has no:of valid keys entered
	typed 	db 6 dup(0ffh)				;has numbers need to display
	cur		db 1 dup(0h)
	ic 		db 1 dup(0h)					
	
; code segment
	
	;initialize  of RAM	

start:
							
	mov	ax,0200h
	mov es,ax
	mov ss,ax
	mov ds,ax
	mov sp,0FFFEH 
	
	mov al,10001000b
	out cregk,al 		 	;Congifure Keyboard
	
	mov al,10000000b
	out cregd,al			;Configure Display
	
	mov al,10010000b
	out cregs,al 			;Configure IC interfacing	

	lea si, cs:typed		;si pointer always for strarting address of typed
	
	;to display nothing
	mov al,00000000b
	out prda,al
	out prdc,al
	mov al,00000000b
	out prsc,al
	
	
;getting keys from keyboard
;displaying entered values
display_st:

	;Check release
	
	mov	al, 00h
	out prkc, al
	x1:	in al,prkc
		and al,0f0h
		cmp al,0f0h
		jnz x1	

	;print current keys entered present in memory

dis:	     
	lea di,cs:table_num
	lea si,cs:typed
	mov ch,cs:ntyped
	mov dl,11111110b
	mov cl,0h
	mov bh,0h
	mov ah,0h
	d1:
		cmp cl,ch
		jge key_in
		mov al,dl
		out prdc,al
		mov bl,cs:[si]
		mov al,cs:[di+bx]
		out prda,al
		mov al,00000000b
		out prda,al
		inc cl
		inc si
		rol dl,01h
		jmp d1
	
	lea si,cs:typed
	call delay20
	
	;check press

	key_in:
		
		mov	al, 00h
		out prkc, al
		a1:	in 	al,prkc
			and al,0f0h
			cmp al,0f0h
			jz 	dis
	
	call delay20
	
	;check press again
	
	mov	al, 00h
	out prkc, al
	in 	al,prkc
	and al,0f0h
	cmp al,0f0h
	jz 	a1
	
	;check each column
	;column 1
	
	mov al,0eh		
	mov bl,al
	out prkc,al
	in 	al,prkc
	and al,0f0h
	cmp al,0f0h
	jnz key
	
	;column 2
	
	mov al,0dh		
	mov bl,al
	out prkc,al
	in 	al,prkc
	and al,0f0h
	cmp al,0f0h
	jnz key
	
	;column 3
	
	mov al,0bh		
	mov bl,al
	out prkc,al
	in 	al,prkc
	and al,0f0h
	cmp al,0f0h
	jnz key
	
	;column 4
	
	mov al,07h		
	mov bl,al
	out prkc,al
	in 	al,prkc
	and al,0f0h
	cmp al,0f0h
	
key:
	or 	al,bl
	lea di,cs:table_kb[0fh]
	
	;Useless key
	
	cmp al,cs:[di]						
	jz display_st
	
	;Useless key
	
	dec di
	cmp al,cs:[di]						
	jz display_st
	
	;Useless key
	
	dec di
	cmp al,cs:[di]						
	jz display_st
	
	;backspace
	
	dec di
	cmp al,cs:[di]						
	jz bksp
	
	;test
	
	dec di
	cmp al,cs:[di]						
	jz t_ic
	
	;enterIC
	
	dec di
	cmp al,cs:[di]
	jz enterIC							
	
	mov cl,0bh
	n1:
		dec di
		dec cl
		cmp cl,0h
		je	display_st
		cmp al,cs:[di]
		jne n1
		jmp write

	;writing the entered keys in memory for displaying

	write:	
		dec cl
		mov al,00h					;reseting
		mov cs:cur,al
		mov al,cs:ntyped
		cmp al,06h					; if already 6 num entered 
		jge display_st
		lea di,cs:[si+al]
		mov cs:[di],cl
		inc al
		mov cs:ntyped,al
		
	jmp display_st			; for displaying entered key
	
	;funtion of backspace
bksp:						
		mov  al,0h						;reseting
		mov  cs:cur,al
		mov  al,cs:ntyped					;cheak for valid backspace
		cmp  al,0h
		jle	 b1
		dec  al
		mov  cs:ntyped,al
b1:		jmp display_st						;for displaying after revoming	

	;cheak for vaild ic num
enterIC:
	
	;check IC number
	
	;7400(nand)
	
	mov ah,00h
	
	EIC1:
		lea si,cs:typed
		lea di,cs:ic1
		mov cx,04h
		mov al,cs:ntyped
		cmp ax,cx
		jnz EIC2
		cld
		cheakIC1:
			mov al,cs:[di]
			cmp al,cs:[si]
			jnz EIC2
			inc si
			inc di
			dec cx
			jnz cheakIC1
		mov al,01h
		jz set_default
	
	;7408(and)
	
	EIC2:
		lea si,cs:typed
		lea di,cs:ic2
		mov cx,04h
		mov al,cs:ntyped
		cmp ax,cx
		jnz EIC3
		cld
		cheakIC2:
			mov al,cs:[di]
			cmp al,cs:[si]
			jnz EIC3
			inc si
			inc di
			dec cx
			jnz cheakIC2
		mov al,02h
		jz set_default
	
	;7432(or)
	
	EIC3:
		lea si,cs:typed
		lea di,cs:ic3
		mov cx,04h
		mov al,cs:ntyped
		cmp ax,cx
		jnz EIC4
		cld
		cheakIC3:
			mov al,cs:[di]
			cmp al,cs:[si]
			jnz EIC4
			inc si
			inc di
			dec cx
			jnz cheakIC3
		mov al,03h
		jz set_default	
	
	;7486(xor)
	
	EIC4:
		lea si,cs:typed
		lea di,cs:ic4
		mov cx,04h
		mov al,cs:ntyped
		cmp ax,cx
		jnz EIC5
		cld
		cheakIC4:
			mov al,cs:[di]
			cmp al,cs:[si]
			jnz EIC5
			inc si
			inc di
			dec cx
			jnz cheakIC4
		mov al,04h
		jz set_default
	
	;747266(xnor)
	
	EIC5:
		lea si,cs:typed
		lea di,cs:ic5
		mov cx,06h
		mov al,cs:ntyped
		cmp ax,cx
		jnz invalid
		cld
		cheakIC5:
			mov al,cs:[di]
			cmp al,cs:[si]
			jnz invalid
			inc si
			inc di
			dec cx
			jnz cheakIC5
		mov al,05h
		jz set_default
	
	lea si,cs:typed		;reset to default place
	jmp invalid
	
set_default:
	
	mov cs:ic,al         
	mov al,01h
	mov cs:cur,al
	lea si,cs:typed		;setting everything default
	jmp valid
	
		;vaild ic
valid:
	
	;check key release
	
	mov	al, 00h
	out prkc, al
	v1:	
		in al,prkc
		and al,0f0h
		cmp al,0f0h
		jnz v1
		
	;displaying IA (is available)
	mov cx,01fffh
	v2:
	    mov ah,00h
	    mov al,11111110b
		out prdc,al  
		mov al,cs:table_letter[02h]
		out prda,al
		mov al,00000000b
		out prda,al
		
		mov al,11111101b
		out prdc,al
	    mov al,cs:table_letter[01h]
		out prda,al
		mov al,00000000b
		out prda,al
		loop v2
	jmp display_st
	
	;invaild ic
	
invalid:
	;check key release
	mov	al, 00h
	out prkc, al
	iv1:	
		in al,prkc
		and al,0f0h
		cmp al,0f0h
		jnz iv1

	;dispalying NA(not available)
	mov cx,01fffh
	iv2:
	    mov al,11111110b
		out prdc,al
		mov al,cs:table_letter[07h]
		out prda,al
		mov al,00000000b
		out prda,al
		
		mov al, 11111101b
		out prdc,al
		mov al,cs:table_letter[01h]
		out prda,al
		mov al,00000000b
		out prda,al
		loop iv2

	jmp display_st
	
	;testing the ic
t_ic:
	
	mov al,cs:ic					;cheaking according to ICI number 
	cmp al,01h
	je t_nand
	cmp al,02h
	je t_and
	cmp al,03h
	je t_or
	cmp al,04h
	je t_xor
	cmp al,05h
	je t_xnor
	
	mov al,0h						;reseting to default if test is completed
	mov cs:ntyped,al
	lea si,cs:typed
	jmp display_st				
	
        ;giving test cases to IC  and getting o/p of IC 
t_nand:
	;7400
	
	mov al,cs:check1
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic11
	jnz fail
	
	mov al,cs:check2
	out prsc,al
	call delay20
	in al, prsa
	and al,0fh
	cmp al,cs:ic12
	jnz fail
	
	mov al,cs:check3
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic13
	jnz fail
	
	mov al,cs:check4
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic14
	jnz fail

	jmp pass
	
t_and:
	;7408
	
	mov al,cs:check1
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic21
	jnz fail
	
	mov al,cs:check2
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic22
	jnz fail
	
	mov al,cs:check3
	out prsc,al
	call delay20
	in al,prsa
	and al,0f0h
	cmp al,cs:ic23
	jnz fail
	
	mov al,cs:check4
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic24
	jnz fail
	
	jmp pass

t_or:
	;7432
	
	mov al,cs:check1
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic31
	jnz fail
	
	mov al,cs:check2
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic32
	jnz fail
	
	mov al,cs:check3
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic33
	jnz fail
	
	mov al,cs:check4
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic34
	jnz fail
	
	jmp pass

t_xor:
	;7486
	
	mov al,cs:check1
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic41
	jnz fail
	
	mov al,cs:check2
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic42
	jnz fail
	
	mov al,cs:check3
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic43
	jnz fail
	
	mov al,cs:check4
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic44
	jnz fail
	
	jmp pass
t_xnor:
	;747266
	
	mov al,cs:check1
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic51
	jnz fail
	
	mov al,cs:check2
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic52
	jnz fail
	
	mov al,cs:check3
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic53
	jnz fail
	
	mov al,cs:check4
	out prsc,al
	call delay20
	in al, prsa
	and al,0f0h
	cmp al,cs:ic54
	jnz fail
	
	jmp pass
	
pass:
	
	;check key release
	
	mov	al, 00h
	out prkc, al
	p1:	
		in al,prkc
		and al,0f0h
		cmp al,0f0h
		jnz p1
		
	mov cx,01fffh
	p2:
		mov al,11111110b
		out prdc,al
		mov al,cs:table_letter[04h]
		out prda,al
		mov al,00000000b
		out prda,al
		
		mov al,11111101b
		out prdc,al
		mov al,cs:table_letter[01h]
		out prda,al
		mov al,00000000b
		out prda,al
		
		mov al,11111011b
		out prdc,al
		mov al,cs:table_letter[05h]
		out prda,al
		mov al,00000000b
		out prda,al
		
		mov al,11110111b
		out prdc, al
		mov al,cs:table_letter[05h]
		out prda,al
		mov al,00000000b
		out prda,al
		loop p2
		
		mov al,00000000b
		out prda,al
		mov al,00000000b
		out prdc,al
	jmp display_st

fail:
	;check key release
	mov	al, 00h
	out prkc, al
	f1:	
		in al,prkc
		and al,0f0h
		cmp al,0f0h
		jnz f1
		
	mov cx,01fffh
	f2:
		mov al,11111110b
		out prdc,al
		mov al,cs:table_letter[0h]
		out prda,al
		mov al,00000000b
		out prda,al
		
		mov al,11111101b
		out prdc,al
		mov al,cs:table_letter[01h]
		out prda,al
		mov al,00000000b
		out prda,al
		
		mov al,11111011b
		out prdc,al
		mov al,cs:table_letter[02h]
		out prda,al
		mov al,00000000b
		out prda,al
		
		mov al,11110111b
		out prdc, al
		mov al,cs:table_letter[03h]
		out prda,al
		mov al,00000000b
		out prda,al
		loop f2
	
		mov al,00000000b
		out prda,al
		mov al,00000000b
		out prdc,al
	jmp display_st
	
delay20 proc near
		mov ax,11C1h
	dl1:	nop
		dec ax
		jnz dl1
		ret
	
HLT           ; halt