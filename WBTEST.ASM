	org 100h
section .text
start:
	; disable speaker & stop timer 2
	in      al, 61h
	and     al, 0FCh
	out     61h, al
	; initialize timer 2 for benchmarking
	mov     al, 0B4h        ; count-down mode / r/w 16 bit value
	out     43h, al
	mov     al, 0
	out     42h, al
	out     42h, al
	
	cli                     ; no interrupts please - may destroy cache
				; feng-shui
	mov     dx, 1789h       ; "mov [bx], dx"
	call    bench
	mov     [tmr1], ax      ; timer value 1: for store loop (negative)

	mov     dx, 178Bh       ; "mov dx, [bx]"
	call    bench
	sti                     ; AX = timer value 2: for load loop (negative)

	sub     ax, [tmr1]      ; AX = duration of stores - duration of loads
				; in timer ticks for 62,000 iterations
	mov     bx, 838         ; 838ns/tick
	imul    bx
	mov     bx, 6200        ; iteration count/10 (to get 10ths of ns)
	idiv    bx
	jnz     different
	mov     ah, 9           ; less than .1ns difference - output "equal"
	mov     dx, equalmsg
	int     21h
	ret

different:
	mov     si, storeslow
	jns     positivediff    ; jump - positive difference (stores slower)
	mov     si, storefast
	neg     ax              ; negate value
positivediff:
	
	mov     cx, 4
	mov     bx, 10          ; push four decimal digits (up to 999.9ns)
decimalloop:
	xor     dx, dx
	div     bx
	push    dx
	loop    decimalloop

	mov     ah, 2           ; function code "print char" for DOS
	mov     cx, 3
printloop:
	pop     dx              ; pop digit
	or      dl, '0'         ; to ASCII
	int     21h             ; print
	loop    printloop

	mov     dl, '.'         ; decimal separator
	int     21h
	pop     dx
	or      dl, 30h         ; last digit
	int     21h

	mov     dx, si
	mov     ah, 9
	int     21h
	mov     dx, commonmsg
	int     21h
	
	ret

; In:  DX = opcode to execute 62000 times (2 bytes)
; Out: AX = negative amount of timer ticks taken (including loop overhead)
; Opcode is executed with BX pointing to an address in L1
; Opcode must not change CX or AL
bench:
	mov     si, testarea
	mov     cx, 80h
	rep     lodsw           ; load 256B into L1 cache

	mov     di, testloop
	mov     cx, 62
	mov     ax, dx
	rep     stosw           ; 62 repetitions (124 bytes)

	mov     bx, dummy
	mov     cx, 1000
	call    testarea        ; repeat the instruction 62,000 times
	
	in      al, 42h         ; read timer to AX
	mov     ah, al
	in      al, 42h
	xchg    ah, al
	ret

; cache-line aligned and pre-loaded.
; make sure it includes timer start and timer stop
	align   16
testarea:
	in      al, 61h
	or      al, 1           ; start timer at FFFFh, counting down
	out     61h, al
testloop:
	times 62 dw 9090h       ; 62 repetition to keep in reach of 8086 loop
	loop    testloop

	and     al, 0FEh        ; freeze timer
	out     61h, al
	retn
	align   16
	db 0,0,0
dummy:  dw 0

section .data
storeslow:     db " ns slower$" 
storefast:     db " ns faster$"
commonmsg:     db " unaligned stores than unaligned loads", 0dh, 0ah, '$'
equalmsg:      db "loads and stores are equally fast", 0dh, 0ah, '$'

section .bss
tmr1:   resb 2
