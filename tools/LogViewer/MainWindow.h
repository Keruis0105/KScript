#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include "PipeServer.h"

#include "../win32/Window.h"
#include "../win32/MessageLoop.h"

namespace Tools::Log {

class MainWindow : public win32::Window {
public:
    explicit MainWindow(HINSTANCE hinstance, win32::MessageLoop&);
    ~MainWindow() override;

    [[nodiscard]] HWND hwnd() const noexcept { return m_hwnd; }
    void appendLog(const wchar_t* text) const;
    
protected:
    LRESULT handleMessage(UINT, WPARAM, LPARAM) override;

private:
    HINSTANCE m_hinstance{};
    HWND m_edit{};

    win32::MessageLoop& m_loop;
    PipeServer* m_pipeServer;
};

}

#endif