	.file	"fputest.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_f2p2_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.text.uart_tx_string.constprop.0,"ax",@progbits
	.align	2
	.type	uart_tx_string.constprop.0, @function
uart_tx_string.constprop.0:
	lui	a2,%hi(uart0)
.L2:
	lbu	a4,0(a0)
	bne	a4,zero,.L4
	ret
.L4:
	lw	a3,%lo(uart0)(a2)
.L3:
	lw	a5,8(a3)
	andi	a5,a5,8
	bne	a5,zero,.L3
	sw	a4,0(a3)
	addi	a0,a0,1
	j	.L2
	.size	uart_tx_string.constprop.0, .-uart_tx_string.constprop.0
	.section	.text.exception_handler,"ax",@progbits
	.align	2
	.globl	exception_handler
	.type	exception_handler, @function
exception_handler:
	bge	a0,zero,.L6
	andi	a5,a0,16
	beq	a5,zero,.L6
	andi	a0,a0,15
	bne	a0,zero,.L6
	lui	a5,%hi(timer0)
	lw	a4,%lo(timer0)(a5)
	lw	a5,0(a4)
	ori	a5,a5,2
	sw	a5,0(a4)
.L6:
	ret
	.size	exception_handler, .-exception_handler
	.section	.rodata.main.str1.4,"aMS",@progbits,1
	.align	2
.LC0:
	.string	"--- FPU Test Application ---\r\n\n"
	.align	2
.LC3:
	.string	"\r\n"
	.section	.text.startup.main,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-48
	li	a5,-1073733632
	lui	a4,%hi(uart0)
	sw	ra,44(sp)
	sw	a5,%lo(uart0)(a4)
	lui	a0,%hi(.LC0)
	li	a4,96
	sw	a4,12(a5)
	addi	a0,a0,%lo(.LC0)
	call	uart_tx_string.constprop.0
	lui	a5,%hi(timer0)
	li	a4,-1073741824
	sw	a4,%lo(timer0)(a5)
	li	a3,2
	sw	a3,0(a4)
	lw	a4,%lo(timer0)(a5)
	li	a5,179998720
	addi	a5,a5,1280
	sw	a5,4(a4)
	li	a5,3
	sw	a5,0(a4)
	li	a5,16777216
 #APP
# 78 "../../../potato.h" 1
	csrs mie, a5

# 0 "" 2
# 43 "fputest.c" 1
	csrsi mstatus, 1 << 3

# 0 "" 2
 #NO_APP
	lui	a5,%hi(.LC1)
	lw	a1,%lo(.LC1)(a5)
	lui	a5,%hi(.LC2)
	lw	a0,%lo(.LC2)(a5)
	call	mul
	mv	a1,sp
	li	a2,4
	call	fp2str
	mv	a0,sp
	call	uart_tx_string.constprop.0
	lui	a0,%hi(.LC3)
	addi	a0,a0,%lo(.LC3)
	call	uart_tx_string.constprop.0
	lw	ra,44(sp)
	li	a0,0
	addi	sp,sp,48
	jr	ra
	.size	main, .-main
	.section	.sbss.timer0,"aw",@nobits
	.align	2
	.type	timer0, @object
	.size	timer0, 4
timer0:
	.zero	4
	.section	.sbss.uart0,"aw",@nobits
	.align	2
	.type	uart0, @object
	.size	uart0, 4
uart0:
	.zero	4
	.section	.srodata.cst4,"aM",@progbits,4
	.align	2
.LC1:
	.word	1076754509
	.align	2
.LC2:
	.word	1078530000
	.ident	"GCC: (g1ea978e3066) 12.1.0"
