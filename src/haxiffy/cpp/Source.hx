package haxiffy.cpp;

import haxiffy.cpp.Type;

class Source {
	public var structs(default, null):Hash<StructType>;
	public var enums(default, null):Hash<EnumType>;
	public var typedefs(default, null):Hash<DefType>;
	public var classes(default, null):Hash<ClassType>;
	public var functions(default, null):Hash<FunType>;
	
	public var types(default, null):Hash<Type>;
}