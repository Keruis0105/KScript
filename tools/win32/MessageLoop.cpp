#include "MessageLoop.h"

namespace Tools::win32 {

int MessageLoop::run() const {
    MSG msg;
    while (GetMessage(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return m_exitCode;
}

void MessageLoop::quit(int exitCode) {
    m_exitCode = exitCode;
    PostQuitMessage(exitCode);
}


}