# Install develop environment

## Windows

    1. Install `Visual Studio 2019 Community`
    2. Exec `SETX VS142 C:\Program Files (x86)\Microsoft Visual Studio\2019\Community`
    3. Exec `git clone https://github.com/Microsoft/vcpkg`
    4. Exec `bootstrap-vcpkg.bat` in vcpkg
    5. Exec `SETX VCPKG_DEFAULT_TRIPLET x64-windows`
    6. Exec `vcpkg install boost`
    7. Exec `SETX PATH %PATH%;C:\Program Files\vcpkg;C:\Program Files\vcpkg\installed\x64-windows\bin`
    8. Install `Visual Studio Code`
    9. Exec `SETX PATH %PATH%;C:\Users\Tony\AppData\Local\Programs\Microsoft VS Code\bin`
    10. Exec `code --install-extension ms-vscode.cpptools`
    11. Exec `sbin/vscode.bat` in this project