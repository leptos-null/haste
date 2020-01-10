include $(THEOS)/makefiles/common.mk

TOOL_NAME = haste

haste_FILES = src/main.m
haste_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tool.mk
