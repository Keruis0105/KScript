#ifndef PIPESERVER_H
#define PIPESERVER_H

#include <windows.h>
#include <thread>
#include <atomic>

namespace Tools::Log {
class PipeServer {
public:
    explicit PipeServer(HWND targetWnd);
    ~PipeServer();

private:
    void run() const;

public:
    void stop();

    HWND m_targetWnd{};
    std::thread m_thread;
    std::atomic<bool> m_running{ true };
};

}
#endif //PIPESERVER_H
