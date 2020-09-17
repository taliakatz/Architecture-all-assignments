section .rodata 
	format: db "%d", 10, 0 			; printf format string follow by a newline(10) and a null terminator(0), "\n",'0'

section .bss
	result resd 1

section .text                    										
	global assFunc													
	extern c_checkValidity
	extern printf
        
assFunc:
	push ebp            			; backup ebp
	mov ebp, esp       				; set ebp to assFunc activation frame
	pushad                  		; push all signficant registers onto stack (backup registers values)	
	pushfd							; backup eflags
			
	mov ebx, [ebp+8]   				; get the first argument (x)
	mov ecx, [ebp+12]  				; get the second argument (y)
	push ecx            			; push the reg value onto stack
	push ebx            			; push the reg value onto stack
	call c_checkValidity			; call to c function
	add esp, 8          			; “free" space allocated for function arguments in Stack, 8 because we pushed two integers and its 8 bytes, 2 addresses
	cmp eax, 0x31
	je substruct
	add ebx, ecx
	mov dword[result], ebx
	
print:	

	push dword[result]
	push format
	call printf
	add esp, 8          			; “free" space allocated for function arguments in Stack, because this 2 arguments take 8 bytes, 2 addresses
	jmp end
	
											
substruct:
	sub ebx, ecx
	mov dword [result], ebx
	jmp print
	
end:
	popfd							; restore all previously used eflags regs
	popad                  			; restore all previously used registers
	mov esp, ebp					; free function activation frame
	pop ebp							; restore Base Pointer previous value (to returnt to the activation frame of main())
	ret	
	
