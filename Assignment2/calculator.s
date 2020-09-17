MAX_BUF equ 80

%macro FREE_OPERAND 1       ;%1 = address of the first link of the number we need to delete
pushad
pushfd
mov edx, %1
mov ebx, edx             ; ebx = curr , edx = next
%%free_loop:
cmp ebx, 0             ; next address is "null"
je %%exit_free
add edx,1               ; edx = pointer to the next link
mov edx, dword[edx]        ; edx = the address of the next link
mov dword[to_delete],ebx
FREE dword[to_delete]
mov ebx, edx          ; ebx points to next link
jmp %%free_loop
%%exit_free:            ;freeing the first link
dec byte[num_operands]
popfd
popad
%endmacro

%macro FREE_ALL_LIST 0
pushad
pushfd
%%loop_free_list:
cmp byte[num_operands], 0
je %%free_stack_ptr
sub dword[stack_ptr], 4
mov edx, dword[stack_ptr]
FREE_OPERAND dword[edx]  ; this macro also sub 1 from num_operands
jmp %%loop_free_list
%%free_stack_ptr:
FREE dword[stack_ptr]
popfd
popad
%endmacro

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

%macro FGETS 3
pushad
pushfd
push %1 ; stream
push %2 ; length to 'get'
push %3 ; buffer to store
call fgets
add esp, 12
popfd
popad
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

%macro PRINT_STDERR 2    
pushad
pushfd
push %1     ;string to print
push %2     ;format
push dword[stderr]
call fprintf
add esp, 12
popfd
popad
%endmacro

%macro ADD_NUMBER 1    ; create linked list for new number and add it to the stack
	mov ecx, dword[stack_ptr]   ; ecx = address that the stack pointer points on
	mov dword[curr_link], ecx  ; *curr_link = *stack_ptr ->> we want the number's list to be added to the next available space on stack
	mov ecx, %1  	 ; ecx = & input_buf                    
	cmp byte[ecx], 0xa      ; check if the buf is empty      
	je exit_add_num
dismiss_leading_zeros:
	cmp byte[ecx], 0xa      ; check if = '\n'
    je got_zero	; then the input number is 0
	cmp byte[ecx], 0x30
	jne change_address_of_input_buf
	inc ecx
	jmp dismiss_leading_zeros
got_zero:
	dec ecx

change_address_of_input_buf:
	mov dword[input_no0], ecx 
go_until_end_buf:			; going to the lsb of the number
	inc ecx                   ; ecx++
	cmp byte[ecx], 0xa		;input fron FGETS finishes with '\n'
	je get_decimal_val_of_first_byte
	jmp go_until_end_buf
get_decimal_val_of_first_byte:            ; getting the decimal value of the hex-number
	mov edx, 0
	mov ebx, 0
	dec ecx  	; ecx = ecx - 1 , need to points on the first byte of the input
	mov bl, byte[ecx]   ; bl = (byte)ecx
	cmp bl, 0x39          ; checking if the next digit is a letter
	jg sub_letter_bl
	sub bl, 0x30        ; bl = bl - 48 for decimal representation
after_sub_bl:
	cmp ecx, dword[input_no0]  ; if & ecx == & input_buf   ; if true, continue _addNumber2
	je add_new_link_of_byte
	dec ecx    ; ecx = ecx -1
	mov dl, byte[ecx]  ; dl = (byte)ecx
	cmp dl, 0x39      ; checking if the next digit is a letter
	jg sub_letter_dl
	sub dl, 0x30   ; dl = dl - 48 for decimal representation
	cmp dl, 0
	je add_new_link_of_byte
after_sub_dl:
	shl edx, 4     ; edx = edx * 16
add_new_link_of_byte:
	add edx, ebx   ; now edx will contain the number that we'll store inside the link (until now it is in bl)
	MAKE_LINK dl  ; the macro make_link will allocate memory for a new link that it's address will return in eax, the data of the link also will be store
	mov ebx, dword[curr_link]  ; ebx = *curr_link ( == *stack_ptr in the first loop)
	mov dword[ebx], eax			; **curr_link = the new link
	inc eax						; eax = 'link->next'
	mov dword[curr_link], eax	; *curr_link = eax (the next 4 bytes which are alocated for curr_link)
	cmp ecx, dword[input_no0]			; if & ecx == & input_buf   ; if true, ret_addNumber
	je ret_addNumber
	jmp get_decimal_val_of_first_byte		; return to the loop that will make the next link
sub_letter_bl:
	sub bl, 0x37                ; bl = bl - 55 -> to get a decimal value out of letter 
	jmp after_sub_bl
sub_letter_dl:              ; dl = dl - 55 -> to get a decimal value out of letter
	sub dl, 0x37
	jmp after_sub_dl
ret_addNumber:
	cmp byte[fdebug], 1            ;if 1 -> debug print
	jne end_add_num
	PRINT_STDERR debug_number_read_from_user, format_calc	; print the debug sentence
	DEBUG_PRINT dword[stack_ptr]							; print the number which has been added
end_add_num:
	add dword[stack_ptr], 4        ;stack_ptr pints to the next free space on stack
	inc byte[num_operands]         ;after adding a number -> number of operands++
exit_add_num:
%endmacro

%macro MAKE_LINK 1          ; creates a new link with the byte value %1 (=data) and enters the new address to EAX
	CALLOC 5, 1, eax   ; eax = calloc(1, 5)
	mov byte[eax], %1  ; the last byte of the new link ( [eax] ) = dl (the new data of the link)
%endmacro

%macro GET_NEW_STACK_SIZE 1  	; %1 is edx , and edx has the address to the value of argv[i] that is the new stack size
	pushad 
	pushfd 						; backup all registers
	mov ecx, 0						; ecx = 0
	mov cl, byte[%1]				; ecx now contain the first byte (in ascii value) of the user stack size
	cmp cl, 0x39					; check if there is letter or number
	jg %%sub_55
	sub cl ,0x30					; ecx = ecx - 48
%%after_sub_48_first_time:
	inc %1							; edx point of the second byte of the user stack size, maybe eill be 0 (null)
	cmp byte[%1], 0
	jne %%mult_16
	mov byte[stack_size], cl
	jmp %%return_to_check_debug			; update the stack size
%%sub_55:
	sub cl, 0x37					; ecx = ecx - 55
	jmp %%after_sub_48_first_time
%%mult_16:							
	shl ecx, 4  					; ecx = ecx*16
	mov byte[stack_size], cl		; stack_size will contain the decimal value of the user stack size	
	mov cl, byte[%1]				; else, ecx contain the value in ascii of the second byte
	cmp cl, 0x39					; check if there is letter or number
	jg %%sub_55_second_time
	sub cl ,0x30					; ecx = ecx - 48
	jmp %%after_all_subs
%%sub_55_second_time:
	sub cl, 0x37					; ecx = ecx - 55	
%%after_all_subs:				
	add byte[stack_size], cl		; addind to stack_size 
%%return_to_check_debug:
	popfd
	popad
%endmacro

section .rodata
	format_normal: db "%s", 10, 0	
	format_counter: db "%d",10, 0  
	format_calc: db "%s", 0
	format_hexa: db "%02X", 0
    format_hexa_x: db "%X", 0
	format_byte: db "%c", 0
	debug_str: dd '-'
	calc: db 'calc: ', 0
	error_insufficient: db 'Error: Insufficient Number of Arguments on Stack', 0
	error_overflow: db 'Error: Operand Stack Overflow', 0
    debug_pushed_to_stack: db 'Pushed to stack: ', 0
    debug_number_read_from_user: db 'Got number from user: ',0
    
section .data
	fdebug: db 0
	stack_size: db 5
	num_operands: db 0
	num_operations: dd 0
	
section .bss
	stack_ptr: resd 1
	curr_link: resd 1
	input_buf: resb MAX_BUF
	input_no0: resd 1
	operation: resb 1
	to_delete: resd 1

section .text
  align 16
  global main
  extern printf
  extern fprintf 
  extern malloc 
  extern calloc 
  extern free 
  extern fgets 
  extern stdin
  extern stdout
  extern stderr

main:
	START 0
	mov ecx, [ebp+8]  ;ecx = argc (including './calc')
	mov eax, [ebp+12] ;eax = pointer to argv
	mov ebx, 1
	mov edx, 0
check_for_debug:
	cmp ebx, ecx   ; checking if (ebx == argc) 
	je end_main
	mov edx, dword[eax+4*ebx]	;edx = address of argv[i]
	cmp byte[edx], '-'             ;check if the first byte of argv[i] == '-', if so - we need to look for 'd'
	je continue_check_debug
	GET_NEW_STACK_SIZE edx     ; macro for computing the stack size from hexa to decimal, also stores the value in 'stack_size'
	jmp next
continue_check_debug:
	cmp byte[edx+1], 'd' ;check if second byte of argv[i] == 'd', if so - turn debug flag on
	jne next
is_debug:
	mov byte[fdebug], 1   ;turn on debug flag
next:
	inc ebx
	jmp check_for_debug ;go to > next round of the loop
end_main:
    mov ecx,0
    mov cl, byte[stack_size]
	CALLOC 4, ecx, dword[stack_ptr] ; *stack_ptr = calloc (stack_size, 4) >> allocating space for the operands stack suck that stack_ptr points to the first element
	call myCalc
exit_main:			; need to free stack before exit
	FREE_ALL_LIST
	PRINT dword[num_operations], format_counter  ;print the return value of myCalc
	END 0 
	mov ebx, 0 ; exit system call
	mov eax,1
	int 0x80
	
%macro DEBUG_PRINT 1           ;%1 = 'stack' address that hold the address of first link
    mov ebx, esp                       ;ebx = last address of esp before we start pushing into the stack (so we'll know when to end the print)
    mov ecx, %1                 
    mov ecx, dword[ecx]         ; ecx = address of first link
%%go_to_last_link:                        ; going to the last link of the operand (when stoped -> ecx has the adress of the last link (null))
    cmp ecx, 0                    ;checking if last link       
    je %%print_number
    mov edx, 0
    mov dl, byte[ecx]
    push edx                  ; pushing the first byte (=the digit)
    inc ecx                         ; going to the last 4 bytes to get the next link's address
    mov ecx, dword[ecx]                ; ecx = address of next link
    jmp %%go_to_last_link
    %%print_number:               ;printing the first digit seperatly because it could have 1 digit
    pop edx
    PRINT_STDERR edx, format_hexa_x
    %%print_rest:
    cmp esp, ebx            ; checking if we got to the last digit the number
    je %%end_print
    pop edx                 ; edx has the number to be printed
    PRINT_STDERR edx, format_hexa  ;printing digit without '\n'
    jmp %%print_rest
    %%end_print:
    mov edx, 0xa            ; priting '\n'
    PRINT_STDERR edx, format_byte
    mov ebx, dword[stack_ptr]       ;ebx = address of the 'stack' location
%endmacro

myCalc:
	START 0
main_loop:
	PRINT calc, format_calc ; printing: "calc:"
	b1:
	FGETS dword[stdin], MAX_BUF, input_buf ; 
	b2:
	cmp byte[input_buf], 'q'
	je exit_main
	cmp byte[input_buf], '+'
	je check_at_least_2_operands
	cmp byte[input_buf], 'p'
	je check_at_least_1_operand
	cmp byte[input_buf], 'd'
	je check_at_least_1_operand
	cmp byte[input_buf], '&'
	je check_at_least_2_operands
	cmp byte[input_buf], '|'
	je check_at_least_2_operands
    cmp byte[input_buf], 'n'
    je check_at_least_1_operand
	jmp check_space		;need to add new number to the list
	END 0

check_space:                        ; checking for Overflow
	mov cl, byte[num_operands]       
	cmp cl, byte[stack_size]         ;if (number of operand == stackSize) ->> Overflow ERROR
	jl after_check_space
    PRINT error_overflow, format_normal 
    jmp main_loop
	after_check_space:
	cmp byte[input_buf], 'd'
	je duplicate
	cmp byte[input_buf], 'n'
	je push_num_of_digits
make_number:	; if not 'd' and not 'n' jump to add new numbe
	ADD_NUMBER input_buf           ;create the linked list for the new number, using input_buf as 'stop' address
	jmp main_loop

%macro LOOP_ADD_OR 2           ; %1 - address on 'stack' of the longer number (will store the final answer), %2 - address on 'stack' to of the shorter number   ECX=LONGER, EBX=SHORTER  
	pushad
	pushfd
	push %1
	push %2
	mov ebx, dword[%2]          ; ebx points to the first link of the shorter operand
    mov ecx, dword[%1]           ; ecx points to the first link of the longer operand
%%loopAddOr:                       ;ebx is shorter or equall in length to ecx        
    mov eax,0
    mov al, byte[ebx]           ; al = first byte of the shorter number
    pushfd
    cmp byte[operation], '|'
    je %%or_loop
    popfd
	adc byte[ecx], al             ; byte[ecx] = first byte of the final number
	pushfd
	cmp dword[ebx+1], 0        ; checking if the next address is "null" -> if so, we can stop
	je %%carry_last_link
	popfd
    mov ebx, dword[ebx+1]       ; ebx opints to the next link
    mov ecx, dword[ecx+1]       ; ecx points to the next link
    jmp %%loopAddOr
%%carry_last_link:
	popfd
	jnc %%end_add
	cmp dword[ecx+1], 0
	je %%make_carry_link
	mov ecx, dword[ecx+1]
	adc byte[ecx], 1
	pushfd
	jmp %%carry_last_link
%%make_carry_link:
	MAKE_LINK 1
	mov dword[ecx+1], eax
	jmp %%end_add
%%or_loop:
	popfd
	or byte[ecx], al             ; byte[ecx] = first byte of the final number
	cmp dword[ebx+1], 0        ; checking if the next address is "null" -> if so, we can stop
	je %%end_add
	mov ebx, dword[ebx+1]       ; ebx opints to the next link
    mov ecx, dword[ecx+1]       ; ecx points to the next link
    jmp %%loopAddOr
%%end_add:                    ; %1 is the address on the operands stack that points to the longer operand
    pop %2
    pop %1
    FREE_OPERAND dword[%2]         ; free the space of the shorter operand
	mov ebx, dword[stack_ptr]
	mov ecx, dword[%1]
	mov dword[ebx], ecx
    popfd
    popad
%endmacro
	
%macro BITWISE_AND 2          ; %1 - address on 'stack' of the shorter number (will store the final answer), %2 - addres on 'stack' to longer number (will be deleted)
    push %2
	push %1
	mov edi, %1
	mov ebx, dword[%2]          ; ebx points to the first link of the longer operand
    mov ecx, dword[%1]           ; ecx points to the first link of the shorter operand
%%loop_and:                       ;ecx is shorter or equall in length to ebx        
    mov eax,0
    mov al, byte[ebx]           ; al = first byte of the longer number
	and byte[ecx], al             ; byte[ecx] = first byte of the final number
	
	cmp dword[ecx+1], 0        ; checking if the next address is "null" -> if so, we can stop
	je %%check_for_leading_zeros
    mov ebx, dword[ebx+1]       ; ebx opints to the next link
    mov ecx, dword[ecx+1]       ; ecx points to the next link
    jmp %%loop_and
%%check_for_leading_zeros:  ; now ecx points to the last link
    cmp byte[ecx],0         ; checking if we have a non-zero digit-> we can stop dissmissing zeros
    jne %%end_and           
    cmp ecx, dword[edi]             ; checking if this is the only link -> we can stop dissmissing zeros
    je %%end_and
    mov eax, ecx         ; eax = address of the link we deleted-> we need it to check if we got to the end of the list later
    FREE ecx            ; if it is a leading zero - we free the link
%%set_ecx_as_first_link:
    mov ecx, edi          ; now ecx has the address on 'stack' of the first link
%%go_to_end:
    mov ecx, dword[ecx]     ; ecx = address of link
    cmp dword[ecx+1], eax         ; if next link's adress is equal to the link we just deleted
    je %%last_link
    inc ecx
    jmp %%go_to_end
%%last_link:
    mov dword[ecx+1],0          ;making the last link to point to null
    jmp %%check_for_leading_zeros
%%end_and:                    ; %1 is the address on the operands stack that points to the longer operand
    pop %1
    pop %2
    
    FREE_OPERAND dword[%2]         ; free the space of the longer operand
	mov ebx, dword[stack_ptr]
	mov ecx, dword[%1]
	mov dword[ebx], ecx

%endmacro

%macro OPERATION_2_NUMBERS 1
	pushad
	pushfd
    clc                             ; clear carry flag
    sub dword[stack_ptr], 4        
	mov ebx, dword[stack_ptr]      ; ebx = address of operand1 first link
	mov ebx, dword[ebx]
	sub dword[stack_ptr], 4        ; stack_ptr points to next operand
	mov ecx, dword[stack_ptr]      ; ecx = address of operand2 first link
    mov ecx, dword[ecx]
    add dword[stack_ptr], 4         ;returning stack_ptr to point to the first operand
%%check_longer_number:
    inc ecx                         ;now ecx = address of next link
    cmp dword[ecx],0                ;checking if next link is null
    je %%ebx_is_longer
    inc ebx                         ;now ebx = address of next link
    cmp dword[ebx], 0               ;checking if next link is null
    je %%ecx_is_longer
    mov ecx,dword[ecx]              ;going to next links
    mov ebx, dword[ebx]
    jmp %%check_longer_number
    
%%ebx_is_longer:                  ; eax will always point on the longer one, and edx on the shorter
    mov eax, dword[stack_ptr]
    sub dword[stack_ptr], 4
    mov edx, dword[stack_ptr]
    jmp %%after_checking_who_is_longer
    
%%ecx_is_longer:                  
    mov edx, dword[stack_ptr]
    sub dword[stack_ptr], 4
    mov eax, dword[stack_ptr]
    jmp %%after_checking_who_is_longer
    
    %%after_checking_who_is_longer:
	cmp %1 ,'+'
	je %%go_to_add
	cmp %1, '&'
	je %%go_to_bitwise_and
	cmp %1, '|'
	je %%go_to_bitwise_or
%%go_to_add:
	LOOP_ADD_OR eax, edx
	jmp %%end_operation_2_nums
	%%go_to_bitwise_and:
	BITWISE_AND edx, eax
    jmp %%end_operation_2_nums
	%%go_to_bitwise_or:
    LOOP_ADD_OR eax, edx
	jmp %%end_operation_2_nums
	%%end_operation_2_nums:
	cmp byte[fdebug], 1            		; if 1 -> debug print
	jne %%finish_operation_2_operands
	PRINT_STDERR debug_pushed_to_stack, format_calc
	DEBUG_PRINT dword[stack_ptr]
	%%finish_operation_2_operands:
	;inc dword[num_operations]			; add 1 to the operation counter
	add dword[stack_ptr], 4
	popfd
	popad
%endmacro	

%macro POP_AND_PRINT 0
    sub dword[stack_ptr], 4         ;stack_ptr points to the first operand on 'stack'
    mov ecx, dword[stack_ptr]       ; ecx = address of first operand on 'stack'
    mov ecx, dword[ecx]             ; ecx = adress of first link of operand
    mov ebx, esp                       ;ebx = last address of esp before we start pushing into the stack (so we'll know when to end the print)
    go_to_last_link:                        ; going to the last link of the operand (when stoped -> ecx has the adress of the last link (null))
    cmp ecx, 0                    ;checking if last link -> next link has 0 on 4 last bytes(null)       
    je print_number
    mov edx, 0
    mov dl, byte[ecx]
    push edx                  ; pushing the first byte (=the digit)
    inc ecx                         ; going to the last 4 bytes to get the next link's address
    mov ecx, dword[ecx]                ; ecx = address of next link
    jmp go_to_last_link
    print_number:
    pop edx
    PRINT edx, format_hexa_x
    print_rest:
    cmp esp, ebx            ; checking if we got to the last link of the number
    je end_print
    pop edx                 ; edx has the number to be printed
    PRINT edx, format_hexa  ;printing digit without '\n'
    jmp print_rest
    end_print:
    mov edx, 0xa            ; priting '\n'
    PRINT edx, format_byte
    mov ebx, dword[stack_ptr]       ;ebx = address of the 'stack' location
    before_free:
    FREE_OPERAND dword[ebx]            ; dword[ebx] = address of first link
%endmacro

%macro DUPLICATE 0              ; duplicating the last operand in 'stack'
    mov ecx, dword[stack_ptr]   
	mov dword[curr_link], ecx   ;curr_link = address of the next space available on 'stack'
    mov edx, dword[stack_ptr]   ;edx = address of the next space available on 'stack'
    sub edx, 4                  ;edx = address on 'stack' that holds the address of last operand entered 
    mov edx, dword[edx]         ;edx = address of first link    (edx = number to copy)
    dup_loop:
    cmp edx, 0
    je end_dup
    mov ebx,0
    mov bl,byte[edx]
    MAKE_LINK bl                ;bl=byte[edx] = byte to be copied, MAKE_LINK returns new address in EAX
    mov ecx, dword[curr_link]   ;ebx = address of the next space available on 'stack'
    mov dword[ecx], eax			;next address = the new link
    inc eax						;eax = 'link->next'
    mov dword[curr_link], eax   ;now curr_link = where we want to insert next link's 
    inc edx 
    mov edx, dword[edx]         ;edx = address of next link to be copied 
    jmp dup_loop
    end_dup:
    cmp byte[fdebug], 1            ;if 1 -> debug print
	jne end_dupicate
	PRINT_STDERR debug_pushed_to_stack, format_calc
	DEBUG_PRINT dword[stack_ptr]
	end_dupicate:
    add dword[stack_ptr], 4     ;stack_ptr points to the next space available
    inc byte[num_operands]
%endmacro

%macro PUSH_NUM_OF_DIGITS 0
    ;mov edx, 0          			;edx will be the difits counter
    sub dword[stack_ptr], 4         ;stack_ptr points to the first operand on 'stack'
    mov ecx, dword[stack_ptr]       ; ecx = address of first operand on 'stack'
    mov ecx,dword[ecx]
    MAKE_LINK 0                     ; this will be the list of the counter
    mov edx, eax                    ; edx = address of first link of the counter
    mov edi,edx                     ; edi = address of first link of the counter
    clc
    mov esi,0                       ; esi = FLAG ~ did we add the digits of the last link
loop_num_digits:
    pushfd
    cmp esi,1                       ; esi = FLAG ~ did we add the digits of the last link
    je end_push_num_digits
    cmp dword[ecx+1], 0                ;checking if last link -> next link has 0 on 4 last bytes(null)       
    je add_digits_of_last_link
    popfd
    mov ecx, dword[ecx+1]                ; ecx = address of next link
	adc byte[edx], 2                ; counter+=2
carry_last_link:
	jnc end_carry
	pushfd
	cmp dword[edx+1], 0
	je make_carry_link
	popfd
	mov edx, dword[edx+1]
	adc byte[edx], 1
	jmp carry_last_link
make_carry_link:
    popfd
	MAKE_LINK 1
	mov dword[edx+1], eax
end_carry:  
    mov edx, edi

    jmp loop_num_digits
    
add_digits_of_last_link:         ;ecx points to 'last->next'
    mov esi,1                   ; esi = FLAG ~ did we add the digits of the last link
    popfd
    mov eax, 0
    mov al, byte[ecx]
    pushfd
    cmp eax, 0xf             ;last link of the number could represent either 2 or 1 figits, the largest number that can represent 1 digit is 0xf
    jg add_2_digits
    popfd
    adc byte[edx], 1                ; counter+=2
	jmp carry_last_link
add_2_digits:
    popfd
	adc byte[edx], 2                ; counter+=2
	jmp carry_last_link
end_push_num_digits:
    mov ecx, dword[stack_ptr]
    FREE_OPERAND dword[ecx]         ; free the link that we just counted it's digits
    mov ebx, dword[stack_ptr]       ;dword[stack_ptr] == address of the first link
    mov dword[ebx], edi             ; now stack_ptr points on the new operand(=num of digits)
 
    cmp byte[fdebug], 1            ;if 1 -> debug print
	jne exit_push_num_digits
	PRINT_STDERR debug_pushed_to_stack, format_calc
	DEBUG_PRINT dword[stack_ptr]
exit_push_num_digits:
    add dword[stack_ptr], 4         ; now stack_ptr points to the next available place on 'stack'
    inc byte[num_operands]
%endmacro

    





check_at_least_2_operands:
    inc dword[num_operations]
	cmp byte[num_operands], 1      ;check if there are at least two operands
	jg after_2_operands            ;if so -> continue
	PRINT error_insufficient, format_normal    ;if not ->ERROR
	jmp main_loop
	after_2_operands:
	cmp byte[input_buf], '+'
	je adder                       
	cmp byte[input_buf], '&'
	je do_bitwise_and
	cmp byte[input_buf], '|'
	je do_bitwise_or
	jmp main_loop          ;need to check at the end
do_bitwise_and:
    mov byte[operation], '&'
    OPERATION_2_NUMBERS byte[operation]
    jmp main_loop
do_bitwise_or:
    mov byte[operation], '|'
    OPERATION_2_NUMBERS byte[operation]
    jmp main_loop
adder:
    mov byte[operation], '+'
    OPERATION_2_NUMBERS byte[operation]
    jmp main_loop

check_at_least_1_operand:
    inc dword[num_operations]   
    cmp byte[num_operands] ,0       ;check if there are at least 1 operand
    jg after_1_operand                ;if so -> continue
    PRINT error_insufficient, format_normal    ;if not ->ERROR
    jmp main_loop
    after_1_operand:
    cmp byte[input_buf], 'p'
    je print_and_pop
			; if not p -> 'n' or 'd' 
    cmp byte[input_buf], 'n'
    je push_num_of_digits   ; if not p and not n -> input=d (need to check space)
    jmp check_space         ; check enough space to enter new operand (for duplicate or 'n' operation)
print_and_pop:
    POP_AND_PRINT
    check_print_now:
    ;inc dword[num_operations] ; add 1 to the operation counter
    jmp main_loop
push_num_of_digits:     ;after check_at_least_1_operand
    PUSH_NUM_OF_DIGITS
    ;inc dword[num_operations]	; add 1 to the operation counter
    jmp main_loop
duplicate:              ;after check_at_least_1_operand & check_space
    DUPLICATE 
    ;inc dword[num_operations]	; add 1 to the operation counter
    jmp main_loop
