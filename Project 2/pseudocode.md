pseudocode for outlining/dividing work -- feel free to use for designing functions
(this is a markdown file, but you can just treat it as a text file)

***

.data


.code
main proc
    _loop:
        get user input
        get first char of input
        switch first char:
            case digit: 
                push_num
            case '-':
                if number: push_num
                else: minus_op
            case '+': plus_op
            case '*': mul_op
            case '/': div_op
            case 'x': exchange_top_two
            case 'u': roll_stack_up
            case 'd': roll_stack_down
            case 'v': print_stack
            case 'c': clear_stack
            case 'q': jump _quit
            default: print error
        if quit jump _out
        jump _loop
    _out:
    quit
main endp

// ------------------- push onto stack, operations -------------------

push_num proc
push_num endp

minus_op proc
minus_op endp

mul_op proc
mul_op endp

div_op proc
div_op endp

// ------------------- commands -------------------

exchange_top_two proc
exchange_top_two endp

roll_stack_up proc
roll_stack_up endp

roll_stack_down proc
roll_stack_down endp

print_stack proc
print_stack endp

clear_stack proc
clear_stack endp