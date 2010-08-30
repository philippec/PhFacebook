//
//  PhAuthenticationToken.h
//  PhFacebook
//
//  Created by Philippe on 10-08-29.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PhAuthenticationToken : NSObject
{
    NSString *_authenticationToken;
    NSDate *_expiry;
    NSString *_permissions;
}

@property (nonatomic, retain) NSString *authenticationToken;
@property (nonatomic, retain) NSDate *expiry;
@property (nonatomic, retain) NSString *permissions;

- (id) initWithToken: (NSString*) token secondsToExpiry: (NSTimeInterval) seconds permissions: (NSString*) perms;

@end
