package haxiffy;

import haxe.FastList;
import haxe.xml.Fast;

import neko.Lib;
import neko.Sys;
import neko.FileSystem;
import neko.io.File;
import neko.io.FileInput;

using ListTools;
using HashTools;

class Main{
	static public function main():Void {
		var consolePath = Sys.getCwd();
		var configPath = consolePath+"haxiffy.xml";
		
		if (!FileSystem.exists(configPath)) {
			Lib.println("Cannot find config file: "+ configPath);
			Sys.exit(0);
		}
		
		var config = Xml.parse(File.getContent(configPath));
		var fast = new Fast(config).node.haxiffy;
		
		
		var projectName = fast.att.name;
		var gccxmlPath = fast.node.gccxml.att.path;
		var csourcePath = fast.node.csource.att.path;
		var outputPath = fast.node.output.att.path;
		var outputPackage = fast.node.output.node.haxePackage.att.name;
		
		if (FileSystem.kind(gccxmlPath) != FileKind.kfile) {
			Lib.println("Cannot find gccxml: "+ gccxmlPath);
			Sys.exit(0);
		}

		if (!FileSystem.exists(csourcePath)) {
			Lib.println("Cannot find c/c++ source directory: "+ csourcePath);
			Sys.exit(0);
		}
		
		if (!FileSystem.exists(outputPath)) {
			Lib.println("Create output directory: " + outputPath);
			FileSystem.createDirectory(outputPath);
		}

		if (!FileSystem.exists(outputPath+"/xml")) {
			Lib.println("Create output directory: " + outputPath+"/xml");
			FileSystem.createDirectory(outputPath+"/xml");
		}

		var outputPackagePath = outputPath+"/"+outputPackage;
		if (!FileSystem.exists(outputPackagePath)) {
			Lib.println("Create output directory: " + outputPackagePath);
			FileSystem.createDirectory(outputPackagePath);
		}

		var classes = fast.node.csource.nodes.resolve("class");
		var getFileOfClass = function(f:Fast):String return f.has.file ? f.att.file : f.att.name + ".h";

		var allCppPath = outputPath+"/xml/all.cpp";
		if (!FileSystem.exists(allCppPath)) {
			Lib.println("Create cpp file: " + allCppPath);
			var tempCpp = File.write(allCppPath,false);
			var cfiles = fast.node.csource.nodes.resolve("class").map(getFileOfClass).unique();
			for (file in cfiles) {
				tempCpp.writeString('#include "'+csourcePath+"/"+file+'" \n');
			}
			tempCpp.close();
		}
		
		
		var outputXmlPath = outputPath+"/xml/all.xml";
		if (!FileSystem.exists(outputXmlPath)) {
			Lib.println("gccxml: " + outputXmlPath);
			Sys.command(gccxmlPath,[allCppPath,"-fxml="+outputXmlPath]);
		}

		var gccxml = new GccXml(Xml.parse(File.getContent(outputXmlPath)));

		var interfaceCppPath = outputPath+"/interface.cpp";
		if (!FileSystem.exists(interfaceCppPath)) {
			Lib.println("Create cpp file: " + interfaceCppPath);
		} else {
			Lib.println("Overwrite cpp file: " + interfaceCppPath);
		}
		var interfaceCpp = File.write(interfaceCppPath,false);
		
		interfaceCpp.writeString(File.getContent(allCppPath)+"\n//////////////////////////////\n");
		interfaceCpp.writeString("#define IMPLEMENT_API\n#include <hx/CFFI.h>\n\n");
		interfaceCpp.writeString(
"template<typename OBJ>
bool haxiffy_abstractToCpp(value a, OBJ *&outObj, &vkind kind)
{
	OBJ* obj = (OBJ*)val_to_kind(a,kind);
	outObj = dynamic_cast<OBJ*>(obj);
	return outObj;
}\n\n");
		for (_class in classes) {
			var classXml = gccxml.tagNameHash.get("Class").findFirst(function(x:Xml) return x.get("name") == _class.att.name);
			var demangledName = classXml.get("demangled");
			var name = ~/::/.replace(demangledName,"_");
			interfaceCpp.writeString("\n/* "+name+" */\n");
			var kindName = "haxiffy_"+name;
			interfaceCpp.writeString("DEFINE_KIND("+kindName+");\n");
			interfaceCpp.writeString("\n");

			var memberIds = classXml.get("members").split(" ").filter(function(s:String) return s.length>0);
			var members = memberIds.map(function (id:String) return gccxml.idHash.get(id));
			var memberTypeHash = members.groupByHash(function (x:Xml) return x.nodeName);

			interfaceCpp.writeString(
"static void release_"+kindName+"(value a) {
	"+demangledName+"* obj = ("+demangledName+"*)val_to_kind(a,"+kindName+");
	if (obj) delete obj;
}\n\n");

			var constructors = memberTypeHash.get("Constructor").filter(function (x:Xml) return !gccxml.isCopyConstructor(x));
			if (constructors.length != 1) {
				Lib.println("Warning: "+name+" has "+constructors.length+" constructor(s).");
			}

			var args = new Fast(constructors.first()).nodes.Argument.array();
			var argTypes = args.map(function(f:Fast) return gccxml.getRootType(f.x));
			var argTypeNames = argTypes.map(function(x:Xml)return x.get("name"));
			var inputStr = argTypes.mapi(function(i:Int,type:Xml) return "value _haxiffy"+i).join(",");
			var conversionStr = argTypes.mapi(function(i:Int,type:Xml) return gccxml.getConversionCode(type,args[i].att.name,"_haxiffy"+i)).join("");
			var innerInputStr = args.map(function(arg:Fast) return arg.att.name).join(",");
			
			interfaceCpp.writeString(
"value "+name+"_new("+inputStr+") {
"+conversionStr+
"	value _haxiffyRet = alloc_abstract("+kindName+",new "+demangledName+"("+innerInputStr+"));
	val_gc(_haxiffyRet, release_"+kindName+");
	return _haxiffyRet;
}
DEFINE_PRIM("+name+"_new,"+args.length+");\n\n");

			/*
				Generate haxe class
			*/
			var haxeFile = File.write(outputPackagePath+"/"+_class.att.name+".hx",false);
			haxeFile.writeString("package "+outputPackage+";\n\n");
			haxeFile.writeString("#if neko import neko.Lib; #elseif cpp import cpp.Lib; #end\n\n");
			haxeFile.writeString("class "+_class.att.name+" {\n");

			//constructor
			haxeFile.writeString("\tpublic function new():Void{\n");
			haxeFile.writeString("\t\thaxiffyHandle = "+name+"_new();\n");
			haxeFile.writeString("\t}\n");

			haxeFile.writeString("\tprivate var haxiffyHandle:Dynamic;\n\n");
			
			//constructor
			haxeFile.writeString("\tstatic private var "+name+"_new = Lib.load('"+projectName+"','"+name+"_new',"+args.length+");\n");

			
			haxeFile.writeString("}");
			haxeFile.close();
		}
		interfaceCpp.close();

		/*
			Generate build.xml
		*/
		var buildXmlPath = outputPath+"/build.xml";
		var buildXml:Xml;
		if (!FileSystem.exists(buildXmlPath)) {
			Lib.println("Create xml file: " + buildXmlPath);
			buildXml = Xml.createDocument();
		} else {
			Lib.println("Overwrite xml file: " + buildXmlPath);
			buildXml = Xml.parse(File.getContent(buildXmlPath));
		}
		var fastBuildXml = new Fast(buildXml);
		var buildXmlFile = File.write(buildXmlPath,false);

		var cur = fastBuildXml;
		if (!cur.hasNode.xml) cur.x.addChild(Xml.createElement("xml"));
		cur = cur.node.xml;
		if (!cur.hasNode.include) cur.x.addChild(Xml.createElement("include"));
		cur.node.include.x.set("name", "${HXCPP}/build-tool/BuildCommon.xml");
		if (!cur.hasNode.files) cur.x.addChild(Xml.createElement("files"));
		cur = cur.node.files;
		if (!cur.hasNode.file) cur.x.addChild(Xml.createElement("file"));
		cur.node.file.x.set("name", "xml/all.cpp");
		buildXmlFile.writeString(fastBuildXml.x.toString());
		buildXmlFile.close();
	}
}
