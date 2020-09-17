%macro PRINT 2
pushad
pushfd
push %1 ; something to print
push %2 ; format
call printf
add esp, 8
popfd
popad
%endmacro

; define sizes
	id equ 0
    x equ 4
    y equ 14
    angle equ 24
    score equ 34
    speed equ 38

section .rodata

	format_game_over: db "The Winner is drone: %d", 10, 0   ; maybe 0, 0
	MAXINT	equ 0xFFFF
	
section .data
	counter: dd 0
	
	extern N
	extern K
	extern R
	extern d
	extern seed
	extern CURR_CO
    extern CURR_ID
    extern pointer_schedular
    extern pointer_target
    extern pointer_printer
    extern pointer_drones_array
	extern pointer_cors_array
	extern LFSR
	extern target_coor_x
	extern target_coor_y
	extern endCo
	extern resume
	extern printf
	global schedular_function	
	
	
section .bss
	players: resd 1
	to_eliminate: resd 1

section .text

schedular_function:
	
	mov edx, dword [N]
	mov dword [players], edx       ; players = N

schedular_function_loop:

	cmp dword [players], 1
	je game_over
	
	mov edx ,0
	mov eax, dword [counter]  ; counter = turn number
	mov ecx, dword [N]
	
	div ecx 	; edx will store the remainder and also the remainder is the curr id (turn number / N) 
	mov edi, edx  ; edi = CURR ID
	
	mov eax,48
	mul edx
	mov edx,eax   ; edx = CURR ID * 48
	
	mov eax , dword[pointer_drones_array]
	
	cmp dword [eax + edx + id], -1	; check if the drone is active (edx = CURR ID)
	je after_activate_drone	; if the drone is not active continue without activate it
	
	mov dword [CURR_ID], edi	; update the CURR_ID
	mov eax, dword[pointer_cors_array]
	
	shl edi,3     ; edi = edi*8
	add eax, edi
	mov ebx, eax	; ebx = struct of co routine of the drone with the CURR_ID	
	call resume

after_activate_drone:
		
	mov edx, 0 	; clear edx
	mov eax, dword [counter]
	mov ecx, dword [K]
	div ecx	; the remaider will be n edx
	cmp edx, 0	; check if the remainder (modulo) is 0
	je mov_to_printer 	; if the modulo result is 0 move the control to printer
		
		
after_printer_function:

	mov edx, 0	; clear edx
	mov eax, dword [counter]
	mov ecx, dword [N]            ; counter / N
	div ecx	; divide by N and the result (without remainder) will be in eax
	mov ecx, dword [R]
	mov edx, 0
	div ecx	; the remaider will be n edx  -> for condition 1: (counter / N) % R ==0

	cmp edx, 0	; check if the remainder (modulo) is 0
	
	jne end_schedular_loop 	; if the modulo result isnt 0 continue without checking the next condition
	
	mov edx, 0
	mov eax, dword [counter]
	mov ecx, dword [N]
	div ecx	; the remaider will be n edx  -> for condition 2: (counter % N)==0
	cmp edx, 0	; check if the remainder (modulo) is 0
	je find_lowest_M 	; if the modulo result is 0 find the lowest M , else if the modulo result is not 0 then continue in the loop
	
end_schedular_loop:
		
	inc dword [counter]
	jmp schedular_function_loop
		
mov_to_printer:

	mov ebx, pointer_printer
	call resume
	jmp after_printer_function

find_lowest_M:

	mov eax, 48
	mov ecx, dword [N]
	mul ecx
	mov esi, eax
	
	mov ecx, 0	; ecx = counter
	
	mov edx, MAXINT 	; edx =  lowest score
	
	mov eax , dword [pointer_drones_array]	; eax = pointer to the drones array
	
find_lowest_M_loop:
	
	cmp ecx, esi
	
	je end_find_lowest_M_loop
	
	cmp dword [eax + ecx + id], -1	; check if the drone is active
	je continue_find_lowest_M_loop
	
	cmp edx, dword [eax + ecx + score]	; compare between the 2 scores
	jle continue_find_lowest_M_loop	; if the minimum score is less, do nothing and continue
	
	mov edx, dword [eax + ecx + score]	; if the score of drone is less then the minimum, change edx (min score) to the drone score
	
	mov edi, eax
	add edi, ecx	; edi = tmp
	mov dword [to_eliminate], edi	; mov to [to_eliminate] the drone with the min score
		
continue_find_lowest_M_loop:
		
	add ecx, 48
	jmp find_lowest_M_loop
		
end_find_lowest_M_loop:
		
	mov edi, dword [to_eliminate]
	mov dword[edi], -1
	dec dword[players]        ; player --
	jmp end_schedular_loop
		
game_over:

	mov ecx, 0	; will be the counter
	mov edx, MAXINT 	; will be the lowest score
	mov eax , dword [pointer_drones_array]	; eax = pointer to the drones array
	
find_winner_loop:

	cmp dword [eax + ecx + id], -1	; check if the drone is active
	jne print_winner
	add ecx, 48
	jmp find_winner_loop

print_winner:	

	PRINT dword [eax + ecx + id], format_game_over
	jmp endCo
