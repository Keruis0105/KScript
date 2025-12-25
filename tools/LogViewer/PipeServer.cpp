#include "PipeServer.h"
#include "Message.h"

#include <windows.h>
#include <thread>

namespace Tools::Log {
PipeServer::PipeServer(HWND targetWnd)
: m_targetWnd(targetWnd),
  m_thread(&PipeServer::run, this)
{ }

PipeServer::~PipeServer() {
    stop();
}

void PipeServer::run() const {
    while (m_running) {
        HANDLE pipe = CreateNamedPipeW(
            L"\\\\.\\pipe\\LogWindowPipe",
            PIPE_ACCESS_INBOUND,
            PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT,
            PIPE_UNLIMITED_INSTANCES,
            4096, 4096,
            0, nullptr
        );

        if (pipe == INVALID_HANDLE_VALUE)
            return;

        BOOL connected =
            ConnectNamedPipe(pipe, nullptr) ||
            GetLastError() == ERROR_PIPE_CONNECTED;

        if (connected) {
            wchar_t buf[1024];
            DWORD read = 0;

            while (ReadFile(pipe, buf, sizeof(buf) - sizeof(wchar_t), &read, nullptr)) {
                size_t wlen = read / sizeof(wchar_t);
                buf[wlen] = 0;
                wchar_t* copy = _wcsdup(buf);

                PostMessageW(
                    m_targetWnd,
                    WM_LOG_APPEND,
                    0,
                    reinterpret_cast<LPARAM>(copy)
                );
            }
        }

        CloseHandle(pipe);
    }
}

void PipeServer::stop() {
    m_running = false;

    HANDLE h = CreateFileW(
        L"\\\\.\\pipe\\LogWindowPipe",
        GENERIC_WRITE,
        0, nullptr, OPEN_EXISTING, 0, nullptr
    );
    if (h != INVALID_HANDLE_VALUE) CloseHandle(h);

    if (m_thread.joinable())
        m_thread.join();
}
}

