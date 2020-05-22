LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := tama-mroot
LOCAL_CFLAGS += -Iinclude -DBINDER_DEVICE="\"/dev/hwbinder\"" -O3 -DNDEBUG
LOCAL_SRC_FILES := src/exploit.c src/endpoint.c src/pending_node.c src/binder.c src/log.c src/helpers.c  src/binder_lookup.c src/realloc.c src/node.c

include $(BUILD_EXECUTABLE)


