package haxiffy.haxe;

typedef Ref<T> = {
	public function get() : T;
	public function toString() : String;
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
	TMono( t : Ref<Null<Type>> );
	TEnum( t : Ref<EnumType>, params : Array<Type> );
	TInst( t : Ref<ClassType>, params : Array<Type> );
	TType( t : Ref<DefType>, params : Array<Type> );
	TFun( args : Array<{ name : String, opt : Bool, t : Type }>, ret : Type );
	TAnonymous( a : Ref<AnonType> );
	TDynamic( t : Null<Type> );
	TLazy( f : Void -> Type );
}

typedef AnonType = {
	var fields : Array<ClassField>;
	//var status : AnonStatus;
}

typedef BaseType = {
	var pack : Array<String>;
	var name : String;
	var module : String;
	//var pos : Expr.Position;
	var isPrivate : Bool;
	var isExtern : Bool;
	var params : Array<{ name : String, t : Type }>;
	var meta : MetaAccess;
	var doc : Null<String>;
	function exclude() : Void;
}

typedef ClassField = {
	var name : String;
	var type : Type;
	var isPublic : Bool;
	var params : Array<{ name : String, t : Type }>;
	var meta : MetaAccess;
	var kind : FieldKind;
	var expr : Null<TypedExpr>;
	//var pos : Expr.Position;
	var doc : Null<String>;
}

typedef ClassType = {> BaseType,
	//var kind : ClassKind;
	var isInterface : Bool;
	var superClass : Null<{ t : Ref<ClassType>, params : Array<Type> }>;
	var interfaces : Array<{ t : Ref<ClassType>, params : Array<Type> }>;
	var fields : Ref<Array<ClassField>>;
	var statics : Ref<Array<ClassField>>;
	//var dynamic : Null<Type>;
	//var arrayAccess : Null<Type>;
	var constructor : Null<Ref<ClassField>>;
	var init : Null<TypedExpr>;
}

typedef EnumField = {
	var name : String;
	var type : Type;
	//var pos : Expr.Position;
	var meta : MetaAccess;
	var index : Int;
	var doc : Null<String>;
}

typedef EnumType = {> BaseType,
	var constructs : Hash<EnumField>;
	var names : Array<String>;
}

typedef DefType = {> BaseType,
	var type : Type;
}

typedef MetaAccess = {
	//function get() : Expr.Metadata;
	//function add( name : String, params : Array<Expr>, pos : Expr.Position ) : Void;
	//function remove( name : String ) : Void;
	//function has( name : String ) : Bool;
}

enum FieldKind {
	FVar( read : VarAccess, write : VarAccess );
	FMethod( k : MethodKind );
}

enum VarAccess {
	AccNormal;
	AccNo;
	AccNever;
	AccResolve;
	AccCall( m : String );
	AccInline;
	AccRequire( r : String );
}

enum MethodKind {
	MethNormal;
	MethInline;
	MethDynamic;
	MethMacro;
}

extern enum TypedExpr {}