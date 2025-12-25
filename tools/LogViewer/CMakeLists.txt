cmake_minimum_required(VERSION 3.20)
project(LogViewer LANGUAGES CXX)

add_executable(LogViewer
        ../win32/MessageLoop.cpp
        ../win32/Window.cpp
        MainWindow.cpp
        PipeServer.cpp
        LogViewerApp.cpp
)

target_compile_features(LogViewer PRIVATE cxx_std_23)

target_compile_definitions(LogViewer PRIVATE
        UNICODE
        _UNICODE
)

target_link_libraries(LogViewer PRIVATE
        user32
        gdi32
)

set_target_properties(LogViewer PROPERTIES
        WIN32_EXECUTABLE TRUE
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../bin"
        RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_CURRENT_SOURCE_DIR}/../bin"
        RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_CURRENT_SOURCE_DIR}/../bin"
)