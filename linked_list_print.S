//CSE 30321
//Linked List Print Code


#pragma qtrvsim show registers
#pragma qtrvsim show memory


.globl _start
.option norelax


//for printing
.equ __NR_write,       64  // ssize_t write(int fd, const void *buf, size_t count)


.text
_start:
    //***linked list "main" goes here for each assignment***


    //***DUMMY LINKED LIST CODE, DELETE THIS***
    la x8, linked_list_head
   
    ebreak


//  
//  CODE TO PRINT LIST STARTS HERE
//
    #pragma qtrvsim show terminal


    addi x31, x0, 10        //constant 10
    addi x27, x0, 32        //ascii space


    //REPLACE x8 WITH REG CONTAINING LIST HEAD POINTER
    mv x5, x8               //print code expects head in x5


    //memory space for ASCII text representation of linked list
    li x18, 0x700
   
    //outer loop iterates num_elements times
    la x29, num_elements
    lw x29, 0x0(x29)
    li x15, 0


    //for traversing the linked list
    mv x6, x5


list_loop:  
    bge x15, x29, print_it  //we are done generating ASCII, go to print it
    li x26, 4               //1 address + 3 fields in each element
    li x14, 4              
field_loop:
    bne x26, x14, field     //first time through, print the address of the element
    mv x19, x6              //copy address into x19
    j not_field
field:
    lw x19, 0x0(x6)         //load the current field of the element
not_field:
    li x30, 3               //will count 4 digits (each a nibble) of field for conversion
nbl_loop:  
    blt x30, x0, next_field //go on to next element if counter < 0
    andi x20, x19, 0xF      //mask the least significant nibble of field
    bge x20, x31, add_hex   //need to compute ASCII for letter ('A' is decimal 55)
    addi x20, x20, 48       //compute ASCII for number ('0' is decimal 48)
    j skip_ah
add_hex:    
    addi x20, x20, 55       //compute ASCII for letter
skip_ah:    
    add x28, x18, x30       //compute address to store ASCII byte (entire word for 1 field)
                            // note we need to do it backwards, e.g., 0x0604 --> '4' '0' '6' '0'
    sb x20, 0x0(x28)        //store the byte
    srli x19, x19, 4        //shift to get the next nibble
    addi x30, x30, -1       //update loop counter
    j nbl_loop


next_field:
    addi x18, x18, 4        //we just stored 4 characters (4 bytes), advance to next word of ASCII storage
    sb x27, 0x0(x18)        //fill the next word with 4 spaces
    sb x27, 0x1(x18)        //fill the next word with 4 spaces
    sb x27, 0x2(x18)        //fill the next word with 4 spaces
    sb x27, 0x3(x18)        //fill the next word with 4 spaces


    addi x18, x18, 4        //we just stored 4 characters (4 bytes), advance to next word of ASCII storage


    beq x26, x14, skip_fa   //first time through, do not update address
    addi x6, x6, 0x4        //get addr of next field
skip_fa:
    addi x26, x26, -1
    bne x26, x0, field_loop
    addi x6, x6, 0x34       //get addr of next linked list element
    sb x31, 0(x18)          //fill the LSB of the word with a newline
    sb x0, 0x1(x18)         //fill the next byte with null character
    sb x0, 0x2(x18)         //fill the next byte with null character
    sb x0, 0x3(x18)         //fill the next byte with null character
    addi x18, x18, 4        //we just stored a full element, store a newline (10)
    addi x15, x15, 1
    j list_loop
   
    //based on QtRVSim template-os.S
print_it:  
    addi  x17, x0, __NR_write       // load syscall number
    addi  x10, x0, 1                // load file descriptor
    li  x11, 0x700                  // load text address
    addi  x12, x0, 280              // load text length
    ecall                           // print the text
   
    ebreak


//  
//  CODE TO PRINT LIST ENDS HERE
//


//***Linked List functions go here***


//***HARD CODED LIST MATCHING HW02 LIST AS AN EXAMPLE ***
//*** DELETE EVERYTHING BELOW THIS LINE, REPLACE WITH YOUR .data***
.data
.org 0x1000


num_elements:
    .word  0x8
   
.org 0x3504
linked_list_head:
    .word  0x0000, 0x4815, 0x3544
.org 0x3544
    .word 0x3504, 0x1623, 0x3584
.org 0x3584
    .word 0x3544, 0x4242, 0x35C4
.org 0x35C4
    .word 0x3584, 0xFEED, 0x3604
.org 0x3604
    .word 0x35C4, 0xADAD, 0x3644
.org 0x3644
    .word 0x3604, 0xBABA, 0x3684
.org 0x3684
    .word 0x3644, 0xB0BA, 0x36C4
.org 0x36C4
    .word 0x3684, 0x1842, 0x0000
