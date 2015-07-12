//
//  PhAuthenticationToken.m
//  PhFacebook
//
//  Created by Philippe on 10-08-29.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import "PhAuthenticationToken.h"


@implementation PhAuthenticationToken

@synthesize authenticationToken = _authenticationToken;
@synthesize expiry = _expiry;
@synthesize permissions = _permissions;

- (id) initWithToken: (NSString*) token secondsToExpiry: (NSTimeInterval) seconds permissions: (NSString*) perms
{
    if ((self = [super init]))
    {
        _authenticationToken = [token copy];
        if (seconds != 0)
        {
            _expiry = [[NSDate dateWithTimeIntervalSinceNow: seconds] retain];
        }
        _permissions = [perms copy];
    }

    return self;
}

- (void) dealloc
{
    [_authenticationToken release];
    [_expiry release];
    [_permissions release];
    [super dealloc];
}

@end
