#ifndef MESSAGELOOP_H
#define MESSAGELOOP_H

#include <windows.h>

namespace Tools::win32 {

class MessageLoop {
public:
    int run() const;
    void quit(int exitCode);

private:
    int m_exitCode{0};
};

}



#endif //MESSAGELOOP_H
