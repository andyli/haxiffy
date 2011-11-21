#ifndef _WIN32_WINNT
#   define _WIN32_WINNT 0x400
#endif

#define IMPLEMENT_API
#include <hx/CFFI.h>

#include "ofMain.h"
#include "ofAppGlutWindow.h"

DEFINE_KIND(_@(project)_ndll_kind);

@for (struct in structs) { @{ var hxName = cpp2hxTypeName(toCppTypeEnum(struct)); }
	void delete_@(hxName)(value a) {
		@struct.name* strct = (@struct.name*) val_data(a);
		delete strct;
	}
	
	value alloc_@(hxName)(@(struct.name)& v) {
		@(struct.name)* s = new @(struct.name)();
		*s = v;
		value handle = alloc_abstract(_@(project)_ndll_kind, s);
		val_gc(handle, delete_@(hxName));
		return handle;
	}
	
	value alloc_@(hxName)(@(struct.name)* v, bool weakRef = true) {
		value handle = alloc_abstract(_@(project)_ndll_kind, v);
		if (!weakRef) val_gc(handle, delete_@(hxName));
		return handle;
	}
}

@for (struct in structs) { @{ var hxName = cpp2hxTypeName(toCppTypeEnum(struct)); }
	value _@(hxName)_new() {	
		value handle = alloc_abstract(_@(project)_ndll_kind, new @(struct.name)());
		val_gc(handle, delete_@(hxName));
		return handle;
	}
	DEFINE_PRIM(_@(hxName)_new, 0);
	
	@for (field in struct.fields) {
	value _@(hxName)_get_@(field.name)(value a) {
		@struct.name* strct = (@struct.name*) val_data(a);
		return @cpp2hxVal(field.type, "strct->"+field.name);
	}
	DEFINE_PRIM(_@(hxName)_get_@(field.name), 1);

	value _@(hxName)_set_@(field.name)(value a, value b) {
		@struct.name* strct = (@struct.name*) val_data(a);
		strct->@(field.name) = @hx2cppVal(cpp2hxType(field.type), field.type, "b");
		return b;
	}
	DEFINE_PRIM(_@(hxName)_set_@(field.name), 2);
	}
}
