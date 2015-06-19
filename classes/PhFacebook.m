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

@interface PhFacebook()
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) PhWebViewController *webViewController;
@property (nonatomic, retain) PhAuthenticationToken *authToken;
@property (nonatomic, copy) NSString *permissions;

@end

@implementation PhFacebook

@synthesize appID=_appID, delegate=_delegate, webViewController=_webViewController, authToken=_authToken, permissions=_permissions;

#pragma mark Initialization

- (id) initWithApplicationID: (NSString*) appID delegate: (id) delegate
{
    if ((self = [super init]))
    {
        if (appID)
        {
            _appID = [[NSString stringWithString: appID] retain];
        }
        _delegate = delegate; // Don't retain delegate to avoid retain cycles
        _webViewController = nil;
        _authToken = nil;
        _permissions = nil;
        DebugLog(@"Initialized with AppID '%@'", _appID);
    }

    return self;
}

- (void) dealloc
{
    _delegate = nil;
    [_appID release];
    [_webViewController release];
    [_authToken release];
    [super dealloc];
}

- (void) notifyDelegateForToken: (PhAuthenticationToken*) token withError: (NSString*) errorReason
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if (token)
    {
        // Save it to user defaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject: token.authenticationToken forKey: kFBStoreAccessToken];
        if (token.expiry)
        {
            [defaults setObject: token.expiry forKey: kFBStoreTokenExpiry];
        }
        else
        {
            [defaults removeObjectForKey: kFBStoreTokenExpiry];
        }
        [defaults setObject: token.permissions forKey: kFBStoreAccessPermissions];

        [result setObject: [NSNumber numberWithBool: YES] forKey: @"valid"];
    }
    else
    {
        [result setObject: [NSNumber numberWithBool: NO] forKey: @"valid"];
        [result setObject: errorReason forKey: @"error"];
    }

    if ([self.delegate respondsToSelector: @selector(tokenResult:)])
    {
        [self.delegate tokenResult: result];
    }
}

#pragma mark Access

-(void) invalidateCachedToken
{
    self.authToken = nil;
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
    self.authToken = nil;

    if (accessToken)
    {
        self.authToken = [[[PhAuthenticationToken alloc] initWithToken: accessToken secondsToExpiry: tokenExpires permissions: perms] autorelease];
    }
}

- (void) getAccessTokenForPermissions: (NSArray*) permissions cached: (BOOL) canCache
{
    BOOL validToken = NO;
    NSString *scope = [permissions componentsJoinedByString: @","];

    if (canCache && self.authToken == nil)
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

    if ([self.authToken.permissions isCaseInsensitiveLike: scope])
    {
        // We already have a token for these permissions; check if it has expired or not
        if (self.authToken.expiry == nil || [[self.authToken.expiry laterDate: [NSDate date]] isEqual: self.authToken.expiry])
        {
            validToken = YES;
        }
    }

    if (validToken)
    {
        [self notifyDelegateForToken: self.authToken withError: nil];
    }
    else
    {
        self.authToken = nil;

        // Use self.webViewController to request a new token
        NSString *authURL;
        if (scope)
        {
            authURL = [NSString stringWithFormat: kFBAuthorizeWithScopeURL, self.appID, kFBLoginSuccessURL, scope];
        }
        else
        {
            authURL = [NSString stringWithFormat: kFBAuthorizeURL, self.appID, kFBLoginSuccessURL];
        }
      
        if ([self.delegate respondsToSelector: @selector(needsAuthentication:forPermissions:)])
        {
            if ([self.delegate needsAuthentication: authURL forPermissions: scope])
            {
                // If needsAuthentication returns YES, let the delegate handle the authentication UI
                return;
            }
        }
      
        // Retrieve token from web page
        if (self.webViewController == nil)
        {
            self.webViewController = [[[PhWebViewController alloc] init] autorelease];
            [NSBundle loadNibNamed: @"FacebookBrowser" owner: self.webViewController];
        }

        // Prepare window but keep it ordered out. The webViewController will make it visible
        // if it needs to.
        self.webViewController.parent = self;
        self.webViewController.permissions = scope;
        [self.webViewController.webView setMainFrameURL: authURL];
    }
}

- (void) setAccessToken: (NSString*) accessToken expires: (NSTimeInterval) tokenExpires permissions: (NSString*) perms error: (NSString*) errorReason
{
	[self setAccessToken: accessToken expires: tokenExpires permissions: perms];
	[self notifyDelegateForToken: self.authToken withError: errorReason];
}

- (NSString*) accessToken
{
    return [[self.authToken.authenticationToken copy] autorelease];
}

- (void) sendFacebookRequest: (NSDictionary*) allParams
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    if (self.authToken)
    {
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
            {
                formatStr = kFBGraphApiGetURLWithParams;
            }
            str = [NSString stringWithFormat: formatStr, request, self.authToken.authenticationToken];
        }

        
        NSDictionary *params = [allParams objectForKey: @"params"];
        NSMutableString *strPostParams = nil;
        if (params != nil) 
        {
            if (postRequest)
            {
                strPostParams = [NSMutableString stringWithFormat: @"access_token=%@", self.authToken.authenticationToken];
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

        if ([self.delegate respondsToSelector: @selector(requestResult:)])
        {
            NSString *str = [[NSString alloc] initWithBytesNoCopy: (void*)[data bytes] length: [data length] encoding:NSASCIIStringEncoding freeWhenDone: NO];

            NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                str, @"result",
                request, @"request",
                data, @"raw",                                    
                self, @"sender",
                nil];
            [self.delegate performSelectorOnMainThread:@selector(requestResult:) withObject: result waitUntilDone:YES];
            [str release];
        }
    }
    [pool drain];
}

- (void) sendRequest: (NSString*) request params: (NSDictionary*) params usePostRequest: (BOOL) postRequest
{
    NSMutableDictionary *allParams = [NSMutableDictionary dictionaryWithObject: request forKey: @"request"];
    if (params != nil)
    {
        [allParams setObject: params forKey: @"params"];
    }

    [allParams setObject: [NSNumber numberWithBool: postRequest] forKey: @"postRequest"];

	[NSThread detachNewThreadSelector: @selector(sendFacebookRequest:) toTarget: self withObject: allParams];    
}

- (void) sendRequest: (NSString*) request
{
    [self sendRequest: request params: nil usePostRequest: NO];
}

- (void) sendFacebookFQLRequest: (NSString*) query
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    if (self.authToken)
    {
        NSString *str = [NSString stringWithFormat: kFBGraphApiFqlURL, [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], self.authToken.authenticationToken];

        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: str]];

        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest: req returningResponse: &response error: &error];

        if ([self.delegate respondsToSelector: @selector(requestResult:)])
        {
            NSString *str = [[NSString alloc] initWithBytesNoCopy: (void*)[data bytes] length: [data length] encoding:NSASCIIStringEncoding freeWhenDone: NO];

            NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                                    str, @"result",
                                    query, @"request",
                                    data, @"raw",
                                    self, @"sender",
                                    nil];
            [self.delegate performSelectorOnMainThread:@selector(requestResult:) withObject: result waitUntilDone:YES];
            [str release];
        }
    }
    [pool drain];
}

- (void) sendFQLRequest: (NSString*) query
{
    [NSThread detachNewThreadSelector: @selector(sendFacebookFQLRequest:) toTarget: self withObject: query];
}

#pragma mark Notifications

- (void) webViewWillShowUI
{
    if ([self.delegate respondsToSelector: @selector(willShowUINotification:)])
    {
        [self.delegate performSelectorOnMainThread: @selector(willShowUINotification:) withObject: self waitUntilDone: YES];
    }
}

- (void) didDismissUI
{
    if ([self.delegate respondsToSelector: @selector(didDismissUI:)])
    {
        [self.delegate performSelectorOnMainThread: @selector(didDismissUI:) withObject: self waitUntilDone: YES];
    }
}

@end
