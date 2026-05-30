cmake_minimum_required(VERSION 3.20)
project(OpenProxifierCLI C)
set(CMAKE_C_STANDARD 11)

set(SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/..")
set(WINDIVERT_DIR "${SRC_DIR}/windivert")

add_library(ProxyEngineCore STATIC
    ${SRC_DIR}/core/ProxyEngine.c
    ${SRC_DIR}/core/PacketProcessor.c
    ${SRC_DIR}/core/LocalProxy.c
    ${SRC_DIR}/core/ConnectionTracker.c
    ${SRC_DIR}/core/RuleEngine.c
    ${SRC_DIR}/core/Socks5.c
    ${SRC_DIR}/core/ProcessTracker.c
    ${SRC_DIR}/core/UdpRelay.c
)
target_include_directories(ProxyEngineCore PUBLIC ${SRC_DIR}/core ${WINDIVERT_DIR}/include)
target_link_libraries(ProxyEngineCore PUBLIC ${WINDIVERT_DIR}/x64/WinDivert.lib ws2_32 iphlpapi)
target_compile_definitions(ProxyEngineCore PRIVATE _WIN32_WINNT=0x0601 WIN32_LEAN_AND_MEAN)

add_executable(OpenProxifierCLI ${SRC_DIR}/cli/main.c)
target_link_libraries(OpenProxifierCLI PRIVATE ProxyEngineCore)
target_compile_definitions(OpenProxifierCLI PRIVATE _WIN32_WINNT=0x0601 WIN32_LEAN_AND_MEAN)

add_custom_command(TARGET OpenProxifierCLI POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${WINDIVERT_DIR}/x64/WinDivert.dll" "$<TARGET_FILE_DIR:OpenProxifierCLI>"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${WINDIVERT_DIR}/x64/WinDivert64.sys" "$<TARGET_FILE_DIR:OpenProxifierCLI>"
)
