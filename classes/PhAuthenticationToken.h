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

@property (nonatomic, strong) NSString *authenticationToken;
@property (nonatomic, strong) NSDate *expiry;
@property (nonatomic, strong) NSString *permissions;

- (id) initWithToken: (NSString*) token secondsToExpiry: (NSTimeInterval) seconds permissions: (NSString*) perms;

@end
