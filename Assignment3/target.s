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
     
    global target_function
	extern LFSR
	extern target_coor_x
	extern target_coor_y
	extern pointer_cors_array
	extern CURR_ID
	extern seed
	extern resume
    extern hundred
    extern MAXINT
    extern printf
    
section .text
	
target_function:

call createTarget

    mov ecx, dword[CURR_ID]
    mov eax, 8
    mul ecx
    mov ecx,eax
    mov eax, dword[pointer_cors_array]
    add eax,ecx
    mov ebx , eax

    call resume
    jmp target_function
    
createTarget:	; function

    START 0
    finit
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
    ffree
    END 0
    ret
