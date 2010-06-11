{for file in files}#include "{file.path}"
{end}
{?
	absToCppFuncName = function (type) {
		//TODO
		return type;
	}
}
//////////////////////////////
#define IMPLEMENT_API
#include <hx/CFFI.h>

template<typename OBJ>
bool haxiffy_abstractToCpp(value a, OBJ *&outObj, &vkind kind)
{
	OBJ* obj = (OBJ*)val_to_kind(a,kind);
	outObj = dynamic_cast<OBJ*>(obj);
	return outObj;
}

{for _class in classes}
/* {:class.encodedFullName} */
DEFINE_KIND(haxiffy_{:_class.encodedFullName})

static void release_haxiffy_{:_class.encodedFullName}(value a) {
	{:_class.fullName}* obj = ({:_class.fullName}*)val_to_kind(a,haxiffy_{:_class.encodedFullName});
	if (obj) delete obj;
}

{if(_class.constructor != null)}
{?
	args = _class.constructor.arguments;
	argNum = args.length;
}
value {:_class.encodedFullName}_new({for i in 0...argNum}value _haxiffy_{:i}{if(i+1<argNum)}, {end}{end}) {
{for i in 0...argNum}
	{:args[i].type} _haxiffy_{:args[i].name} = {:absToCppFuncName(args[i].type)}(_haxiffy_{:i});
{end}
	value _haxiffyRet = alloc_abstract(haxiffy_{:_class.encodedFullName},new {:_class.fullName}({for i in 0...argNum}value _haxiffy_{:args[i].name}{if(i+1<argNum)}, {end}{end}));
	val_gc(_haxiffyRet, release_haxiffy_{:_class.encodedFullName});
	return _haxiffyRet;
}
DEFINE_PRIM({:_class.encodedFullName}_new,{:argNum})
{end}

{end}
