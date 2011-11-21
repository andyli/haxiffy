package haxiffy.haxe;

import haxiffy.haxe.Type;

class CommonType {
	static public var VOID(default, null):EnumType;
	static public var BOOL(default, null):EnumType;
	static public var FLOAT(default, null):ClassType;
	static public var INT(default, null):ClassType;
	static public var STRING(default, null):ClassType;
	
	static public var enums(default, null):Hash<EnumType>;
	static public var typedefs(default, null):Hash<DefType>;
	static public var classes(default, null):Hash<ClassType>;
	static public var functions(default, null):Hash<Type>;
	
	static public var types(default, null):Hash<Type>;
	
	static function __init__():Void {
		enums = new Hash<EnumType>();
		typedefs = new Hash<DefType>();
		classes = new Hash<ClassType>();
		functions = new Hash<Type>();
	
		types = new Hash<Type>();
		
		CommonType.VOID = {
			pack: [],
			name: "Void",
			module: "",
			isPrivate: false,
			isExtern: true,
			params: [],
			meta: null,
			doc: null,
			exclude: null,
			constructs: new Hash(),
			names: []
		};
		enums.set("Void", CommonType.VOID);
		types.set("Void", TEnum(new RefImpl("Void", function() return CommonType.VOID), []));
		
		var hash = new Hash();
		var type = TEnum(new RefImpl("Bool", function() return enums.get("Bool")), []);
		hash.set("true", {
			name: "true",
			type: type,
			meta: null,
			index: 0,
			doc: null
		});
		hash.set("false", {
			name: "false",
			type: type,
			meta: null,
			index: 1,
			doc: null
		});
		CommonType.BOOL = {
			pack: [],
			name: "Bool",
			module: "",
			isPrivate: false,
			isExtern: true,
			params: [],
			meta: null,
			doc: null,
			exclude: null,
			constructs: hash,
			names: ["true", "false"]
		};
		enums.set("Bool", CommonType.BOOL);
		types.set("Bool", TEnum(new RefImpl("Bool", function() return CommonType.BOOL), []));
		
		CommonType.FLOAT = {
			pack: [],
			name: "Float",
			module: "",
			isPrivate: false,
			isExtern: true,
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
		};
		classes.set("Float", CommonType.FLOAT);
		types.set("Float", TInst(new RefImpl("Float", function() return CommonType.FLOAT), []));
		
		CommonType.INT = {
			pack: [],
			name: "Int",
			module: "",
			isPrivate: false,
			isExtern: true,
			params: [],
			meta: null,
			doc: null,
			exclude: null,
			isInterface: false,
			superClass: { t:cast new RefImpl("Float", function() return CommonType.FLOAT), params:[] },
			interfaces: [],
			fields: cast new RefImpl("", function() return []),
			statics: cast new RefImpl("", function() return []),
			constructor: null,
			init: null,
		};
		classes.set("Int", CommonType.INT);
		types.set("Int", TInst(new RefImpl("Int", function() return CommonType.INT), []));
		
		CommonType.STRING = {
			pack: [],
			name: "String",
			module: "",
			isPrivate: false,
			isExtern: true,
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
		};
		classes.set("String", CommonType.STRING);
		types.set("String", TInst(new RefImpl("String", function() return CommonType.STRING), []));
	}
}