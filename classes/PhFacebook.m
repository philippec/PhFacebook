//
//  PhFacebook.m
//  PhFacebook
//
//  Created by Philippe on 10-08-25.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import "PhFacebook.h"
#import "PhWebViewController.h"
#import "PhAuthenticationToken.h"
#import "PhFacebook_URLs.h"
#import "Debug.h"

#define kFBStoreAccessToken @"FBAStoreccessToken"
#define kFBStoreTokenExpiry @"FBStoreTokenExpiry"
#define kFBStoreAccessPermissions @"FBStoreAccessPermissions"

@implementation PhFacebook

#pragma mark Initialization

- (id) initWithApplicationID:(NSString *)appID {
	return [self initWithApplicationID:appID delegate:nil];
}
- (id) initWithApplicationID: (NSString*) appID delegate: (id) delegate
{
    if ((self = [super init]))
    {
        if (appID)
            _appID = [NSString stringWithString: appID];
        _delegate = delegate; // Don't retain delegate to avoid retain cycles
        _webViewController = nil;
        _authToken = nil;
        _permissions = nil;
        DebugLog(@"Initialized with AppID '%@'", _appID);
    }

    return self;
}


- (void) notifyDelegateForToken: (PhAuthenticationToken*) token withError: (NSString*) errorReason withCompletionBlock: (PhCompletionBlock) block
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if (token)
    {
        // Save it to user defaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject: token.authenticationToken forKey: kFBStoreAccessToken];
        if (token.expiry)
            [defaults setObject: token.expiry forKey: kFBStoreTokenExpiry];
        else
            [defaults removeObjectForKey: kFBStoreTokenExpiry];
        [defaults setObject: token.permissions forKey: kFBStoreAccessPermissions];

        [result setObject: [NSNumber numberWithBool: YES] forKey: @"valid"];
    }
    else
    {
        [result setObject: [NSNumber numberWithBool: NO] forKey: @"valid"];
        [result setObject: errorReason forKey: @"error"];
    }

	if (block) {
		block(result);
	}
}

#pragma mark Access

- (void) clearToken
{
    _authToken = nil;
}

-(void) invalidateCachedToken
{
    [self clearToken];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kFBStoreAccessToken];
    [defaults removeObjectForKey: kFBStoreTokenExpiry];
    [defaults removeObjectForKey: kFBStoreAccessPermissions];

    // Allow logout by clearing the left-over cookies (issue #35)
    NSURL *facebookUrl = [NSURL URLWithString:kFBURL];
    NSURL *facebookSecureUrl = [NSURL URLWithString:kFBSecureURL];

    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [[cookieStorage cookiesForURL: facebookUrl] arrayByAddingObjectsFromArray:[cookieStorage cookiesForURL: facebookSecureUrl]];

    for (NSHTTPCookie *cookie in cookies)
        [cookieStorage deleteCookie: cookie];
}

- (void) setAccessToken: (NSString*) accessToken expires: (NSTimeInterval) tokenExpires permissions: (NSString*) perms
{
    [self clearToken];

    if (accessToken)
        _authToken = [[PhAuthenticationToken alloc] initWithToken: accessToken secondsToExpiry: tokenExpires permissions: perms];
}

- (void) getAccessTokenForPermissions:(NSArray *)permissions cached:(BOOL)canCache {
	NSCAssert(_delegate!=nil, @"Trying to get access token with no delegate set.");
	PhCompletionBlock block = ^(NSDictionary *result){
		if ([_delegate respondsToSelector: @selector(tokenResult:)])
			[_delegate tokenResult: result];
	};
	[self getAccessTokenForPermissions:permissions cached:canCache withCompletionBlock:block];
}

- (void) getAccessTokenForPermissions: (NSArray*) permissions cached: (BOOL) canCache withCompletionBlock:(PhCompletionBlock)block
{
    BOOL validToken = NO;
    NSString *scope = [permissions componentsJoinedByString: @","];

    if (canCache && _authToken == nil)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *accessToken = [defaults stringForKey: kFBStoreAccessToken];
        NSDate *date = [defaults objectForKey: kFBStoreTokenExpiry];
        NSString *perms = [defaults stringForKey: kFBStoreAccessPermissions];
        if (accessToken && perms)
        {
            // Do not notify delegate yet...
            [self setAccessToken: accessToken expires: [date timeIntervalSinceNow] permissions: perms];
        }
    }

    if ([_authToken.permissions isCaseInsensitiveLike: scope])
    {
        // We already have a token for these permissions; check if it has expired or not
        if (_authToken.expiry == nil || [[_authToken.expiry laterDate: [NSDate date]] isEqual: _authToken.expiry])
            validToken = YES;
    }

    if (validToken)
    {
        [self notifyDelegateForToken: _authToken withError: nil withCompletionBlock:block];
    }
    else
    {
        [self clearToken];

        // Use _webViewController to request a new token
        NSString *authURL;
        if (scope)
            authURL = [NSString stringWithFormat: kFBAuthorizeWithScopeURL, _appID, kFBLoginSuccessURL, scope];
        else
            authURL = [NSString stringWithFormat: kFBAuthorizeURL, _appID, kFBLoginSuccessURL];
      
        if ([_delegate respondsToSelector: @selector(needsAuthentication:forPermissions:)]) 
        {
            if ([_delegate needsAuthentication: authURL forPermissions: scope]) 
            {
                // If needsAuthentication returns YES, let the delegate handle the authentication UI
                return;
            }
        }
      
        // Retrieve token from web page
        if (_webViewController == nil)
        {
            _webViewController = [[PhWebViewController alloc] init];
            [NSBundle loadNibNamed: @"FacebookBrowser" owner: _webViewController];
        }

        // Prepare window but keep it ordered out. The _webViewController will make it visible
        // if it needs to.
        _webViewController.parent = self;
		_webViewController.tokenResultCompletionHandler = block;
        _webViewController.permissions = scope;
        [_webViewController.webView setMainFrameURL: authURL];
    }
}

- (void) setAccessToken:(NSString *)accessToken expires:(NSTimeInterval)tokenExpires permissions:(NSString *)perms error:(NSString *)errorReason {
	// Delegate will be notified, instead of executing a certain completion block
	PhCompletionBlock block = ^(NSDictionary *result){
		if ([_delegate respondsToSelector: @selector(tokenResult:)])
			[_delegate tokenResult: result];
	};
	[self setAccessToken:accessToken expires:tokenExpires permissions:perms error:errorReason withCompletionBlock:block];
}

- (void) setAccessToken: (NSString*) accessToken expires: (NSTimeInterval) tokenExpires permissions: (NSString*) perms error: (NSString*) errorReason withCompletionBlock:(PhCompletionBlock)block
{
	[self setAccessToken: accessToken expires: tokenExpires permissions: perms];
	[self notifyDelegateForToken: _authToken withError: errorReason withCompletionBlock:block];
}

- (NSString*) accessToken
{
    return [_authToken.authenticationToken copy];
}

#pragma mark -
#pragma mark FQL Requests

/** Send a FQL request, notify the delegate once the result is available. */
- (void) sendFQLRequest: (NSString*) query
{
	NSCAssert(_delegate!=nil, @"Trying to send FQL request with no delegate set.");
	[self sendFQLRequest:query withCompletionBlock:nil];
}

/** Send a FQL request, execute the specified completion handler block once the result is available. */
- (void) sendFQLRequest:(NSString *)query withCompletionBlock:(PhCompletionBlock)block {
	NSMutableDictionary *allParams = [NSMutableDictionary dictionaryWithDictionary:@{
										@"query" : query,
									 }];
	if (block != nil)
		[allParams setObject: [block copy] forKey:@"completionBlock"];
	
    [NSThread detachNewThreadSelector: @selector(sendFacebookFQLRequest:) toTarget: self withObject: allParams];
}

#pragma mark -
#pragma mark Graph Requests

/** Send a simple GET request, notify the delegate once the result is available. */
- (void) sendRequest: (NSString*) request
{
 	NSCAssert(_delegate!=nil, @"Trying to send request with no delegate set.");
   [self sendRequest: request params: nil usePostRequest: NO];
}

/** Send a simple GET request, execute the specified completion handler block once the result is available. */
- (void) sendRequest:(NSString *)request withCompletionBlock:(PhCompletionBlock)block {
    [self sendRequest: request params: nil usePostRequest: NO withCompletionBlock:block];
}

/** Send a complex request, notify the delegate once the result is available. */
- (void) sendRequest: (NSString*) request params: (NSDictionary*) params usePostRequest: (BOOL) postRequest
{
	NSCAssert(_delegate!=nil, @"Trying to send complex request with no delegate set.");
	[self sendRequest:request params:params usePostRequest:postRequest withCompletionBlock:nil];
}

/** Send a complex request, execute the specified completion handler block once the result is available. */
- (void) sendRequest:(NSString *)request params:(NSDictionary *)params usePostRequest:(BOOL)postRequest withCompletionBlock:(PhCompletionBlock)block {

	NSMutableDictionary *allParams = [NSMutableDictionary dictionaryWithObject: request forKey: @"request"];
    [allParams setObject: [NSNumber numberWithBool: postRequest] forKey: @"postRequest"];

    if (params != nil)
        [allParams setObject: params forKey: @"params"];
	if (block != nil)
		[allParams setObject: [block copy] forKey:@"completionBlock"];

	[NSThread detachNewThreadSelector: @selector(sendFacebookRequest:) toTarget: self withObject: allParams];
}

#pragma mark -
#pragma mark Private Request Methods

/** All previous defined methods are wrappers for one of the following two methods. */

- (void) sendFacebookRequest: (NSDictionary*) allParams
{
    @autoreleasepool {

        if (_authToken)
        {
		PhCompletionBlock block = [allParams objectForKey:@"completionBlock"];
            NSString *request = [allParams objectForKey: @"request"];
            NSString *str;
            BOOL postRequest = [[allParams objectForKey: @"postRequest"] boolValue];

            if (postRequest)
            {
                str = [NSString stringWithFormat: kFBGraphApiPostURL, request];
            }
            else
            {
                // Check if request already has optional parameters
                NSString *formatStr = kFBGraphApiGetURL;
                NSRange rng = [request rangeOfString:@"?"];
                if (rng.length > 0)
                    formatStr = kFBGraphApiGetURLWithParams;
                str = [NSString stringWithFormat: formatStr, request, _authToken.authenticationToken];
            }


            NSDictionary *params = [allParams objectForKey: @"params"];
            NSMutableString *strPostParams = nil;
            if (params != nil)
            {
                if (postRequest)
                {
                    strPostParams = [NSMutableString stringWithFormat: @"access_token=%@", _authToken.authenticationToken];
                    for (NSString *p in [params allKeys])
                        [strPostParams appendFormat: @"&%@=%@", p, [params objectForKey: p]];
                }
                else
                {
                    NSMutableString *strWithParams = [NSMutableString stringWithString: str];
                    for (NSString *p in [params allKeys])
                        [strWithParams appendFormat: @"&%@=%@", p, [params objectForKey: p]];
                    str = strWithParams;
                }
            }

            NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: str]];

            if (postRequest)
            {
                NSData *requestData = [NSData dataWithBytes: [strPostParams UTF8String] length: [strPostParams length]];
                [req setHTTPMethod: @"POST"];
                [req setHTTPBody: requestData];
                [req setValue: @"application/x-www-form-urlencoded" forHTTPHeaderField: @"content-type"];
            }

            NSURLResponse *response = nil;
            NSError *error = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest: req returningResponse: &response error: &error];

		NSString *resultStr = [[NSString alloc] initWithBytesNoCopy: (void*)[data bytes] length: [data length] encoding:NSASCIIStringEncoding freeWhenDone: NO];

		NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
								resultStr, @"result",
								request, @"request",
								data, @"raw",
								self, @"sender",
								nil];

		// Execute completion block if available, notify delegate otherwise
		if (block != nil) {
			block(result);
		} else {
			if ([_delegate respondsToSelector: @selector(requestResult:)]) {
				[_delegate performSelectorOnMainThread:@selector(requestResult:) withObject: result waitUntilDone:YES];
			}
		}
        }
    }
}

- (void) sendFacebookFQLRequest: (NSDictionary*) allParams
{
	@autoreleasepool {

		NSString *query = [allParams objectForKey:@"query"];
		PhCompletionBlock block = [allParams objectForKey:@"completionBlock"];

    if (_authToken)
    {
        NSString *str = [NSString stringWithFormat: kFBGraphApiFqlURL, [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], _authToken.authenticationToken];

        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: str]];

        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest: req returningResponse: &response error: &error];

			NSString *resultStr = [[NSString alloc] initWithBytesNoCopy: (void*)[data bytes] length: [data length] encoding:NSASCIIStringEncoding freeWhenDone: NO];
			NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
									resultStr, @"result",
									query, @"request",
									data, @"raw",
									self, @"sender",
									nil];

			// Execute completion block if available, notify delegate otherwise
			if (block != nil) {
				block(result);
			} else {
				if ([_delegate respondsToSelector: @selector(requestResult:)])
				{
					[_delegate performSelectorOnMainThread:@selector(requestResult:) withObject: result waitUntilDone:YES];
				}
			}
    }
    }
}

#pragma mark -
#pragma mark Notifications

- (void) webViewWillShowUI
{
    if ([_delegate respondsToSelector: @selector(willShowUINotification:)])
        [_delegate performSelectorOnMainThread: @selector(willShowUINotification:) withObject: self waitUntilDone: YES];
}

- (void) didDismissUI
{
    if ([_delegate respondsToSelector: @selector(didDismissUI:)])
        [_delegate performSelectorOnMainThread: @selector(didDismissUI:) withObject: self waitUntilDone: YES];
}

@end
