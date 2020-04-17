TITLE Designing low-level I/O procedures     (Program06-pittenja.asm)

; Author: Jay Pittenger
; Last Modified: 3/10/2020
; OSU email address: pittenja@oregonstate.edu
; Course number/section: CS271-400
; Project Number: Program 06                 Due Date: 03/15/2020
; Description: Program uses macros to obtain strings and display strings from and to user. Program performs input validation
; and converts input string to signed integer. Program then stores 10 of these integer inputs from user in an array, calculates 
; average and sum, and converts these values all back to strings to display to the user.

INCLUDE Irvine32.inc

; macro to perform print out of string to user
displayString	MACRO	string_print_offset
	push	edx
	mov		edx, string_print_offset
	call	WriteString
	pop		edx
ENDM

;macro to get string input from user
getString		MACRO	string_name_offset
	push	edx
	push	ecx
	mov		edx, string_name_offset		
	mov		ecx, 32
	call	ReadString
	pop		ecx
	pop		edx
ENDM

MAXSIZE     = 100

.data
title_str			BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures", 0
name_str			BYTE	"Written by: Jay Pittenger", 0
instruct_1			BYTE	"Please provide 10 signed decimal integers.", 0
instruct_2			BYTE	"Each number needs to be small enough to fit inside a 32 bit register.", 0
instruct_3			BYTE	"After you have finished inputting the raw numbers I will display a list", 0
instruct_4			BYTE	"of the integers, their sum, and their average value.", 0
prompt				BYTE	"Please enter a signed number: ", 0
signed_error		BYTE	"ERROR: You did not enter a signed number or your number was too big.", 0
again_prompt		BYTE	"Please try again: ", 0
num_str				BYTE	"You entered the following numbers:", 0
sum_str				BYTE	"The sum of these numbers is: ", 0
ave_str				BYTE	"The rounded average is: ", 0
thanks_str			BYTE	"Thanks for playing!", 0
comma_space			BYTE	", ", 0
numArray			DWORD	10 DUP(?)		; storage location for array of 10 integers
sum_num				DWORD	?				; storage location for sum of array integers
ave_num				DWORD	?				; storage location for average of array integers
int_val				DWORD	?				; temporary integer storage location
array_el			DWORD	0				; temporary array element index integer storage location
string_val			BYTE    MAXSIZE DUP(?)	; temporary input string storage location
string_val_print	BYTE    MAXSIZE DUP(?)	; temporary output string storage location

.code
main PROC

; program introduction
displayString	OFFSET title_str
call			CrLf
displayString	OFFSET name_str
call			CrLf
call			CrLf
displayString	OFFSET instruct_1
call			CrLf
displayString	OFFSET instruct_2
call			CrLf
displayString	OFFSET instruct_3
call			CrLf
displayString	OFFSET instruct_4
call			CrLf
call			CrLf


; get user input and store in numArray
readValLoop:
mov		ecx, array_el
cmp		ecx, 10
je		endReadValLoop						; end of array reached - jump to end of loop
mov		array_el, ecx

push	OFFSET prompt
push	OFFSET signed_error
push	OFFSET again_prompt
push	OFFSET string_val
push	OFFSET int_val
call	readVal								; call procedure to read value from user input

push	OFFSET numArray
push	int_val
push	array_el
call	appendArray							; call procedure to add integer to array

mov		ecx, array_el
inc		ecx									; increment array element index
mov		array_el, ecx
jmp		readValLoop

endReadValLoop:
call	CrLf

; perform sum and average calculations
push	OFFSET numArray
push	OFFSET ave_num
push	OFFSET sum_num
call	sumAveArray


; print out 10 array values to user
displayString	OFFSET num_str				; display array list information string
call	CrLf
mov		ecx, 0
mov		array_el, ecx						; reset array element index
writeArrayLoop:

push	OFFSET numArray
push	array_el
push	OFFSET int_val
call	getArrayEl							; call procedure to get element from array

push	OFFSET string_val_print
push	int_val	
call	writeVal							; call write value to print value

mov		ecx, array_el
inc		ecx									; increment array element index
mov		array_el, ecx
cmp		ecx, 10								; check if last element has been printed
je		endWriteArrayLoop
displayString	OFFSET comma_space			; if not last val - display a comma and space after element
jmp		writeArrayLoop

endWriteArrayLoop:

; print sum to user
call	CrLf
displayString	OFFSET sum_str
push	OFFSET string_val_print
push	sum_num
call	writeVal							; call WriteVal procedure to print sum
call	CrLf

; print average to user
displayString	OFFSET ave_str
push	OFFSET string_val_print
push	ave_num
call	writeVal							; call WriteVal procedure to print ave
call	CrLf
call	CrLf

; print thanks for playing message
displayString	OFFSET thanks_str

	exit	; exit to operating system
main ENDP


;-----------------------------------------------------------------------------------------------------------------
;Procedure to get signed integer from user
;recieves: prompt(by reference), error_string(by reference), again_prompt(by reference), string_val(by reference)
;storage location for valid integer-int_val
;returns: valid signed 32-bit integer 
;registers changed: none
;-----------------------------------------------------------------------------------------------------------------
readVal PROC

; local variables
ten				EQU	DWORD PTR [ebp-4]
string_length	EQU	DWORD PTR [ebp-8]
ascii_num_min	EQU	DWORD PTR [ebp-12]
multiplier		EQU	DWORD PTR [ebp-16]
	
	pushad
	push	ebp
	mov		ebp,esp
	sub		esp, 16							; room for local variable on stack
	displayString [ebp+56]					; display prompt
	mov		ten, 10							; initialize local variable ten
	mov		ascii_num_min, 48				; initialize local variable ascii_num_min
notNumRestart:
	mov		esi, [ebp+44]					; move storage adress for string into esi
	getString esi							; get string from user
	mov		string_length, eax				; store length of string
	cld
	mov		ebx, 0							; set initial integer value to 0
	mov		multiplier, 1					; initialize multiplier
	mov		ecx, string_length				; initialize loop counter

	lodsb									; check if number is negative and adjust multiplier if needed
	cmp		al, 45
	jne		notNeg
	mov		multiplier, -1
notNeg:										; number is positive
	std
	dec		esi
	add		esi, ecx						; set first load byte to end of string
	dec		esi
	mov		eax, 0							; initialize eax to 0

valReadLoop:
	lodsb									; load current byte
	movzx	eax, al							; extend value in al to eax
	cmp		eax, 48							; compare byte to 48 - integer '0' in ascii
	jl		notNum		
	cmp		eax, 57							; compare byte to 57 - integer '9' in ascii
	jg		notNum
	sub		eax, 48							; convert to correct integer value
	imul	multiplier						; set it to correct place value
	jo		notPlusMinus					; result is too large - redo user prompt
	add		ebx, eax						; add currrent value to running integer total
	jo		notPlusMinus					; result is too large - redo user prompt
	mov		eax, multiplier					; increment multiplier by factor of 10
	imul	ten
	mov		multiplier, eax
	loop	valReadLoop
	jmp		endValReadLoop

notNum:
	cmp		ecx, 1							; check if non integer character is the first character in string
	jne		notPlusMinus
	cmp		string_length, 1
	je		notPlusMinus					; check if symbol is the only character in array
	cmp		eax, 43							; compare to ascii value for '+'
	je		endValReadLoop
	cmp		eax, 45							; compare to ascii value for '-'
	je		endValReadLoop

notPlusMinus:								; character is not integer, or first char in string is not '+' or '-'
	displayString [ebp+52]
	call	CrLf
	displayString [ebp+48]
	jmp		notNumRestart					; redo prompt for signed integer from user

endValReadLoop:
	mov		ecx, [ebp+40]
	mov		[ecx], ebx						; move integer result into int_val
	mov		esp, ebp						; remove local variable from stack
	pop		ebp
	popad
	ret		20

readVal ENDP


;-----------------------------------------------------------------------------------------------------------------
;Procedure to append value to array
;recieves: array(by reference), value(by value), element_index(by value)
;returns: array with value appended to it 
;registers changed: none
;-----------------------------------------------------------------------------------------------------------------
appendArray PROC

; local variables
multiplier	EQU	DWORD PTR [ebp-4]

	pushad
	push	ebp
	mov		ebp,esp
	sub		esp, 4							; room for local variable on stack
	mov		edi,[ebp+48]					; address of array moved into edi
	mov		ebx, [ebp+44]					; value to be appended moved into ebx
	mov		eax, [ebp+40]					; element index for array into eax
	mov		multiplier, 4
	mul		multiplier						; multiply by four to get correct offset
	add		edi, eax
	mov		[edi], ebx						; move value into array at correct index
	mov		esp, ebp						; remove local variable from stack
	pop		ebp
	popad
	ret		12

appendArray ENDP


;-----------------------------------------------------------------------------------------------------------------
;Procedure to get element from array
;recieves: array(by reference), element_index(by value), value_storage_loc(by reference)
;returns: element @ element_index stored in value_storage_loc
;registers changed: none
;-----------------------------------------------------------------------------------------------------------------
getArrayEl PROC

; local variables
multiplier	EQU	DWORD PTR [ebp-4]

	pushad
	push	ebp
	mov		ebp,esp
	sub		esp, 4							; room for local variable on stack
	mov		esi,[ebp+48]					; address of array moved into esi
	mov		eax, [ebp+44]					; element index for array into eax
	mov		ebx, [ebp+40]					; value storage address into ebx
	mov		multiplier, 4
	mul		multiplier						; multiply for correct offset in array
	mov		ecx, [esi+eax]			
	mov		[ebx], ecx						; move element into address at ebx
	mov		esp, ebp						; remove local variable from stack
	pop		ebp
	popad
	ret		12

getArrayEl ENDP


;-----------------------------------------------------------------------------------------------------------------
;Procedure to print integer
;recieves: string_val_print(by reference), integer(by value)
;returns: none - integer is printed to user as a string
;registers changed: none
;preconditions: integer must be within range of 32-bit signed integer size. string_val_print must be large enough
;to hold 11 characters.
;-----------------------------------------------------------------------------------------------------------------
writeVal PROC

; local variables
rem_divisor	EQU	DWORD PTR [ebp-4]
div_ten		EQU	DWORD PTR [ebp-8]

	pushad
	push	ebp
	mov		ebp,esp
	sub		esp, 8							; room for local variable on stack
	mov		rem_divisor, 1000000000			; initialize divisor
	mov		div_ten, 10						; initialize ten
	mov		ebx, [ebp+40]					; integer into ebx
	mov		edi, [ebp+44]					; move storage adress for string into edi
	mov		ecx, 0
	mov		eax, 0
	cld										; set direction to move forward in stored string

; determine sign symbol to add in front of integer string
	cmp		ebx, 0							
	jl		negative_num
	mov		al, 43							; add '+' to beginning of string
	stosb
	cmp		ebx, 0
	jg		stringConvertLoop
	mov		al, 48							; if integer is zero, just print "+0" as string and skip loop
	stosb
	jmp		valPrint
negative_num:
	mov		al, 45							; add '-' to beginning of string
	stosb

; handle min negative number
	cmp		ebx, -2147483648				; if value is minimum negative 32 bit signed integer, increment before twos complement
	jne		main_neg
	;
	inc		ebx

main_neg:									; number is negative but not minimum negative
	neg		ebx								; change ebx to positive number for string processing

stringConvertLoop:
	mov		eax, ebx
	cdq
	idiv	rem_divisor	
	cmp		eax, 0							; next digit to be added is in eax
	je		zero							; if eax is zero, jump to zero section to handle correctly based on loc of zero in int

;handle minimum 32-bit negative number
	mov		edx, rem_divisor
	cmp		edx, 1							; check if current digit to add to string is last digit in integer
	jne		notLastMinNeg
	mov		edx, [ebp+40]
	cmp		edx, -2147483648				; if integer being converted is equal to minimum 32-bit signed integer
	jne		notLastMinNeg
	inc		eax								; change last digit to '8' instead of '7'

notLastMinNeg:
	add		al, 48							; set digit to proper ascii value
	stosb									; store in string_val
	sub		al, 48
; multiply by divisor to remove digit just added to string from integer 
	movzx	eax, al
	mul		rem_divisor
	sub		ebx, eax						; remove highest order digit from integer
	mov		ecx, 1							; set ecx equal to 1 - this means non-zero int character has been added to string
	jmp		stringConvertContinue

zero:
	cmp		ecx, 0							; if non-zero integer has not yet been added to string - do not add a zero character
	je		stringConvertContinue
	mov		al, 48
	stosb
stringConvertContinue:
	mov		eax, rem_divisor
	cdq
	div		div_ten
	mov		rem_divisor, eax
	cmp		eax, 1							; if divisor has not yet reached zero, continue loop through integer
	jge		stringConvertLoop

valPrint:
	displayString [ebp+44]					; display converted integer string
	
; reset string storage location to clear for next use of procedure
	mov		edi, [ebp+44]
	mov		ecx, 11
	cld
resetStringLoop:
	mov		al, 0
	stosb
	loop resetStringLoop

	mov		esp, ebp						; remove local variable from stack
	pop		ebp
	popad
	ret		8

writeVal ENDP


;-----------------------------------------------------------------------------------------------------------------
;Procedure to add all elements of array together to calculate sum and average
;recieves: array(by reference), ave_mem_location(by reference) sum_mem_location(by reference)
;returns: sum of array elements in sum_mem_location, ave of array elements in ave_mem_location 
;registers changed: none
;preconditions: array must have 10 integer array elements
;-----------------------------------------------------------------------------------------------------------------
sumAveArray PROC

; local variables
divisor	EQU	DWORD PTR [ebp-4]
	
	pushad
	push	ebp
	mov		ebp,esp
	sub		esp, 4							; room for local variable on stack
	mov		esi,[ebp+48]					; address of array moved into esi
	mov		ebx, [ebp+40]					; sum value storage address into ebx

; perform sum calculation
	mov		ecx, 0							; array index
	mov		eax, 0							; initialize sum
arraySumLoop:
	add		eax, [esi+ecx]	
	add		ecx, 4
	cmp		ecx, 40							; end of array has been reached - end loop
	je		endArraySumLoop
	jmp		arraySumLoop

endArraySumLoop:
	mov		[ebx], eax						; move sum into address at eax
	mov		divisor, 10						; initialize divisor to 10
; if sum is negative, adjust division process for average calculation
	cmp		eax, 0
	jge		aveCalc
	neg		eax								; make dividend positive
	mov		divisor, -10					; make divisor negative to preserve sign

; perform average calculation
aveCalc:
	cdq
	idiv	divisor							; divide sum by 10
	mov		ebx, [ebp+44]					; move average storage address into ebx
	mov		[ebx], eax						; move average value into storage location
	mov		esp, ebp						; remove local variable from stack
	pop		ebp
	popad
	ret		12

sumAveArray ENDP


END main
