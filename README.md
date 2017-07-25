> Debugging the fucking source code is more effective than reading the fucking source code.

# Usage

1. change to your code path

You need to change below variables to be yours.

```
android_code_path= YOUR_LOCAL_ANDROID_SOURCE_CODE_PATH
symbols_path=  YOUR_BUILT_SYMBOLS_PATH
```

2. prepare lldb env

```
./start_lldb.sh <YOUR_DEBUG_MODULE>
```

This will generate .lldbinit in local machine. Now maybe you can change some in .lldbinit

3. fire lldb command

run lldb command

```
lldb
```

and enjoy.
