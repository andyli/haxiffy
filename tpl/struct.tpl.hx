package @package;

import cpp.Lib;

@if (struct.doc != null) {/*
 * @struct.doc
 */}
class @hxName {
	var handle:Dynamic;

	public function new():Void {
		handle = _@(hxName)_new();
	}
	static var _@(hxName)_new = Lib.load("@(project).ndll", "_@(hxName)_new", 0);
	
	@for (field in struct.fields) {
	@if (field.doc != null) {/*
	 * @field.doc
	 */}
	public var @(field.name)(_get_@(field.name), _set_@(field.name)):@cpp2hxTypeName(field.type);

	function _get_@(field.name)():@cpp2hxTypeName(field.type) {
		@if (isSimpleCppType(field.type)) {
		return _@(hxName)_get_@(field.name)(handle);
		} else {
		var r:Dynamic = Type.createEmptyInstance(@cpp2hxTypeName(field.type));
		r.handle = _@(hxName)_get_@(field.name)(handle);
		return r;
		}
	}
	static var _@(hxName)_get_@(field.name) = Lib.load("@(project).ndll", "_@(hxName)_get_@(field.name)", 1);
	
	function _set_@(field.name)(v:@cpp2hxTypeName(field.type)):@cpp2hxTypeName(field.type) {
		@if (isSimpleCppType(field.type)) {
		return _@(hxName)_set_@(field.name)(handle, v);
		} else {
		_@(hxName)_set_@(field.name)(handle, untyped v.handle);
		return v;
		}
	}
	static var _@(hxName)_set_@(field.name) = Lib.load("@(project).ndll", "_@(hxName)_set_@(field.name)", 2);
	}
}
