package haxiffy.cpp;

typedef Ref<T> = {
	public function get():T;
	public function toString():String;
}

class RefImpl<T> {
	var name:String;
	
	public function new(name:String, get:Void->T):Void {
		this.name = name;
		this.get = get;
	}
	
	dynamic public function get():T { return throw "not set yet"; }
	
	public function toString():String {
		return name;
	}
}

enum Type {
	TEnum( t: Ref<EnumType> );
	TStruct( t: Ref<StructType> );
	TInst( t: Ref<ClassType>, params: Array<Type> );
	TType( t: Ref<DefType>, params: Array<Type> );
	TFun( t: Ref<FunType> );
}

typedef Field = {
	var name:String;
	var type:Type;
	var params: Array<{ name: String, t: Type }>;
	var doc: Null<String>;
}

typedef BaseType = {
	var name: String;
	var doc: Null<String>;
}

typedef EnumField = {
	var name: String;
	var index: Int;
	var doc: Null<String>;
}

typedef EnumType = { > BaseType,
	var constructs : Hash<EnumField>;
}

typedef DefType = { > BaseType,
	var type : Type;
}

typedef StructType = { > BaseType,
	var fields:Array<Field>;
}

typedef ClassType = { > BaseType,
	var fields: Array<Field>;
	var statics: Array<Field>;
	var constructor : Null<Field>;
}

typedef FunType = { > BaseType,
	args: Array<{ name: String, opt: Bool, t: Type }>,
	ret: Type
}