#include "PipeServer.h"
#include "MainWindow.h"

int WINAPI WinMain(
    HINSTANCE hInstance,
    HINSTANCE,
    LPSTR,
    int
) {
    Tools::win32::MessageLoop loop;
    Tools::Log::MainWindow window(hInstance, loop);

    return loop.run();
}