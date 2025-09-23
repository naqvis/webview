UNAME := $(shell uname)

CXXFLAGS ?= -std=c++11

ifeq ($(UNAME), Darwin)
CXXFLAGS += -DWEBVIEW_COCOA=1 -DWEBVIEW_BUILD_SHARED=1 -DOBJC_OLD_DISPATCH_PROTOTYPES=1
endif

ifeq ($(UNAME), Linux)
CXXFLAGS += -DWEBVIEW_GTK=1 -DWEBVIEW_BUILD_SHARED=1 `if pkg-config --exists webkit2gtk-4.1; then \
	pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.1; \
else \
	pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.0; \
fi`
endif

cpp_file := ext/webview.cc
obj_file := $(cpp_file:.cc=.o)

.PHONY: all
all: $(obj_file)

ifeq ($(UNAME), Linux)
	ar rcs ext/libwebview.a ext/webview.o
endif

%.o: %.cc
	$(CXX) -c -o $@ $(CXXFLAGS) $<

.PHONY: clean
clean:
	rm -f $(obj_file)
