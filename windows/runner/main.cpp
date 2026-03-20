#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <shellapi.h>

#include "flutter_window.h"
#include "utils.h"

#include <commctrl.h>

#include "resource.h"

#pragma comment(lib, "comctl32.lib")

#define WM_TRAYICON (WM_USER + 1)
#define ID_TRAY_EXIT 1001
#define ID_TRAY_SHOW 1002

NOTIFYICONDATA nid = {};
HWND g_hwnd = nullptr;

void AddTrayIcon(HWND hwnd) {
  nid.cbSize = sizeof(NOTIFYICONDATA);
  nid.hWnd = hwnd;
  nid.uID = 1;
  nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  nid.uCallbackMessage = WM_TRAYICON;
  nid.hIcon = (HICON)LoadImage(
    GetModuleHandle(nullptr),
    MAKEINTRESOURCE(IDI_APP_ICON),
    IMAGE_ICON,
    GetSystemMetrics(SM_CXSMICON),
    GetSystemMetrics(SM_CYSMICON),
    LR_DEFAULTCOLOR
  );
  if (!nid.hIcon) {
    // Fallback to system icon if app icon not found
    nid.hIcon = LoadIcon(nullptr, IDI_APPLICATION);
  }
  wcscpy_s(nid.szTip, L"BusyLight Buddy");
  Shell_NotifyIcon(NIM_ADD, &nid);
}

void RemoveTrayIcon() {
  Shell_NotifyIcon(NIM_DELETE, &nid);
}

void ShowTrayMenu(HWND hwnd) {
  HMENU menu = CreatePopupMenu();
  AppendMenu(menu, MF_STRING, ID_TRAY_SHOW, L"Show");
  AppendMenu(menu, MF_SEPARATOR, 0, nullptr);
  AppendMenu(menu, MF_STRING, ID_TRAY_EXIT, L"Quit");
  POINT pt;
  GetCursorPos(&pt);
  SetForegroundWindow(hwnd);
  TrackPopupMenu(menu, TPM_BOTTOMALIGN | TPM_LEFTALIGN, pt.x, pt.y, 0, hwnd, nullptr);
  DestroyMenu(menu);
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line, _In_ int show_command) {
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");
  std::vector<std::string> command_line_arguments = GetCommandLineArguments();
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(420, 820);
  if (!window.Create(L"BusyLight Buddy", origin, size)) {
    return EXIT_FAILURE;
  }

  g_hwnd = window.GetHandle();
  AddTrayIcon(g_hwnd);

  // Subclass the window to intercept WM_SYSCOMMAND and WM_TRAYICON
  SetWindowSubclass(g_hwnd, [](HWND hwnd, UINT msg, WPARAM wp, LPARAM lp,
                                UINT_PTR, DWORD_PTR) -> LRESULT {
    switch (msg) {
      case WM_SYSCOMMAND:
        if ((wp & 0xFFF0) == SC_MINIMIZE) {
          ShowWindow(hwnd, SW_HIDE);  // hide instead of minimize
          return 0;
        }
        break;
      case WM_TRAYICON:
        if (lp == WM_LBUTTONDBLCLK || lp == WM_LBUTTONUP) {
          ShowWindow(hwnd, SW_SHOW);
          SetForegroundWindow(hwnd);
        } else if (lp == WM_RBUTTONUP) {
          ShowTrayMenu(hwnd);
        }
        break;
      case WM_COMMAND:
        if (LOWORD(wp) == ID_TRAY_EXIT) {
          RemoveTrayIcon();
          PostQuitMessage(0);
        } else if (LOWORD(wp) == ID_TRAY_SHOW) {
          ShowWindow(hwnd, SW_SHOW);
          SetForegroundWindow(hwnd);
        }
        break;
      case WM_DESTROY:
        RemoveTrayIcon();
        break;
    }
    return DefSubclassProc(hwnd, msg, wp, lp);
  }, 1, 0);

  ::MSG msg = {};
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}