#include <windows.h>
#include <string>
#include <iostream>

int main()
{
    // 打开管道（宽字符版本）
    HANDLE pipe = CreateFileW(
        L"\\\\.\\pipe\\LogWindowPipe", // 宽字符管道名
        GENERIC_WRITE,
        0, nullptr, OPEN_EXISTING, 0, nullptr
    );

    if (pipe == INVALID_HANDLE_VALUE)
    {
        std::wcerr << L"Failed to open pipe\n";
        return 1;
    }

    // 构造要发送的日志（wchar_t）
    std::wstring log = L"这是中文日志 🌟\n";

    DWORD written;
    BOOL ok = WriteFile(
        pipe,
        log.c_str(),
        static_cast<DWORD>(log.size() * sizeof(wchar_t)), // 注意单位是字节
        &written,
        nullptr
    );

    if (!ok)
    {
        std::wcerr << L"WriteFile failed\n";
        CloseHandle(pipe);
        return 1;
    }

    CloseHandle(pipe);
    std::wcout << L"Log sent successfully\n";
    return 0;
}