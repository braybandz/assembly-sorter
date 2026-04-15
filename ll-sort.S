.data 
.org 0x2000 
num_elements: 
.word 0x8 
array_data: 
.word  0xAA23, 0x3263, 0x827E, 0xC3D0, 0xF2D2, 0x1337, 0xFEDA, 
0x1234 
.globl head 
head: 
.word 0                 
.text 
.org 0x200 
.globl _start 
_start: 
    la x5, num_elements 
    lw x6, 0(x5)           # num elements 
 
    la x7, array_data      # base of array 
 
    li x28, 0x300 
    add x29, x7, x28       # list base (array + 0x300) 
 
    addi x8, x29, 0        # keep original head ptr here (x8) 
 
    li x30, 0              # i = 0 
    li x31, 0              # prev = 0 
 
# loop through array 
insertLoop: 
    beq x30, x6, make_circular 
 
    slli x27, x30, 2 
    add  x10, x7, x27      # &array[i] 
 
    slli x27, x30, 6       # i * 64 (0x40 stride) 
    add  x11, x29, x27     # &node[i] 
 
    addi x12, x31, 0       # prev node 
 
    jal  x1, insert 
 
    addi x31, x11, 0       # update prev 
    addi x30, x30, 1 
    j insertLoop 
 
 
make_circular: 
    sw x8,  8(x31)         # tail.next = head (x8) 
    sw x31, 0(x8)          # head.prev = tail 
 
    la x20, head 
    sw x8, 0(x20)          # save head globally 
    #test case code 
    # bubbleSort(head) 
    la   a0, head 
    lw   a0, 0(a0) 
    jal  ra, bubbleSort 
 
    # deleteOdd(head) 
    la   a0, head 
    lw   a0, 0(a0) 
    jal  ra, deleteOdd 
 
    # recount nodes into num_elements (after deletions) 
    la   a0, head 
    lw   a0, 0(a0) 
    jal  ra, recount_store_num 
 
hang: 
    j hang 
 
#insert one node 
insert: 
    lw x13, 0(x10)         # load array val 
    sw x12, 0(x11)         # prev 
    sw x13, 4(x11)         # data 
    li x14, 0 
    sw x14, 8(x11)         # next=0 
    beq x12, x0, insert_done 
    sw x11, 8(x12)         # prev->next = new 
insert_done: 
    jr x1 
 
#bubble sort 
.globl bubbleSort 
bubbleSort: 
    addi sp, sp, -16 
    sw   ra, 12(sp) 
 
    beq  a0, x0, bs_ret          # empty 
    lw   t0, 8(a0)               # head->next 
    beq  t0, a0, bs_ret          # single 
 
bs_outer: 
    li   t6, 0                   # swapped = 0 
    la   t3, head                 
    lw   t4, 0(t3)               
 
    mv   t1, t4                  # t1 = left 
bs_inner: 
    lw   t2, 8(t1)               # t2 = right = left->next 
    beq  t2, t4, bs_endpass      # wrapped -> end of pass 
 
    lw   t5, 4(t1)               # left->data 
    lw   a4, 4(t2)               # right->data   (use a4 instead of t7) 
    sltu a5, a4, t5              # a5 = (right < left) (use a5 
instead of t8) 
    beq  a5, x0, bs_advance_no_swap 
 
    # do swap(left) 
    addi sp, sp, -16 
    sw   ra, 12(sp) 
    mv   a0, t1 
10 of 15  
    jal  ra, swap 
    lw   ra, 12(sp) 
    addi sp, sp, 16 
 
    li   t6, 1                   # swapped = true 
    lw   t1, 8(t1)               # after swap, left moves to next2 
(A->next) 
    j    bs_inner 
 
bs_advance_no_swap: 
    mv   t1, t2                  # left = right 
    j    bs_inner 
 
bs_endpass: 
    beq  t6, x0, bs_ret          # if !swapped -> done 
    j    bs_outer 
 
bs_ret: 
    lw   ra, 12(sp) 
    addi sp, sp, 16 
    ret 
     
# deleteOdd(a0=head)  
.globl deleteOdd 
deleteOdd: 
    addi sp, sp, -16 
    sw   ra, 12(sp) 
 
do_pass: 
    li   t6, 0                   # deleted = 0 
    la   t3, head 
    lw   t4, 0(t3)               # h = head (start-of-pass snapshot) 
    beq  t4, x0, do_pass_done    # empty -> done 
 
    mv   t1, t4                  # p = h 
del_loop: 
    # if list went empty mid-pass 
    la   t3, head 
    lw   t0, 0(t3) 
    beq  t0, x0, pass_end 
 
    lw   t2, 8(t1)               # next = p->next  (grab BEFORE 
possible delete) 
    lw   t5, 4(t1)               # data 
    andi a4, t5, 1               # odd? 
    beq  a4, x0, no_del          # even -> skip 
 
    # If we're deleting the snapshot start node, move the snapshot 
forward 
    beq  t1, t4, adjust_snapshot 
11 of 15  
    j    do_delete 
adjust_snapshot: 
    mv   t4, t2                  # new start-of-pass is the next node 
 
do_delete: 
    # delete(p) 
    addi sp, sp, -16 
    sw   ra, 12(sp) 
    mv   a0, t1 
    jal  ra, delete 
    lw   ra, 12(sp) 
    addi sp, sp, 16 
    li   t6, 1                   # deleted = 1 
 
no_del: 
    mv   t1, t2                  # p = next 
    bne  t1, t4, del_loop        # loop while p != snapshot start 
 
pass_end: 
    bne  t6, x0, do_pass         # if deleted this pass, repeat 
 
do_pass_done: 
    lw   ra, 12(sp) 
    addi sp, sp, 16 
    ret 
 
.globl recount_store_num 
recount_store_num: 
    la   t1, num_elements 
    beq  a0, x0, rsn_zero 
    li   t2, 1 
    lw   t3, 8(a0)          # n = head->next 
    beq  t3, a0, rsn_store  # single 
rsn_loop: 
    addi t2, t2, 1 
    lw   t3, 8(t3) 
    bne  t3, a0, rsn_loop 
rsn_store: 
    sw   t2, 0(t1) 
    ret 
rsn_zero: 
    sw   x0, 0(t1) 
    ret 
 
# same as hw03 
 
.globl swap 
swap: 
    beq     a0, x0, done_swap 
    lw      t0, 8(a0)          # next 
12 of 15  
    beq     t0, a0, done_swap  # single node 
 
    la      t6, head 
    lw      t5, 0(t6)          # curr head 
    lw      t4, 0(t5)          # tail = head->prev 
 
    lw      t1, 0(a0)          # prev 
    lw      t2, 8(t0)          # next2 
 
    sw      t0, 8(t1)          # prev->next = next 
    sw      t1, 0(t0)          # next->prev = prev 
    sw      a0, 8(t0)          # next->next = a0 
    sw      t0, 0(a0)          # a0->prev  = next 
    sw      t2, 8(a0)          # a0->next  = next2 
    sw      a0, 0(t2)          # next2->prev = a0 
 
    beq     t5, a0, set_head_to_B 
    beq     t4, a0, set_head_to_A 
    j       done_swap 
set_head_to_B: 
    sw      t0, 0(t6)          # head = next 
    j       done_swap 
set_head_to_A: 
    sw      a0, 0(t6)          # head = a0 (tail case) 
done_swap: 
    ret 
 
# delete a node HW03 
.globl delete 
delete: 
    beq     a0, x0, done_delete 
 
    la      t6, head 
    lw      t5, 0(t6)          # head 
    beq     t5, x0, done_delete 
 
    lw      t0, 8(t5)          # head->next 
    bne     t0, t5, check_two_nodes 
    bne     a0, t5, done_delete 
    sw      x0, 0(t6)          # single -> empty 
    ret 
 
check_two_nodes: 
    lw      t1, 8(t0)          # head->next->next 
    bne     t1, t5, more_than_two 
    sw      x0, 0(t6)          # exactly 2 -> empty 
    ret 
 
more_than_two: 
    lw      t2, 0(a0)          # prev 
13 of 15  
    lw      t3, 8(a0)          # next 
    sw      t3, 8(t2)          # prev->next = next 
    sw      t2, 0(t3)          # next->prev = prev 
    beq     a0, t5, update_head 
    j       done_delete 
update_head: 
    sw      t3, 0(t6)          # head = next 
done_delete: 
    ret 
