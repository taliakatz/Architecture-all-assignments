section .data
	number: dd 0
	tmp: dd 0xa
	
section	.rodata			; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	; format string

section .bss			; we define (global) uninitialized variables in .bss section
	an: resb 12		; enough to store integer in [-2,147,483,648 (-2^31) : 2,147,483,647 (2^31-1)]
	
section .text
	global convertor
	extern printf

convertor:
	push ebp
	mov ebp, esp	
	pushad			

	mov ecx, dword [ebp+8]	; get function argument (pointer to string)
	mov eax, 1
	mov ebx, 0

go_to_end:
	cmp byte[ecx], 0
	je convert_to_int
	inc ecx
	jmp go_to_end

convert_to_int:
	dec ecx
	mov bl, byte[ecx]
	sub ebx, 0x30	;turning the ascii-number to decimal
	cmp ebx, 0
	je without_divide_0
	mul ebx
	add dword[number], eax
	div ebx

without_divide_0:
	mul dword[tmp]
	cmp ecx, dword[ebp+8]
	je init_regs
	jmp convert_to_int
	
init_regs:
	mov edx, 0
	mov ecx, esp

convert_to_hex:
	mov ebx, 0xf
	and ebx, dword[number]
	shr dword[number], 4
	cmp ebx, 9
	jg add_55
	add ebx, 0x30
	
end_of_convertion:
	push ebx
	cmp dword[number], 0
	je set_an
	jmp convert_to_hex
	
add_55:
	add ebx, 0x37
	jmp end_of_convertion
	
set_an:
	pop ebx
	mov byte[an+edx], bl
	inc edx
	cmp esp, ecx
	jne set_an

	mov byte[an+edx], 0
	push an			; call printf with 2 arguments -  
	push format_string	; pointer to str and pointer to format string
	call printf
	add esp, 8		; clean up stack after call

	popad			
	mov esp, ebp	
	pop ebp
	ret
