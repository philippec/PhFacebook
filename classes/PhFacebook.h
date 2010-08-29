//
//  PhFacebook.h
//  PhFacebook
//
//  Created by Philippe on 10-08-25.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PhWebViewController;
@class PhAuthenticationToken;

@interface PhFacebook : NSObject
{
@private
    NSString *_appID;
    id _delegate;
    PhWebViewController *_webViewController;
    PhAuthenticationToken *_authToken;
}

- (id) initWithApplicationID: (NSString*) appID delegate: (id) delegate;

// permissions: an array of required permissions
// see http://developers.facebook.com/docs/authentication/permissions
- (void) getAccessTokenForPermissions: (NSArray*) permissions;

// request: the short version of the Facebook Graph API, e.g. "me/feed"
// see http://developers.facebook.com/docs/api
- (void) sendRequest: (NSString*) request;


- (void) setAccessToken: (NSString*) accessToken expires: (NSString*) tokenExpires error: (NSString*) errorReason;

@end

@protocol PhFacebookDelegate

- (void) tokenResult: (NSDictionary*) result;
- (void) requestResult: (NSDictionary*) result;

@end