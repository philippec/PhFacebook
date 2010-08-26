//
//  PhFacebook.m
//  PhFacebook
//
//  Created by Philippe on 10-08-25.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import "PhFacebook.h"


@implementation PhFacebook

- (id) initWithApplicationID: (const NSString*) appID
{
    if ((self == [super init]))
    {
        _appID = [appID copy];
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
