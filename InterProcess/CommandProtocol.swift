//
// CommandProtocol.swift
//	Chromium module
//
// Pure-example message exchange between Chromium's Browser (which can do things like
//	pop up a file picker or access the file system) and Renderer Process (which is
//	receiving the UI events like button clicks).
//
// Created by Tadd Jensen on 9/27/19; follows same BSD-3-Clause-like terms as project
//	on which it is based: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//

import Foundation


public class CommandProtocol : Codable {

	static var instance = CommandProtocol()

	public enum Operation : String, Codable {
		case SAVE		= "Save"
		case OPEN		= "Open"
		case NAV_NEXT	= "NavigateForward"
		case LOG_OUT	= "LogOut"
	}

	public enum FileType : String, Codable {
		case REGULAR	= "Regular"
		case SPECIAL	= "Special"
		case UNKNOWN	= "Unknown"
	}


	public struct RequestData : Codable {
		var Operation: Operation?
		var FileType:  FileType?
		var FileName:  String?
		var ExampleId: Int?
		var IsSpecial: Bool?
	}
	public var Request = RequestData()

	public var FilePath: String? = nil


	init() {
	}

	init(request: RequestData) {
		initialize(request: request)
	}

	func initialize(request: RequestData) {

		Request.Operation = request.Operation
		Request.FileType  = request.FileType
		Request.FileName  = request.FileName
		Request.ExampleId = request.ExampleId
		Request.IsSpecial = request.IsSpecial
	}

	// save
	init(operation: Operation?, fileType: FileType?, fileName: String?,
								anyId: Int?, isSpecial: Bool? = nil) {
		Request.Operation = operation
		Request.FileType  = fileType
		setParentId(to: anyId, forFileType: fileType)
		Request.FileName  = fileName
		Request.IsSpecial = isSpecial
	}

	// open
	init(operation: Operation?, fileType: FileType?, fileName: String?, anyId: Int?) {

		Request.Operation = operation
		Request.FileType  = fileType
		setParentId(to: anyId, forFileType: fileType)
		Request.FileName  = fileName
		Request.IsSpecial = false
	}

	// navigate (or some sundry operation)
	init(operation: Operation?, destinationId: Int?) {

		Request.Operation = operation
		Request.ExampleId = destinationId
	}

	// UTILITY METHODS

	func setParentId(to: Int?, forFileType: FileType?) {

		if let toId = to,
		   let fileType = forFileType {

			switch fileType {
			case .REGULAR:
				Request.ExampleId = toId
			case .SPECIAL:
				Request.ExampleId = toId + 100
			default: break
			}
		}
	}

	func parentIdFor(givenFileType: FileType?) -> Int? {

		if let fileType = givenFileType {
			switch fileType {
			case .REGULAR:
				return Request.ExampleId
			case .SPECIAL:
				return Request.ExampleId != nil ? Request.ExampleId! - 100 : Request.ExampleId
			default: break
			}
		}
		return nil
	}
}
