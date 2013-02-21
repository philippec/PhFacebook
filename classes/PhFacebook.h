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

/** Completion handler blocks receive (as the delegate does) a custom NSDictionary result object. */
typedef void (^PhCompletionBlock)(NSDictionary *result);

@interface PhFacebook : NSObject
{
@private
    NSString *_appID;
    id _delegate;
    PhWebViewController *_webViewController;
    PhAuthenticationToken *_authToken;
    NSString *_permissions;
}

/** Initialize the instance with a Facebook Application Identifier. This initialization should only be used, if you make use of completion blocks for both the access token retrieval and the actual API requests. */
- (id) initWithApplicationID: (NSString*) appID;

/** Initialize the instance with both a Facebook Application Identifier and a delegate object. The delegate will be notified once the access token retrieval result or a request result is available. */
- (id) initWithApplicationID: (NSString*) appID delegate: (id) delegate;

// permissions: an array of required permissions
//              see http://developers.facebook.com/docs/authentication/permissions
// canCache: save and retrieve token locally if not expired
// If you do not specify a block, the delegate will be notified instead.
- (void) getAccessTokenForPermissions: (NSArray*) permissions cached: (BOOL) canCache withCompletionBlock:(PhCompletionBlock) block;
- (void) getAccessTokenForPermissions: (NSArray*) permissions cached: (BOOL) canCache;

// request: the short version of the Facebook Graph API, e.g. "me/feed"
// see http://developers.facebook.com/docs/api
// If no block is specified, the delegate will be notified instead.
- (void) sendRequest: (NSString*) request;
- (void) sendRequest: (NSString*) request withCompletionBlock:(PhCompletionBlock) block;
- (void) sendRequest: (NSString*) request params: (NSDictionary*) params usePostRequest: (BOOL) postRequest;
- (void) sendRequest: (NSString*) request params: (NSDictionary*) params usePostRequest: (BOOL) postRequest withCompletionBlock:(PhCompletionBlock) block;

// query: the query to send to FQL API, e.g. "SELECT uid, sex, name from user WHERE uid = me()"
// see http://developers.facebook.com/docs/reference/fql/
- (void) sendFQLRequest: (NSString*) query;
- (void) sendFQLRequest: (NSString*) query withCompletionBlock:(PhCompletionBlock) block;

- (void) invalidateCachedToken;

- (void) setAccessToken: (NSString*) accessToken expires: (NSTimeInterval) tokenExpires permissions: (NSString*) perms error: (NSString*) errorReason;
- (void) setAccessToken: (NSString*) accessToken expires: (NSTimeInterval) tokenExpires permissions: (NSString*) perms error: (NSString*) errorReason withCompletionBlock: (PhCompletionBlock) block;
- (NSString*) accessToken;

- (void) webViewWillShowUI;
- (void) didDismissUI;

@end

/** The delegate protocol should be implemented if you do not make use of completion blocks. */
@protocol PhFacebookDelegate

@required
- (void) tokenResult: (NSDictionary*) result;
- (void) requestResult: (NSDictionary*) result;

@optional
// needsAuthentication is called before showing the authentication WebView.
// If it returns YES, the default login window will not be shown and
// your application is responsible for the authentication UI.
- (BOOL) needsAuthentication: (NSString*) authenticationURL forPermissions: (NSString*) permissions; 
- (void) willShowUINotification: (PhFacebook*) sender;
- (void) didDismissUI: (PhFacebook*) sender;

@end