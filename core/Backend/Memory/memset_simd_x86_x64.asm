BITS 64
DEFAULT REL

extern _NTStoreThreshold

%ifidn __OS__, WINDOWS
    %define ARG1_REG_R rcx
    %define ARG2_REG_R rdx
    %define ARG3_REG_R r8
    %define ARG1_REG_E ecx
    %define ARG2_REG_E edx
    %define ARG3_REG_E r8d
    %define ARG2_REG_L dl
%elifidn __OS__, LINUX
    %define ARG1_REG_R rdi
    %define ARG2_REG_R rsi
    %define ARG3_REG_R rdx
    %define ARG1_REG_E edi
    %define ARG2_REG_E esi
    %define ARG3_REG_E edx
    %define ARG2_REG_L si
%else
    %error "Unsupported OS"
%endif

SECTION .data
MemsetJTab dq MemsetSmall0, MemsetSmall1, MemsetSmall2, MemsetSmall3
           dq MemsetSmall4, MemsetSmall5, MemsetSmall6, MemsetSmall7
           dq MemsetSmall8, MemsetSmall9, MemsetSmall10, MemsetSmall11
           dq MemsetSmall12, MemsetSmall13, MemsetSmall14, MemsetSmall15
           dq MemsetSmall16, MemsetSmall17, MemsetSmall18, MemsetSmall19
           dq MemsetSmall20, MemsetSmall21, MemsetSmall22, MemsetSmall23
           dq MemsetSmall24, MemsetSmall25, MemsetSmall26, MemsetSmall27
           dq MemsetSmall28, MemsetSmall29, MemsetSmall30, MemsetSmall31
           dq MemsetSmall32

SECTION .text

%macro DECL_MEMSET 2
GLOBAL %1
%1:
    mov r9, ARG1_REG_R
    movzx eax, ARG2_REG_L
    mov r11, ARG3_REG_R
    mov r10, 0x0101010101010101
    imul rax, r10
    %if %2  ;avx
        cmp r11d, 32
    %else   ;sse
        cmp r11d, 16
    %endif
    ja FillLargeBlock_%1
    lea r10, [rel MemsetJTab]
    jmp [r10 + r11 * 8]

FillLargeBlock_%1:
    %if %2  ; avx
        %define VEC_SIZE_ 32
        %define VEC_MASK_ -32
        %define STORE_TAIL_A_ vmovdqa [r9 + r11], ymm0
        %define STORE_TAIL_U_ vmovdqu [r9 + r11], ymm0
        %define INC_ add r9, 32
        movd        xmm0, eax
        vpbroadcastb ymm0, xmm0
        vmovdqu [r9], ymm0
    %else   ; sse
        %define VEC_SIZE_ 16
        %define VEC_MASK_ -16
        %define STORE_TAIL_A_ movdqa [r9 + r11], xmm0
        %define STORE_TAIL_U_ movdqu [r9 + r11], xmm0
        %define INC_ add r9, 16
        movd xmm0, eax
        pshufd xmm0, xmm0, 0
        movq [r9], xmm0
        movq [r9 + 8], xmm0
    %endif
    cmp r11, [_NTStoreThreshold]
    ja NT_FillLargeBlock_%1

    lea r11, [r9 + r11 - 1]
    and r11, VEC_MASK_

    add r9, VEC_SIZE_
    and r9, VEC_MASK_

    sub r9, r11
    jnl TailPart_%1

RegularLoop_%1:
    STORE_TAIL_A_
    INC_
    jnz RegularLoop_%1

TailPart_%1:
    mov rax, ARG1_REG_R
    mov r11, ARG3_REG_R
    mov r10, r11
    sub r10, VEC_SIZE_

    %if %2  ; AVX2
        vmovdqu [rax + r10], ymm0
    %else   ; SSE2
        movq [rax + r10], xmm0
        movq [rax + r10 + 8], xmm0
    %endif
    ret

NT_FillLargeBlock_%1:
    lea r11, [r9 + r11 - 1]
    and r11, VEC_MASK_
    add r9, VEC_SIZE_
    and r9, VEC_MASK_
    sub r9, r11
    jnl NT_TailPart_%1

NT_RegularLoop_%1:
    STORE_TAIL_U_
    INC_
    jnz NT_RegularLoop_%1

NT_TailPart_%1:
    mov rax, ARG1_REG_R
    mov r11, ARG3_REG_R
    mov r10, r11
    sub r10, VEC_SIZE_

    %if %2  ; AVX2
        vmovdqu [rax + r10], ymm0
    %else   ; SSE2
        movq [rax + r10], xmm0
        movq [rax + r10 + 8], xmm0
    %endif
    ret
%undef VEC_MASK_
%undef VEC_SIZE_
%undef LOAD_
%undef INC_
%endmacro

DECL_MEMSET memset_sse2_x86_x64, 0
DECL_MEMSET memset_avx2_x86_x64, 1

%macro RETURN_DEST 0
    mov rax, ARG1_REG_R
    ret
%endmacro

MemsetSmall32: mov [r9 + 24], rax
MemsetSmall24: mov [r9 + 16], rax
MemsetSmall16: mov [r9 + 8], rax
MemsetSmall8:  mov [r9], rax
MemsetSmall0:  RETURN_DEST
MemsetSmall31: mov [r9 + 23], rax
MemsetSmall23: mov [r9 + 15], rax
MemsetSmall15: mov [r9 + 7], rax
MemsetSmall7:  mov [r9 + 3], eax
MemsetSmall3:  mov [r9 + 1], ax
MemsetSmall1:  mov [r9], al
               RETURN_DEST
MemsetSmall30: mov [r9 + 22], rax
MemsetSmall22: mov [r9 + 14], rax
MemsetSmall14: mov [r9 + 6], rax
MemsetSmall6:  mov [r9 + 2], eax
MemsetSmall2:  mov [r9], ax
               RETURN_DEST
MemsetSmall29: mov [r9 + 21], rax
MemsetSmall21: mov [r9 + 13], rax
MemsetSmall13: mov [r9 + 5], rax
MemsetSmall5:  mov [r9 + 1], eax
               mov [r9], al
               RETURN_DEST
MemsetSmall28: mov [r9 + 20], rax
MemsetSmall20: mov [r9 + 12], rax
MemsetSmall12: mov [r9 + 4], rax
MemsetSmall4:  mov [r9], eax
               RETURN_DEST
MemsetSmall27: mov [r9 + 19], rax
MemsetSmall19: mov [r9 + 11], rax
MemsetSmall11: mov [r9 + 3], rax
               mov [r9 + 1], ax
               mov [r9], al
               RETURN_DEST
MemsetSmall26: mov [r9 + 18], rax
MemsetSmall18: mov [r9 + 10], rax
MemsetSmall10: mov [r9 + 2], rax
               mov [r9], ax
               RETURN_DEST
MemsetSmall25: mov [r9 + 17], rax
MemsetSmall17: mov [r9 + 9], rax
MemsetSmall9:  mov [r9 + 1], rax
               mov [r9], al
               RETURN_DEST