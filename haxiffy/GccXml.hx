package haxiffy;

import haxe.xml.Fast;

using ListTools;
using HashTools;
using org.casalib.util.ArrayUtil;

class GccXml {
	static public var acceptAsRootTypes:Array<String> = ["string"];
	public var fastRoot(default,null):Fast;
	public var tagNameHash(default,null):Hash<List<Xml>>;
	public var idHash(default,null):Hash<Xml>;

	public var fundamentalTypeHash(default,null):Hash<Xml>;

	public function new(x:Xml):Void {
		fastRoot = new Fast(x).node.GCC_XML;

		var elements = fastRoot.x.filter(function(x:Xml) return x.nodeType == Xml.Element);
		tagNameHash = elements.groupByHash(function(x:Xml) return x.nodeName);

		idHash = new Hash<Xml>();
		for (i in elements){
			if (i.exists("id"))
				idHash.set(i.get("id"),i);
		}

		fundamentalTypeHash = new Hash<Xml>();
		for (i in tagNameHash.get("FundamentalType")) {
			fundamentalTypeHash.set(i.get("name"),i);
		}
	}

	public function getRootType(x:Xml):Xml {
		var type:Xml = idHash.get(x.get("type"));
		while (type.exists("type") && acceptAsRootTypes.contains(type.get("name")) == 0) {
			type = idHash.get(type.get("type"));
			//trace(x.get("name")+": "+type.nodeName +" "+ type.get("name"));
		}
		if (type.nodeName == "Enumeration") 
			return fundamentalTypeHash.get("int");
		else
			return type;
	}
	
	public function isCopyConstructor(x:Xml):Bool {
		if (x.nodeName != "Constructor")
			return false;

		var args = x.filter(function (x:Xml) return x.nodeType == Xml.Element && x.nodeName == "Argument");
		if (args.length != 1)
			return false;
		
		var argType = idHash.get(args.first().get("type"));
		if (argType.nodeName != "ReferenceType")
			return false;

		var typeStr = argType.get("type");
		if (typeStr.charAt(typeStr.length-1) != "c")
			return false;
		
		argType = idHash.get(typeStr.substr(0,typeStr.length-1));
		return (argType.nodeName == "Class" && argType.get("name") == x.get("name"));
	}

	public function isFundamentalType(x:Xml):Bool {
		return x.nodeName == "FundamentalType" || acceptAsRootTypes.contains(x.get("name")) > 0;
	}

	public function getConversionCode(type:Xml,argName:String, valName:String):String {
		var typeName = type.get("name");
		if (isFundamentalType(type))
			return switch (typeName) {
				case "int","unsigned int","long","float","double":
					"\t"+typeName+" "+argName+" = val_number("+valName+");\n";
				case "string":
					"\t"+typeName+" "+argName+" = val_string("+valName+");\n";
				default:
					"";
			}
		else
			return "";
	}
}
