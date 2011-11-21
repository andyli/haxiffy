package haxiffy;

import haxe.FastList;
import haxe.xml.Fast;

#if neko
import neko.Lib;
import neko.Sys;
import neko.FileSystem;
import neko.io.File;
import neko.io.FileInput;
#else
import cpp.Lib;
import cpp.Sys;
import cpp.FileSystem;
import cpp.io.File;
import cpp.io.FileInput;
#end

import erazor.Template;
import haxiffy.cpp.Source;
import haxiffy.cpp.DoxygenSource;
import haxiffy.haxe.CommonType;
using Lambda;
using org.casalib.util.StringUtil;
using StringTools;

import haxiffy.cpp.Type;
typedef CppType = haxiffy.cpp.Type;
import haxiffy.haxe.Type;
typedef HxType = haxiffy.haxe.Type;

class Main{
	inline static public var DOXYGEN_XML_PATH = "../xml/";
	inline static public var TEMPLATE_PATH = "../tpl/";
	inline static public var OUTPUT_PATH = "../out/";
	
	inline static public var PROJECT = "hxOpenFrameworks";
	inline static public var PACKAGE = "of";
	
	public var cpp:Source;
	
	public function new():Void {
		var ignoreFiles = new Hash();
		ignoreFiles.set("of_gst_utils_8h", false);
		ignoreFiles.set("of_gst_video_grabber_8h", false);
		ignoreFiles.set("of_gst_video_player_8h", false);
		ignoreFiles.set("of_quick_time_grabber_8h", false);
		ignoreFiles.set("of_quick_time_player_8h", false);
		cpp = new DoxygenSource(DOXYGEN_XML_PATH, ignoreFiles);
	
		var vars = new Hash<Dynamic>();
		vars.set("project", PROJECT);
		vars.set("package", PACKAGE);
		
		vars.set("cpp2hxType", cpp2hxType);
		vars.set("cpp2hxTypeName", cpp2hxTypeName);
		vars.set("cpp2hxVal", cpp2hxVal);
		vars.set("hx2cppVal", hx2cppVal);
		vars.set("isSimpleCppType", isSimpleCppType);
		vars.set("toCppTypeEnum", toCppTypeEnum);

		vars.set("structs", cpp.structs);
		
		recursiveDelete(OUTPUT_PATH);
		FileSystem.createDirectory(OUTPUT_PATH);
		
		FileSystem.createDirectory(OUTPUT_PATH + "project");
		var ndll_api_tpl = new Template(File.getContent(TEMPLATE_PATH + "ndll_api.tpl.cpp"));
		var ndll_api_write = File.write(OUTPUT_PATH + "project/ndll_api.cpp", false);
		ndll_api_write.writeString(ndll_api_tpl.execute(vars));
		ndll_api_write.close();
		
		var build_xml_write = File.write(OUTPUT_PATH + "project/build.xml", false);
		build_xml_write.writeString(File.getContent(TEMPLATE_PATH + "build.xml"));
		build_xml_write.close();
		
		FileSystem.createDirectory(OUTPUT_PATH + PACKAGE);
		var struct_tpl = new Template(File.getContent(TEMPLATE_PATH + "struct.tpl.hx"));
		for (struct in cpp.structs) {
			var hxName = cpp2hxTypeName(TStruct(cast new RefImpl(struct.name, function() return struct)));
			vars.set("struct", struct);
			vars.set("hxName", hxName);
			
			var struct_write = File.write(OUTPUT_PATH + PACKAGE + "/" + hxName + ".hx", false);
			struct_write.writeString(struct_tpl.execute(vars));
			struct_write.close();
		}
	}
	
	static public function recursiveDelete(path:String):Void {
		if (FileSystem.isDirectory(path)) {
			FileSystem.readDirectory(path).map(function(p) return path + "/" + p).iter(recursiveDelete);
			FileSystem.deleteDirectory(path);
		} else {
			FileSystem.deleteFile(path);
		}
	}
	
	static public function cpp2hxName(cppTypeName:String):String {
		if (cppTypeName.startsWith("of")) cppTypeName = cppTypeName.substr(2);
		cppTypeName = cppTypeName.replace("::", "_");
		
		for (i in 0...cppTypeName.length) {
			var c = cppTypeName.charAt(i);
			if (~/[A-Z]/.match(c)) return cppTypeName;
			if (~/[a-z]/.match(c)) return cppTypeName.replaceAt(i, c.toUpperCase());
		}
		
		return throw "invalid type: " + cppTypeName;
	}
	
	public function isSimpleCppType(cppType:CppType):Bool {
		return switch (cppType) {
			case TEnum(t):
				true;
			
			case TStruct(t):
				false;
				
			case TInst(t, params):
				switch (t.toString()) {
					//http://www.cppreference.com/wiki/language/types
					case	"void",
							"bool",
							"short",
							"short int",
							"signed short",
							"signed short int",
							"unsigned short",
							"unsigned short int",
							"int",
							"signed",
							"signed int",
							"unsigned",
							"unsigned int",
							"long",
							"long int",
							"signed long",
							"signed long int",
							"unsigned long",
							"unsigned long int",
							"char",
							"signed char",
							"unsigned char",
							"long long",
							"long long int",
							"signed long long",
							"signed long long int",
							"unsigned long long",
							"unsigned long long int",
							"float",
							"double",
							"long double",
							"wchar_t",
							"char16_t",
							"char32_t":
							
							true;
							
					default:
					
							false;
				}
			case TType(t, params):
				isSimpleCppType(t.get().type);
			
			case TFun(t):
				false;
		}
	}
	
	public function toCppTypeEnum(cppType:haxiffy.cpp.Type.BaseType):CppType {
		return cpp.types.get(cppType.name);
	}
	
	public function cpp2hxTypeName(cppType:CppType):String {
		return switch(cpp2hxType(cppType)) {
			case HxType.TInst(t, params):
				var t = t.get();
				t.name;
			case HxType.TEnum(t, params):
				var t = t.get();
				t.name;
			default: throw "not implemented: " + cppType;
		}
	}
	
	public function cpp2hxType(cppType:CppType):HxType {
		return switch (cppType) {
			case CppType.TEnum(t):
				CommonType.types.get("Int");
			case CppType.TStruct(t):
				var name = cpp2hxName(t.toString());
				HxType.TInst(new RefImpl(name, function() return {
					pack: [],
					name: name,
					module: "",
					isPrivate: false,
					isExtern: false,
					params: [],
					meta: null,
					doc: null,
					exclude: null,
					isInterface: false,
					superClass: null,
					interfaces: [],
					fields: cast new RefImpl("", function() return []),
					statics: cast new RefImpl("", function() return []),
					constructor: null,
					init: null,
				}), []);
			case CppType.TInst(t, params):
				switch (t.toString()) {
					//http://www.cppreference.com/wiki/language/types
					case	"void":
		
							CommonType.types.get("Void");
							
					case	"bool":
							
							CommonType.types.get("Bool");
					
					case	"short",
							"short int",
							"signed short",
							"signed short int",
							"unsigned short",
							"unsigned short int",
							"int",
							"signed",
							"signed int",
							"unsigned",
							"unsigned int",
							"long",
							"long int",
							"signed long",
							"signed long int",
							"unsigned long",
							"unsigned long int",
							"char",
							"signed char",
							"unsigned char":
		
							CommonType.types.get("Int");
					
					case	"long long",
							"long long int",
							"signed long long",
							"signed long long int",
							"unsigned long long",
							"unsigned long long int",
							"float",
							"double",
							"long double":
		
							CommonType.types.get("Float");
					
					case	"wchar_t",
							"char16_t",
							"char32_t":
		
							CommonType.types.get("String");
					
					default:
							var name = cpp2hxName(t.toString());
							HxType.TInst(new RefImpl(name, function() return {
								pack: [],
								name: name,
								module: "",
								isPrivate: false,
								isExtern: false,
								params: [],
								meta: null,
								doc: null,
								exclude: null,
								isInterface: false,
								superClass: null,
								interfaces: [],
								fields: cast new RefImpl("", function() return []),
								statics: cast new RefImpl("", function() return []),
								constructor: null,
								init: null,
							}), []);
				}
			case CppType.TType(t, params):
				cpp2hxType(t.get().type);
				
			case CppType.TFun(t):
				throw "Unknow type: " + cppType;
		}
	}
	
	public function hx2cppVal(hxType:HxType, cppType:CppType, valExpr:String):String {
		return switch(hxType) {
			case HxType.TInst(t, params):
				switch(t.toString()) {
					case "Int":		"val_int("+valExpr+")";
					case "Float":	"val_float("+valExpr+")";
					case "String":	"val_string("+valExpr+")";
					default:		switch(cppType) {
										case CppType.TInst(t,params):
											"(" + t.toString() + "*) val_data(" + valExpr + ")";
										case CppType.TEnum(t):
											"(" + t.toString() + "*) val_data(" + valExpr + ")";
										case CppType.TStruct(t):
											"(" + t.toString() + "*) val_data(" + valExpr + ")";
										default:
											throw "unknown type: " + hxType;
									}
				}
			case HxType.TEnum(t, params):
				switch(t.toString()) {
					case "Void":	"NULL";
					case "Bool":	"val_bool("+valExpr+")";
					default:		throw "unknown enum type: " + t;
				}
			default: throw "unknown type: " + hxType;
		}
	}

	public function cpp2hxVal(cppType:CppType, valExpr:String):String {
		return switch (cppType) {
			case TEnum(t):
				"alloc_int("+valExpr+")";
			
			case TStruct(t):
				"alloc_"+cpp2hxTypeName(cppType)+"("+valExpr+")";
				
			case TInst(t, params):
				switch (t.toString()) {
					//http://www.cppreference.com/wiki/language/types
					case	"void":
		
							"alloc_null()";
							
					case	"bool":
							
							"alloc_bool("+valExpr+")";
					
					case	"short",
							"short int",
							"signed short",
							"signed short int",
							"unsigned short",
							"unsigned short int",
							"int",
							"signed",
							"signed int",
							"unsigned",
							"unsigned int",
							"long",
							"long int",
							"signed long",
							"signed long int",
							"unsigned long",
							"unsigned long int",
							"char",
							"signed char",
							"unsigned char":
		
							"alloc_int("+valExpr+")";
					
					case	"long long",
							"long long int",
							"signed long long",
							"signed long long int",
							"unsigned long long",
							"unsigned long long int",
							"float",
							"double",
							"long double":
		
							"alloc_float("+valExpr+")";
					
					case	"wchar_t",
							"char16_t",
							"char32_t":
		
							"alloc_wstring_len(& "+valExpr+", 1)";
		
					default: 
							"alloc_"+cpp2hxTypeName(cppType)+"("+valExpr+")";
				}
			case TType(t, params):
				cpp2hxVal(t.get().type, valExpr);
				
			case TFun(t):
				throw "Unknow type: " + cppType;
		}
	}
	
	static public function main():Void {
		new Main();
	}
}
