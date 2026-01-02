BITS 64
DEFAULT REL

%ifidn __OS__, WINDOWS
    %define ARG_PTR_R rcx
    %define ARG_PTR_E ecx
%elifidn __OS__, LINUX
    %define ARG_PTR_R rdi
    %define ARG_PTR_E edi
%else
    %error "Unsupported OS"
%endif

SECTION .text

%macro DECL_STRLEN 3
GLOBAL %1
%1:
    mov rax, ARG_PTR_R
    mov r8, ARG_PTR_R

    %if %3
        vpxor ymm0, ymm0, ymm0
        and ARG_PTR_R, 31
        and rax, -32
        %define LOAD_ vmovdqa ymm1, [rax]
        %define MASK_ vpmovmskb edx, ymm1
        %define INC_ add rax, 32
        %ifidn %2, BYTE
            %define CMP_ vpcmpeqb ymm1, ymm1, ymm0
            %define BYTE_OFFSET_TO_ELEMENT_COUNT
        %elifidn %2, WORD
            %define CMP_ vpcmpeqw ymm1, ymm1, ymm0
            %define BYTE_OFFSET_TO_ELEMENT_COUNT shr rax, 1
        %elifidn %2, DWORD
            %define CMP_ vpcmpeqd ymm1, ymm1, ymm0
            %define BYTE_OFFSET_TO_ELEMENT_COUNT shr rax, 2
        %endif
    %else
        pxor xmm0, xmm0
        and ARG_PTR_R, 15
        and rax, -16
        %define LOAD_ movdqa xmm1, [rax]
        %define MASK_ pmovmskb edx, xmm1
        %define INC_ add rax, 16
        %ifidn %2, BYTE
            %define CMP_ pcmpeqb xmm1, xmm0
            %define BYTE_OFFSET_TO_ELEMENT_COUNT
        %elifidn %2, WORD
            %define CMP_ pcmpeqw xmm1, xmm0
            %define BYTE_OFFSET_TO_ELEMENT_COUNT shr rax, 1
        %elifidn %2, DWORD
            %define CMP_ pcmpeqd xmm1, xmm0
            %define BYTE_OFFSET_TO_ELEMENT_COUNT shr rax, 2
        %endif
    %endif

    LOAD_
    CMP_
    MASK_

    shr edx, cl
    shl edx, cl
    bsf edx, edx
    jnz .found_%1

.loop_%1:
    INC_
    LOAD_
    CMP_
    MASK_
    bsf edx, edx
    jz .loop_%1

.found_%1:
    sub         rax,    r8
    add         rax,    rdx
    BYTE_OFFSET_TO_ELEMENT_COUNT
    ret

%undef LOAD_
%undef CMP_
%undef MASK_
%undef INC_
%endmacro

DECL_STRLEN strlen_8bit_sse2_x86_x64,  BYTE, 0
DECL_STRLEN strlen_8bit_avx2_x86_x64,  BYTE, 1
DECL_STRLEN strlen_16bit_sse2_x86_x64, WORD, 0
DECL_STRLEN strlen_16bit_avx2_x86_x64, WORD, 1
DECL_STRLEN strlen_32bit_sse2_x86_x64, DWORD,0
DECL_STRLEN strlen_32bit_avx2_x86_x64, DWORD,1