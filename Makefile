UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
CFLAGS = -DWEBVIEW_COCOA=1 -DOBJC_OLD_DISPATCH_PROTOTYPES=1
endif

ifeq ($(UNAME), Linux)
CFLAGS = -DWEBVIEW_GTK=1
endif

CFLAGS += -std=c++11
cpp_file := ext/webview.cc
obj_file := $(cpp_file:.cc=.o)

.PHONY: all
all: $(obj_file)

%.o: %.cc
	$(CXX) -c -o $@ $(CFLAGS) $<

.PHONY: clean
clean:
			rm -f $(obj_file)
