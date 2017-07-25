#! /bin/bash

cur_dir=`pwd`
android_code_path="/home/bobwang/apt_sh01/work.d/debug.st8.rel.24.uda.r1"
symbols_path="$android_code_path/out/debug/target/product/shieldtablet/symbols/system/lib"

lldb_server="$cur_dir/lldb.server/armeabi/lldb-server"

debug_module=$1

#filter correct debug module
case $1 in
    "surface"|"surfaceflinger")
    ;;
    *)
        echo "wrong debug mode, Now supporting surface|surfaceflinger"
        exit 1
    ;;
esac

if [ "x`adb get-state`" != "xdevice" ]; then
    echo "No devices" 
    exit 1
fi

echo "rooting device ..."
adb root
adb wait-for-device
echo "device is rooted!"
echo "remounting device ..."
adb remount
adb wait-for-device
echo "device is remounted!"

adb shell input keyevent 82 #unlock
adb shell input keyevent 3 #enter home

# prepare lldb server
adb shell ls /data/local/tmp/lldb-server
if [ $? -ne 0 ]; then
    echo "preparing lldb server"
    adb shell getprop ro.product.cpu.abi | grep arm64
    if [ $? -eq 0 ]; then
        lldb_server="$cur_dir/lldb.server/arm64-v8a/lldb-server"
    fi
    adb push $lldb_server /data/local/tmp/
    adb shell chmod 777 /data/local/tmp/lldb-server
fi

echo "starting lldb server ..."
adb shell pkill lldb-server
pid_of_old_adb=`ps -ef | grep lldb-server | grep -v grep | awk '{print $2}'`

if [ "X$pid_of_old_adb" != "X" ]; then
    kill $pid_of_old_adb
fi

adb shell /data/local/tmp/lldb-server platform --server --listen unix-abstract:///data/local/tmp/debug.sock &
lldb_server_pid=$!


echo "platform select remote-android" > .lldbinit
echo "platform connect unix-abstract-connect:///data/local/tmp/debug.sock" >> .lldbinit

if [ "$debug_module" == "surface" ]; then
    system_pid=`adb shell ps  | grep system_server | awk '{print $2}'`
    if [ "X$system_server" != "X" ]; then
        echo "no system server process"
        kill -9 $lldb_server_pid
        exit 1
    fi
    echo "process attach -p $system_pid" >> .lldbinit
    #echo "breakpoint set --file android_view_SurfaceSession.cpp --name nativeCreate" >> .lldbinit
    #echo "breakpoint set --file SurfaceComposerClient.cpp --name onFirstRef" >> .lldbinit
    #echo "breakpoint set --file SurfaceComposerClient.cpp --name SurfaceComposerClient" >> .lldbinit
    #echo "breakpoint set --file android_view_SurfaceControl.cpp --name nativeCreate" >> .lldbinit
    #echo "breakpoint set --file SurfaceComposerClient.cpp --name createSurface" >> .lldbinit
    #echo "breakpoint set --file Surface.cpp --name allocateBuffers" >> .lldbinit
    echo "breakpoint set --file SurfaceControl.cpp --name setPosition" >> .lldbinit
    #echo "breakpoint set --file SurfaceControl.cpp --name getSurface" >> .lldbinit
    echo "add-dsym $symbols_path/libandroid_runtime.so" >> .lldbinit
    echo "add-dsym $symbols_path/libgui.so" >> .lldbinit
    echo "add-dsym $symbols_path/libui.so" >> .lldbinit
    echo "add-dsym $symbols_path/libbinder.so" >> .lldbinit
    echo "add-dsym $symbols_path/libcutils.so" >> .lldbinit

elif [ "$debug_module" == "surfaceflinger" ]; then
    surfaceflinger_pid=`adb shell ps | grep surfaceflinger | awk '{print $2}'` 
    if [ "X$surfaceflinger" != "X" ]; then
        echo "no surfaceflinger process"
        kill -9 $lldb_server_pid
        exit 1
    fi
    echo "process attach -p $surfaceflinger_pid" >> .lldbinit
    #echo "breakpoint set --name createConnection" >> .lldbinit
    #echo "breakpoint set --file SurfaceControl.cpp --name getSurface" >> .lldbinit
    echo "breakpoint set --file BufferQueueProducer.cpp --line 1258" >> .lldbinit
    echo "breakpoint set --file BufferQueueCore.cpp --line 103" >> .lldbinit
    echo "add-dsym $symbols_path/libsurfaceflinger.so" >> .lldbinit
    echo "add-dsym $symbols_path/libgui.so" >> .lldbinit
    echo "add-dsym $symbols_path/libui.so" >> .lldbinit
fi

echo "settings set target.source-map /  $android_code_path" >> .lldbinit
echo "settings append target.source-map /proc/self/cwd  $android_code_path" >> .lldbinit

pkill -9 lldb

