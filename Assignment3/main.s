; ebx would be used to transfer control

%macro START 1
push ebp
mov ebp, esp
sub esp, %1
%endmacro

%macro END 1
add esp, %1
mov esp, ebp
pop ebp
%endmacro 

%macro SSCANF 3
pushad
push %1
push %2
push %3
call sscanf
add esp, 12
popad
%endmacro

%macro CALLOC 3 
pushfd		; must not do pushad because we want the return value of calloc will stay in eax (after pusfad need to do popad)
push ecx  
push ebx
push edx
push %1 ; size of space unit
push %2 ; amount of memory space
call calloc
mov %3, eax
add esp, 8
pop edx
pop ebx
pop ecx
popfd
%endmacro

%macro FREE 1
pushad
pushfd
push %1
call free
add esp, 4
popfd
popad
%endmacro

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

section .data
	
	global N
	global K
	global R
	global d
	global seed
	global drone_struct
	global CURR_CO
    global CURR_ID
    global pointer_schedular
    global pointer_target
    global pointer_printer
    global pointer_drones_array
    global pointer_cors_array
	global LFSR
	global target_coor_x
	global target_coor_y
	global endCo
	global resume
	global MAXINT
	global hundred
	global hundred_eighty
	global three_hundred_sixty
	global main
	
	extern printf
    extern calloc 
    extern sscanf
    extern free
    extern schedular_function
    extern printer_function
    extern target_function
    extern function_drones
	
	MAXINT: dd 0xFFFF
	hundred: dd 100
	hundred_eighty: dd 180
	three_hundred_sixty: dd 360

	lfsr: dd 0
	
	pointer_printer: dd printer_function
		dd printer_stack+STKSZ
	
	pointer_target: dd target_function
		dd target_stack+STKSZ
		
	pointer_schedular: dd schedular_function
		dd schedular_stack+STKSZ
		
section .rodata
	
	format_int: db "%d", 0  
	STKSZ	equ	16*1024			

section .bss
	N: resd 1
	R: resd 1
	K: resd 1
	d: resd 1
	seed: resd 1
	
	pointer_drones_array: resd 1
	pointer_cors_array: resd 1
	pointer_free_stk_array: resd 1
	
	printer_stack: resb STKSZ
	target_stack: resb STKSZ
	schedular_stack: resb STKSZ
	
	CURR_CO: resd 1   ; pointer to the current co_routine
    CURR_ID: resd 1   ; pointer to the id of current drone
    SPT: resd 1       ; pointer to current esp
    SPMAIN: resd 1
	
	drone_struct:
        struc drone
            id: resd 1
            x: rest 1
            y: rest 1
            angle: rest 1
            score: resd 1
            speed: rest 1
        endstruc
    
    struct_coroutine:
        struc coi
            funci: resd	1
            sp_co: resd 1
        endstruc

	target_coor_x: rest 1
	target_coor_y: rest 1
	
	diffrence_x: rest 1
	diffrence_y: rest 1
	diffrence_x_square: rest 1
	diffrence_y_square: rest 1
			
section .text

main:

	finit
	
%define argv dword [ebp+12]

	START 0
	pushad
	
    mov ecx, argv 
;read argv    
    SSCANF N, format_int, dword[ecx + 4]  
    SSCANF R, format_int, dword[ecx + 8]
    SSCANF K, format_int, dword[ecx + 12]
    SSCANF d, format_int, dword[ecx + 16]
    SSCANF seed, format_int, dword[ecx + 20]
    
; initialize targrt

	call LFSR
	fild dword [seed]
	fidiv dword[MAXINT]
	fild dword[hundred]
	fmul
	fstp tword [target_coor_x]
	
	call LFSR
	fild dword [seed]
	fidiv dword[MAXINT] 
	fild dword[hundred]
	fmul
	fstp tword [target_coor_y]
	
; init target co routine	
	
	mov [SPT], esp	; save the esp to the temp stack pointer
	mov esp, [pointer_target + 4] ; esp points to the COi stack
	push target_function ; push function of COi , initial “return” address
	pushfd ; push flags
	pushad ; push all other registers
	mov [pointer_target + 4], esp ; save new SPi value (after all the pushes)
	mov esp, [SPT] ; restore esp value
	
init_drones_array:

	mov edx,0
	mov eax, dword [N]
	mov edx, 48
	mul edx
	CALLOC 1, eax, dword[pointer_drones_array]     ; allocating space for the array of  all N drones
	
	mov eax, 0
	mov ebx, 0  ; position in the drones array & counter id & counter until N
		
    mov edi, dword[pointer_drones_array]  ; edi points to the allocated space in memory of the drones array
	
loop_init_drones:
	
	cmp ebx, dword[N]
	je init_free_stk_array
	
	mov eax, 48
	mul ebx
; init id
	mov dword [edi + eax + id], ebx	   ; pointer_drones_array[id] = counter

; init x
	call LFSR
	fild dword [seed]
	fidiv dword[MAXINT]
	fild dword[hundred]
	fmul
	fstp tword [edi + eax + x]    ;pointer_drones_array[x] = new x coordinate
	
; init y
	call LFSR
	fild dword [seed]
	fidiv dword[MAXINT]
	fild dword[hundred]
	fmul
	fstp tword [edi + eax + y]     ;pointer_drones_array[y] = new y coordinate
	
; init angle
	call LFSR	
	fild dword [seed]
	fidiv dword[MAXINT]
	fild dword[three_hundred_sixty]
	fmul
	fstp tword [edi + eax + angle]     ; pointer_drones_array[angle] = new angle
	
; init speed
	call LFSR	
	fild dword [seed]
	fidiv dword [MAXINT]
	fild dword[hundred]
	fmul
	fstp tword[edi + eax + speed]     ; pointer_drones_array[speed] = new speed
	
; init score
	mov dword [edi + eax + score], 0   ;pointer_drones_array[score] = 0
	
; check if to exit from the loop
	
	inc ebx
	jmp loop_init_drones

init_free_stk_array: 

	mov eax, dword [N]
	mov edx, 4
	mul edx
	
	CALLOC 1, eax, dword[pointer_free_stk_array] ; free_stk_array is a pointer to the array of addresses of the co routines stacks that we will need to free
	
init_cors_array:

	mov eax, dword [N]
	mov edx, 8
	mul edx
	
	CALLOC 1, eax, dword[pointer_cors_array] ; cors_array is a pointer to the array of co-routines structs
	
    mov ebx, 0  ; position in the drones array & counter id & counter until N
		
    mov ecx, dword [pointer_cors_array]	; ecx points to the N co-routines array
	
	mov esi, dword [pointer_free_stk_array]	; esi points to the free stacks array
	
loop_init_cors:
	
	cmp ebx, dword[N]
	je init_schedular
	
; init function
	mov dword [ecx + ebx*8 + funci], function_drones  ; sets the struct's function to be function_drones
	
; init drone stack
	CALLOC 1, STKSZ, eax  ;; sets the struct's stack to be a new allocated stack

	mov dword[esi + ebx*4], eax
	add eax, STKSZ
	
	mov dword[ecx + ebx*8 + sp_co], eax
	mov [SPT], esp	; save the esp to the temp stack pointer
	mov esp, [ecx + ebx*8 + sp_co] ; esp points to the COi stack
	push dword [ecx + ebx*8 + funci] ; ecx = function of COi , initial “return” address
	pushfd ; push flags
	pushad ; push all other registers
	mov [ecx + ebx*8 + sp_co], esp ; save new SPi value (after all the pushes)
	mov esp, [SPT] ; restore esp value
	
; check if to exit from the loop
	
	inc ebx
	jmp loop_init_cors
		

init_schedular:
	
	mov [SPT], esp	; save the esp to the temp stack pointer
	mov esp, [pointer_schedular + 4] ; esp points to the COi stack
	push schedular_function ; push function of COi , initial “return” address
	pushfd ; push flags
	pushad ; push all other registers
	mov [pointer_schedular + 4], esp ; save new SPi value (after all the pushes)
	mov esp, [SPT] ; restore esp value

init_printer:

	mov [SPT], esp	; save the esp to the temp stack pointer
	mov esp, [pointer_printer + 4] ; esp points to the COi stack
	push printer_function ; push function of COi , initial “return” address
	pushfd ; push flags
	pushad ; push all other registers
	mov [pointer_printer + 4], esp ; save new SPi value (after all the pushes)
	mov esp, [SPT] ; restore esp value
	
startCo:

	pushad ; save registers of main ()
	mov [SPMAIN], esp ; save ESP of main ()
	mov ebx, pointer_printer ; ebx points to the address of scheduler struct
	jmp do_resume ; resume a scheduler co-routine
	
endCo:

	mov esp, dword [SPMAIN] ; restore esp of main

start_free: 

	mov ebx, 0 ; counter
	mov ecx, dword[pointer_free_stk_array]
	
loop_free_stacks:
    
		cmp ebx, dword [N]
		je end_loop_free_stacks
		
		mov edi, dword[ecx + ebx*4]
		FREE edi
		
		inc ebx
		jmp loop_free_stacks
		
end_loop_free_stacks:
	
	mov edi, dword[pointer_cors_array]
	FREE edi

	mov edi, dword[pointer_drones_array]
	FREE edi
	
	mov edi, dword[pointer_free_stk_array]
	FREE edi
	
	popad ; restore registers of main
	END 0
	ffree
	
; exit
	mov eax, 1                              
    mov ebx, 0
    int 0x80
	
resume: ; save state of current co-routine
	
	pushfd
	pushad	; store resumed co-routine state
	mov edx, [CURR_CO]	; curr = address of the current co routine struct
	mov [edx + 4], esp ; save current esp in the stack of the current co routine for the next time 
	
do_resume: ; load ESP for resumed co-routine
	
	mov esp, [ebx + 4]	; esp will "work" on the current co routine stack 
	mov [CURR_CO], ebx ; curr_co = address of the current co routine struct
	popad ; restore resumed co-routine state
	popfd ; restore resumed co-routine flags
	ret ; "return" to resumed co-routine (function)

; generate a random number
LFSR:

    START 0
    pushad
    mov ecx, 15
      
loop_lfsr: 
		
	cmp ecx, 0 
	je end_lfsr
	
	mov eax, 0
	mov ax, [seed]
	xor [lfsr], ax ; 16 bit
	shr ax, 2
	xor [lfsr], ax ; 14 bit
	shr ax, 1
	xor [lfsr], ax ; 13 bit
	shr ax, 2
	xor [lfsr], ax ; 11 bit
	
	shl dword [lfsr], 15
	
	shr dword [seed], 1 	; MSB = 0
	
	mov bx, [lfsr]
	or [seed], bx    

	dec ecx
	jmp loop_lfsr
        
end_lfsr: 

	popad
	END 0
	ret   
    
