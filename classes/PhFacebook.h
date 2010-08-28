//
//  PhFacebook.h
//  PhFacebook
//
//  Created by Philippe on 10-08-25.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PhWebViewController;

@interface PhFacebook : NSObject
{
@private
    NSString *_appID;
    id _delegate;
    PhWebViewController *_webViewController;
}

- (id) initWithApplicationID: (const NSString*) appID delegate: (id) delegate;

// permissions: an array of required permissions
// see http://developers.facebook.com/docs/authentication/permissions
- (void) getAccessTokenForPermissions: (NSArray*) permissions;

@end

@protocol PhFacebookDelegate

- (void) validToken: (PhFacebook*) fbObject;

@end