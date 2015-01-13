LOCAL_PATH := $(call my-dir)/../../haxe

include $(CLEAR_VARS)

LOCAL_MODULE    := HaxeApplication
LOCAL_SRC_FILES := src/Main.cpp

LOCAL_C_INCLUDES := include

include $(BUILD_SHARED_LIBRARY)