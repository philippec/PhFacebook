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
        self.authenticationToken = token;
        if (seconds != 0)
            self.expiry = [NSDate dateWithTimeIntervalSinceNow: seconds];
        self.permissions = perms;
    }

    return self;
}

@end
