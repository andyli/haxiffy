package haxiffy.cpp;

import haxiffy.cpp.Type;
import haxe.xml.Fast;
#if neko
import neko.Lib;
import neko.io.File;
#else
import cpp.Lib;
import cpp.io.File;
#end

using Lambda;
using StringTools;
using org.casalib.util.StringUtil;

class DoxygenSource extends Source {
	var xmlFolderPath:String;
	var fileFasts:Hash<Fast>; //file xml
	var classFasts:Hash<Fast>; //class file xml
	var structFasts:Hash<Fast>; //struct file xml
	var functionFasts:Hash<Fast>; //memberdef node
	var enumFasts:Hash<Fast>; //memberdef node
	
	public function new(_xmlFolderPath:String, ignoreFiles:Hash<Bool>):Void {
		xmlFolderPath = _xmlFolderPath;
		
		//make sure path ends with '/'
		if (xmlFolderPath.charAt(xmlFolderPath.length - 1) != '/') xmlFolderPath += '/';

		var indexXml = Xml.parse(File.getContent(xmlFolderPath + "index.xml"));
		var indexFast = new Fast(indexXml);
		
		//hold all files that needs to be ignored recursively
		var recursiveIgnore = [];
		for (file in ignoreFiles.keys())
			if (ignoreFiles.get(file))
				recursiveIgnore.push(file);

		//put all inner files of recursiveIgnore into ignoreFiles
		while (recursiveIgnore.length > 0) {
			var ignoreRefid = recursiveIgnore.shift();
			ignoreFiles.set(ignoreRefid, true);
			var fast = new Fast(Xml.parse(File.getContent(xmlFolderPath + ignoreRefid + ".xml")));
			for (includedby in fast.node.doxygen.node.compounddef.nodes.includedby){
				recursiveIgnore.push(includedby.att.refid);
			}
		}
		
		var fileNodes = 
			indexFast.node.doxygenindex.nodes.compound
			.filter(function(c) return c.att.kind == "file" && !ignoreFiles.exists(c.att.refid)); //ignore the files in ignoreFiles
		var members = fileNodes.fold(function(c,a) return c.nodes.member.array().concat(a), []);
		fileFasts = new Hash();
		for (file in fileNodes) {
			var refid = file.att.refid;
			var xml = Xml.parse(File.getContent(xmlFolderPath + refid + ".xml"));
			fileFasts.set(refid, new Fast(xml));
		}
		
		classFasts = new Hash();
		functionFasts = new Hash();
		structFasts = new Hash();
		enumFasts = new Hash();
		
		typedefs = new Hash();
		for (fileFast in fileFasts) {
			var compounddef = fileFast.node.doxygen.node.compounddef;
			
			var sections = compounddef.nodes.sectiondef;
			for (section in sections) {
				if (section.att.kind == "typedef") {
					for (member in section.nodes.memberdef) {
						if (member.att.prot != "public") continue;
						
						var typedefName = member.node.name.innerData;
						var doc = member.node.detaileddescription.innerHTML.trim();
						if (member.node.type.hasNode.ref) {
						
						} else {
							var targetTypeName = member.node.type.innerData;
							typedefs.set(typedefName, {
								type: TInst(new RefImpl(targetTypeName, function() return classes.get(targetTypeName)), []),
								name: typedefName,
								doc: doc == "" ? null : doc
							});
						}
					}
				}
				
				if (section.att.kind == "func") {
					for (member in section.nodes.memberdef) {
						if (member.att.prot != "public") continue;
						
						functionFasts.set(member.node.name.innerData, member);
					}
				}
			}
			
			var innerclasses = compounddef.nodes.innerclass;
			for (innerclass in innerclasses) {
				if (innerclass.att.prot != "public") continue;
				
				if (innerclass.att.refid.startsWith("class"))
					classFasts.set(innerclass.innerData, new Fast(Xml.parse(File.getContent(xmlFolderPath + innerclass.att.refid + ".xml"))));
				else if (innerclass.att.refid.startsWith("struct"))
					structFasts.set(innerclass.innerData, new Fast(Xml.parse(File.getContent(xmlFolderPath + innerclass.att.refid + ".xml"))));
				else
					throw "unknow innerclass: " + innerclass.att.refid;
			}
		}
		
		structs = new Hash();
		classes = new Hash();
		functions = new Hash();
		enums = new Hash();
		types = new Hash();
		for (structName in structFasts.keys()) {
			var structFast = structFasts.get(structName);
			var doc = structFast.node.doxygen.node.compounddef.node.detaileddescription.innerHTML.trim();
			var struct:StructType = {
				name: structName,
				fields: [],
				doc: doc == "" ? null : doc
			}
			for (memberdef in structFast.node.doxygen.node.compounddef.nodes.sectiondef.fold(function(s, a) return s.nodes.memberdef.concat(a),[])) {
				switch (memberdef.att.kind) {
					case "variable":
						var type =
							if (memberdef.node.type.hasNode.ref) {
								var fieldTypeName = memberdef.node.type.node.ref.innerData;
								if (memberdef.node.type.node.ref.att.refid.startsWith("class")) {
									var fieldType = new RefImpl(fieldTypeName, function() return classes.get(fieldTypeName));
									TInst(fieldType, []);
								} else if (memberdef.node.type.node.ref.att.refid.startsWith("struct")) {
									var fieldType = new RefImpl(fieldTypeName, function() return structs.get(fieldTypeName));
									TStruct(fieldType);
								}
							} else {
								var fieldTypeName = memberdef.node.type.innerData;
								switch (fieldTypeName) {
									case "GLint", "GLenum":
										var fieldType = new RefImpl("int", function() return classes.get("int"));
										TInst(fieldType, []);
									default:
										var fieldType = new RefImpl(fieldTypeName, function() return classes.get(fieldTypeName));
										TInst(fieldType, []);
								}
								
							}
						
						var doc = memberdef.node.detaileddescription.innerHTML.trim();
						var field = {
							name: memberdef.node.name.innerData,
							type: type,
							params: [],
							doc: doc == "" ? null : doc
						}
						struct.fields.push(field);
					case "enum":
						enumFasts.set(structName + "::" + memberdef.node.name.innerData, memberdef);
					case "function":
						//ignore constructors at the moment
					default: 
						throw "memberdef.att.kind:\n" + memberdef.x;
				}
			}
			structs.set(structName, struct);
			types.set(structName, TStruct(new RefImpl(structName, function() return struct)));
		}
	}
}