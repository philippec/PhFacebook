//
//  PhFacebook.m
//  PhFacebook
//
//  Created by Philippe on 10-08-25.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import "PhFacebook.h"


@implementation PhFacebook

- (id) initWithApplicationID: (const NSString*) appID delegate: (id) delegate
{
    if ((self == [super init]))
    {
        _appID = [appID copy];
        _delegate = delegate; // Don't retain delegate to avoid retain cycles
    }
    NSLog(@"Initialized with AppID '%@'", _appID);

    return self;
}

- (void) dealloc
{
    [_appID release];
    [super dealloc];
}

@end
