//
// CEF V8 Utility.swift
//	BrowserProcess/ChromiumTester, RenderProcess/ChromiumHelper
//
// Utility methods to process V8 Objects;
//	V8 being the Javascript engine in Chromium.
// SHARED BETWEEN CEF's BROWSER AND RENDER PROCESSES.
//
// Created 10/8/19 by Tadd Jensen; follows same BSD-3-Clause-like terms as project
//	on which it depends: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//

import Foundation
import CEFswift

// CEFV8 UTILITY METHODS

public func CreateCEFV8Object(from: Any, name: String = "inputObject") -> CEFV8Value? {

	var error = "unknown"
	do {
		if var result = CEFV8Value.createObject() {
			try recurseConstructCEFV8Object(from: from, named: name, to: &result)
			return result
		} else {
			error = "CEFV8Value.createObject() FAIL"
		}
	}
	catch (let caught) {
		error = caught.localizedDescription
	}
	//blog(.ERR, "createCEFV8Object: \(error)")
	print("BLOG .ERR:  createCEFV8Object: \(error)")
	return nil
}
private func recurseConstructCEFV8Object(from: Any, named: String, to: inout CEFV8Value, depth: Int = 0) throws {

	let spaces: NSString = "                                                            "
	let indent = spaces.substring(to: depth)

	let reflector = Mirror(reflecting: from)
	if let metatype = reflector.displayStyle {
		switch metatype {
		case .`struct`, .`class`:				// branch nodes
			print("\(indent)STRUCT/CLASS \(named)")
			if var newObject = CEFV8Value.createObject() {
				to.setValue(newObject, for: named, attribute: CEFV8PropertyAttribute.none)
				for case let (memberName?, anyValue) in reflector.children {
					try recurseConstructCEFV8Object(from: anyValue, named: memberName, to: &newObject, depth: depth + 2)
				}
			}
			return
		case .collection:
			print("\(indent)ARRAY \(named)")
			if let array = from as? [Any],
				var newArray = CEFV8Value.createArray(length: array.count) {
				to.setValue(newArray, for: named, attribute: CEFV8PropertyAttribute.none)
				for (index, element) in array.enumerated() {
					try recurseConstructCEFV8Object(from: element, named: "\(index)", to: &newArray, depth: depth + 2)
				}
			}
			return
		default: break
		}
	}
	let description = reflector.description
	let type = reflector.subjectType
	switch type {								// leaf nodes
	case is String.Type:
		if let string = CEFV8Value.createString(from as? String) {
			to.setValue(string, for: named, attribute: CEFV8PropertyAttribute.none)
		}
	case is Bool.Type:
		if let boolean = from as? Bool,
			let cefbool = CEFV8Value.createBool(boolean) {
			to.setValue(cefbool, for: named, attribute: CEFV8PropertyAttribute.none)
		}
	case is Int.Type:
		if let int = from as? Int,
			let cefint = CEFV8Value.createInt(int) {
			to.setValue(cefint, for: named, attribute: CEFV8PropertyAttribute.none)
		}
	case is UInt.Type:
		if let uint = from as? UInt,
			let cefuint = CEFV8Value.createUInt(uint) {
			to.setValue(cefuint, for: named, attribute: CEFV8PropertyAttribute.none)
		}
	case is Double.Type:
		if let double = from as? Double,
			let cefdouble = CEFV8Value.createDouble(double) {
			to.setValue(cefdouble, for: named, attribute: CEFV8PropertyAttribute.none)
		}
		//case is Array<String>.Type:	// (not done this way.  see more efficient .collection handling above.)
	//	break
	default:
		print("\(indent)UNSUPPORTED TYPE! --> \(type) : \(description)")
		return
	}
	print("\(indent)\(named) : \(from)\t\t(\(type))")
}

// V8 debug assist

public func DumpCEFV8(object: CEFListValue?, name: String) {

	if let list = object {
		let last = list.size
		for index in 0 ..< last {
			print("\(String(describing: list.value(at: index)))")
		}
	}
}

public func DumpCEFV8(object: CEFV8Value, name: String) {

	recurseDumpCEFV8(key: name, value: object, indent: "  ")
}
private func recurseDumpCEFV8(key: String, value: CEFV8Value, indent: String) {

	var valueString = "INVALID!"

	if value.isObject {
		print("\(indent)\(key): (OBJECT)")
		for childKey in value.allKeys {
			if let keyValue = value.value(for: childKey),
				keyValue.isValid {

				recurseDumpCEFV8(key: childKey, value: keyValue, indent: indent + "  ")
			}
		}
		return
	}
		/*else if value.isArray {	// this actually enumerates as an object, so already done!
		//for key in keyValue.
		}*/
	else if value.isString {
		valueString = "\"\(value.stringValue)\""
	}
	else if value.isInt {
		valueString = "\(value.intValue)\t\tInt"
	}
	else if value.isUInt {
		valueString = "\(value.uintValue)\t\tUInt"
	}
	else if value.isDouble {
		valueString = "\(value.doubleValue)\t\tDouble"
	}
	else if value.isBool {
		valueString = "\(value.boolValue)\t\tBool"
	}
	else if value.isDate {
		valueString = "\(value.dateValue)\t\tDate"
	}
	else if value.isNull {
		valueString = "NULL!"
	}
	print("\(indent)\(key): \(valueString)")
}
