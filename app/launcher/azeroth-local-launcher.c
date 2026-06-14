#include <windows.h>
#include <wchar.h>

static void show_error(const wchar_t *message)
{
    MessageBoxW(NULL, message, L"Azeroth Local", MB_OK | MB_ICONERROR);
}

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE previous, PWSTR command_line, int show)
{
    wchar_t launcher_path[MAX_PATH];
    wchar_t project_dir[MAX_PATH];
    wchar_t client_dir[MAX_PATH];
    wchar_t client_exe[MAX_PATH];
    wchar_t process_command[MAX_PATH + 3];
    STARTUPINFOW startup = {0};
    PROCESS_INFORMATION process = {0};
    wchar_t *last_separator;

    (void)instance;
    (void)previous;
    (void)command_line;
    (void)show;

    if (!GetModuleFileNameW(NULL, launcher_path, MAX_PATH))
    {
        show_error(L"Nao foi possivel localizar o executavel do lancador.");
        return 1;
    }

    wcscpy(project_dir, launcher_path);
    last_separator = wcsrchr(project_dir, L'\\');
    if (!last_separator)
    {
        show_error(L"Nao foi possivel localizar a pasta do projeto.");
        return 1;
    }
    *last_separator = L'\0';

    if (swprintf(client_dir, MAX_PATH, L"%ls\\client\\WoW-3.3.5a", project_dir) < 0 ||
        swprintf(client_exe, MAX_PATH, L"%ls\\Wow.exe", client_dir) < 0)
    {
        show_error(L"O caminho do cliente e muito longo.");
        return 1;
    }

    if (GetFileAttributesW(client_exe) == INVALID_FILE_ATTRIBUTES)
    {
        show_error(L"Wow.exe nao encontrado em client\\WoW-3.3.5a.");
        return 1;
    }

    if (swprintf(process_command, MAX_PATH + 3, L"\"%ls\"", client_exe) < 0)
    {
        show_error(L"Nao foi possivel preparar o comando do cliente.");
        return 1;
    }

    startup.cb = sizeof(startup);
    if (!CreateProcessW(
            client_exe,
            process_command,
            NULL,
            NULL,
            FALSE,
            0,
            NULL,
            client_dir,
            &startup,
            &process))
    {
        show_error(L"Nao foi possivel iniciar o World of Warcraft.");
        return 1;
    }

    CloseHandle(process.hThread);
    WaitForSingleObject(process.hProcess, INFINITE);
    CloseHandle(process.hProcess);
    return 0;
}
