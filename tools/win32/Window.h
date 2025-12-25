#ifndef WINDOW_H
#define WINDOW_H

#include <windows.h>

namespace Tools::win32 {

class Window {
public:
    virtual ~Window() = default;

    HWND get_handle() const noexcept { return m_hwnd; }

    bool create(
        HINSTANCE instance,
        const wchar_t* className,
        const wchar_t* title,
        DWORD style = WS_OVERLAPPEDWINDOW,
        DWORD exStyle = 0,
        int width = 800,
        int height = 600
    );

protected:
    virtual LRESULT handleMessage(UINT, WPARAM, LPARAM);

private:
    static LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);

protected:
    HWND m_hwnd{};
};

}

#endif //WINDOW_H
