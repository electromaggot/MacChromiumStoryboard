//
// Quickly implement project-wide functions locally (to Tester apps):
//	- "blog" basic logger
//

import Foundation	// for NSString


public enum Level {
	case	CRIT, FATL,				CRITICAL, FATAL
	case	ERR, INTL,	HIGH,		ERROR, INTERNAL
	case	FAIL, EXTL,				FAILURE, EXTERNAL
	case	STATUS,					PROGRESS, IMPORTANT
	case	WARN, MID,	 MED,		WARNING
	case	NORM, DFLT,	 AVG,		NORMAL, DEFAULT, AVERAGE, DIAGNOSTIC
	case	DBUG, INFO,				DEBUG, INFORMATIONAL
	case	DUMP, TMI,	 LOW,		VERBOSE, TROUBLESHOOTING
}
public enum Bucket: Int {
	
	case DEFAULT			= 0
	case DEBUG				= 1
	case BROWSER			= 2
	case RENDERER			= 3
	case INTERPROCESS		= 4
	case WEBSERVICE			= 5

	case NONE				= -1
}


func blog(_ text: String, _ bucket: Bucket = .DEFAULT) {
	
	print(text)
}

func blog(_ text: NSString, _ bucket: Bucket = .DEFAULT) {
	
	blog(text as String)
}

func blog(_ level: Level, _ text: String, _ bucket: Bucket = .DEFAULT) {
	
	blog(text)
}

func blog(_ level: Level, _ text: NSString, _ bucket: Bucket = .DEFAULT) {
	
	blog(text as String)
}
