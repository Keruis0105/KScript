BITS 64
DEFAULT REL

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

