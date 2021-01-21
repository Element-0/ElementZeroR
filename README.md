# ElementZero Redesigned

STATE: WIP

# How to build and install

0. Prepare bedrock server from official website
1. Install msvc with clang_cl support
2. Install nim 1.4.2
3. Append
   ```
   [PackageList]
   name = "ElementZero"
   url = "https://element-0.win/packages.json"
   ```
   into %APPDATA%\nimble\nimble.ini
4. Run `nimble refresh`
5. Run `nimble install ezchakra` in vs environment (x64 Native Tools Command Prompt for VS 2019)
6. Copy dll/pdb from `nim path ezchakra` to bds folder
7. Run `ezpdbparser bedrock_server.pdb --database:bedrock_server.db` in bds folder (with x64 Native Tools Command Prompt for VS 2019)
8. Done