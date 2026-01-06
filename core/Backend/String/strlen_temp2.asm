;extern fn strlen_8bit_sse2_x86_x64(ptr: [*]const u8) usize;
;extern fn strlen_16bit_sse2_x86_x64(ptr: [*]const u8) usize;
;extern fn strlen_32bit_sse2_x86_x64(ptr: [*]const u8) usize;
;extern fn strlen_8bit_avx2_x86_x64(ptr: [*]const u8) usize;
;extern fn strlen_16bit_avx2_x86_x64(ptr: [*]const u8) usize;
;extern fn strlen_32bit_avx2_x86_x64(ptr: [*]const u8) usize;

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

%define TYPE_BYTE  1
%define TYPE_WORD  2
%define TYPE_DWORD 4

%define SIMD_SSE 16
%define SIMD_AVX 32

%macro RETURN 1
    %if %1 = SIMD_AVX
        vzeroupper
    %endif
    ret
%endmacro

SECTION .text
%macro DECL_STRLEN 3
GLOBAL %1
%1:
    mov rax, ARG_PTR_R
    mov r8, ARG_PTR_R

    %define TEST_MASK bsf edx, edx
    %if %2 = TYPE_BYTE
        %define BYTE_OFFSET_TO_ELEMENT_COUNT
    %elif %2 = TYPE_WORD
        %define BYTE_OFFSET_TO_ELEMENT_COUNT shr rax, 1
    %elif %2 = TYPE_DWORD
        %define BYTE_OFFSET_TO_ELEMENT_COUNT shr rax, 2
    %endif
    %if %3 = SIMD_SSE
        %if %2 = TYPE_BYTE
            %define CMP_EQ pcmpeqb xmm1, xmm0
        %elif %2 = TYPE_WORD
            %define CMP_EQ pcmpeqw xmm1, xmm0
        %elif %2 = TYPE_DWORD
            %define CMP_EQ pcmpeqd xmm1, xmm0
        %endif
        %define MOV_MASK pmovmskb edx, xmm1
        %define VEC_SIZE 16
        %define VEC_MASK 15
        %define LOAD_VEC_A movdqa xmm1, [rax]
        pxor xmm0, xmm0
        and ARG_PTR_R, 15
        and rax, -16
    %elif %3 = SIMD_AVX
        %if %2 = TYPE_BYTE
            %define CMP_EQ vpcmpeqb ymm1, ymm1, ymm0
        %elif %2 = TYPE_WORD
            %define CMP_EQ vpcmpeqw ymm1, ymm1, ymm0
        %elif %2 = TYPE_DWORD
            %define CMP_EQ vpcmpeqd ymm1, ymm1, ymm0
        %endif
        %define MOV_MASK vpmovmskb edx, ymm1
        %define VEC_SIZE 32
        %define VEC_MASK 31
        %define LOAD_VEC_A vmovdqa ymm1, [rax]
        vpxor ymm0, ymm0, ymm0
        and ARG_PTR_R, 31
        and rax, -32
    %endif

    LOAD_VEC_A
    CMP_EQ
    MOV_MASK
    add rax, VEC_SIZE
    shr edx, cl
    TEST_MASK
    jnz .found_%1

.loop_%1:
    add rax, VEC_SIZE
    LOAD_VEC_A
    CMP_EQ
    MOV_MASK
    TEST_MASK
    jz .loop_%1

.found_%1:
    sub rax, r8
    add rax, rdx
    BYTE_OFFSET_TO_ELEMENT_COUNT
    RETURN %3

%undef TEST_MASK
%undef BYTE_OFFSET_TO_ELEMENT_COUNT
%undef CMP_EQ
%undef MOV_MASK
%undef VEC_SIZE
%undef VEC_MASK
%undef LOAD_VEC_A
%endmacro

DECL_STRLEN strlen_8bit_sse2_x86_x64,  TYPE_BYTE, SIMD_SSE
DECL_STRLEN strlen_8bit_avx2_x86_x64,  TYPE_BYTE, SIMD_AVX
DECL_STRLEN strlen_16bit_sse2_x86_x64, TYPE_WORD, SIMD_SSE
DECL_STRLEN strlen_16bit_avx2_x86_x64, TYPE_WORD, SIMD_AVX
DECL_STRLEN strlen_32bit_sse2_x86_x64, TYPE_DWORD,SIMD_SSE
DECL_STRLEN strlen_32bit_avx2_x86_x64, TYPE_DWORD,SIMD_AVX