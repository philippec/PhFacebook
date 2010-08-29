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

- (id) initWithToken: (NSString*) token secondsToExpiry: (NSTimeInterval) seconds
{
    if ((self == [super init]))
    {
        self.authenticationToken = token;
        self.expiry = [NSDate dateWithTimeIntervalSinceNow: seconds];
    }

    return self;
}

@end
