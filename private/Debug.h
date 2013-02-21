//
//  Debug.h
//  PhFacebook
//
//  Debug helpers
//
//  Created by Philippe on 10-08-31.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#ifdef DEBUG
	#define DebugLog(format, ...) NSLog(@"%@",[NSString stringWithFormat:format, ## __VA_ARGS__])
#else
    #define DebugLog(format, ...)
#endif                     