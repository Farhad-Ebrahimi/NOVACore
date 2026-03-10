	.file	"fadd_s.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_f2p2_zicsr2p0_zmmul1p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.text.exception_handler,"ax",@progbits
	.align	2
	.globl	exception_handler
	.type	exception_handler, @function
exception_handler:
	li	a4,-2147483648
	addi	a4,a4,31
	li	a5,-2147483648
	and	a0,a0,a4
	addi	a5,a5,16
	beq	a0,a5,.L4
	ret
.L4:
	lw	a5,0(zero)
	ebreak
	.size	exception_handler, .-exception_handler
	.section	.text.startup.main,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-16
	li	a5,4
	sw	a5,4(sp)
	li	a5,5
	sw	a5,8(sp)
	lw	a5,4(sp)
	lw	a4,8(sp)
	li	a0,0
	mul	a5,a5,a4
	sw	a5,12(sp)
	addi	sp,sp,16
	jr	ra
	.size	main, .-main
	.ident	"GCC: (GNU) 15.1.0"
	.section	.note.GNU-stack,"",@progbits
