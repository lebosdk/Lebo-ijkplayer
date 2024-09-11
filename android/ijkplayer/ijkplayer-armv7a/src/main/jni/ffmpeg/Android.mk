LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := lbffmpeg
LOCAL_SRC_FILES := $(MY_APP_FFMPEG_OUTPUT_PATH)/liblbffmpeg.so
LOCAL_CFLAGS := -Wall -O2 -U_FORTIFY_SOURCE –fstack-protector-all
include $(PREBUILT_SHARED_LIBRARY)
