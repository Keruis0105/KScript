#include "MainWindow.h"
#include "Message.h"
#include <stdexcept>
#include <ranges>
#include <algorithm>

namespace Tools::Log {

MainWindow::MainWindow(HINSTANCE hinstance, win32::MessageLoop& loop)
    : m_hinstance(hinstance),
      m_loop(loop)
{
    if (!this->create(
        hinstance,
        L"LogWindowClass",
        L"LogViewer")
    ) {
        throw std::runtime_error("Failed to create window");
    }

    ShowWindow(this->m_hwnd, SW_SHOWNORMAL);

    m_pipeServer = new PipeServer(this->m_hwnd);
}

MainWindow::~MainWindow() {
    DestroyWindow(this->m_hwnd);
    if (m_pipeServer) {
        m_pipeServer->stop();
        delete m_pipeServer;
    }
}

void MainWindow::appendLog(const wchar_t* text) const {
    if (!m_edit || !text) return;

    static HFONT hFont = CreateFontW(
        20,
        0,
        0, 0,
        FW_NORMAL,
        FALSE, FALSE, FALSE,
        DEFAULT_CHARSET,
        OUT_DEFAULT_PRECIS,
        CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY,
        FF_DONTCARE,
        L"Consolas"
    );
    SendMessageW(m_edit, WM_SETFONT, reinterpret_cast<WPARAM>(hFont), TRUE);

    auto view = std::views::all(std::wstring_view{text});
    std::wstring buf;
    for (wchar_t c : view) {
        buf += (c == L'\n') ? L"\r\n" : std::wstring(1, c);
    }

    int len = GetWindowTextLengthW(m_edit);
    SendMessageW(m_edit, EM_SETSEL, len, len);

    SendMessageW(m_edit, EM_REPLACESEL, FALSE, reinterpret_cast<LPARAM>(buf.c_str()));

    SendMessageW(m_edit, EM_SCROLLCARET, 0, 0);
}

LRESULT MainWindow::handleMessage(UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_CREATE:
            m_edit = CreateWindowExW(
                WS_EX_CLIENTEDGE,
                L"EDIT", L"",
                WS_CHILD | WS_VISIBLE | WS_VSCROLL |
                ES_MULTILINE | ES_AUTOVSCROLL | ES_READONLY,
                0, 0, 0, 0,
                m_hwnd, nullptr, m_hinstance, nullptr
            );
            return 0;

        case WM_SIZE:
            MoveWindow(
                m_edit, 0, 0,
                LOWORD(lParam), HIWORD(lParam), TRUE);
            return 0;

        case WM_LOG_APPEND:
            appendLog(reinterpret_cast<wchar_t*>(lParam));
            free(reinterpret_cast<void*>(lParam));
            return 0;

        case WM_DESTROY:
            m_loop.quit(0);
            return 0;

        default: ;
    }

    return DefWindowProcW(m_hwnd, msg, wParam, lParam);
}



}
