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

- (id) initWithApplicationID: (NSString*) appID delegate: (id) delegate
{
    if ((self == [super init]))
    {
        if (appID)
            _appID = [[NSString stringWithString: appID] retain];
        _delegate = delegate; // Don't retain delegate to avoid retain cycles
        _webViewController = nil;
        _authToken = nil;
        _permissions = nil;
    }
    DebugLog(@"Initialized with AppID '%@'", _appID);

    return self;
}

- (void) dealloc
{
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
        [defaults setObject: token.expiry forKey: kFBStoreTokenExpiry];
        [defaults setObject: token.permissions forKey: kFBStoreAccessPermissions];

        [result setObject: [NSNumber numberWithBool: YES] forKey: @"valid"];
    }
    else
    {
        [result setObject: [NSNumber numberWithBool: NO] forKey: @"valid"];
        [result setObject: errorReason forKey: @"error"];
    }

    if ([_delegate respondsToSelector: @selector(tokenResult:)])
        [_delegate tokenResult: result];
}

#pragma mark Access

- (void) clearToken
{
    [_authToken release];
    _authToken = nil;
}

- (void) setAccessToken: (NSString*) accessToken expires: (NSTimeInterval) tokenExpires permissions: (NSString*) perms
{
    [self clearToken];

    if (accessToken)
        _authToken = [[PhAuthenticationToken alloc] initWithToken: accessToken secondsToExpiry: tokenExpires permissions: perms];
}

- (void) getAccessTokenForPermissions: (NSArray*) permissions cached: (BOOL) canCache
{
    BOOL validToken = NO;
    NSString *scope = [permissions componentsJoinedByString: @","];

    if (canCache && _authToken == nil)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *accessToken = [defaults stringForKey: kFBStoreAccessToken];
        NSDate *date = [defaults objectForKey: kFBStoreTokenExpiry];
        NSString *perms = [defaults stringForKey: kFBStoreAccessPermissions];
        if (accessToken && date && perms)
        {
            NSTimeInterval seconds = [date timeIntervalSinceNow];
            // Do not notify delegate yet...
            [self setAccessToken: accessToken expires: seconds permissions: perms];
        }
    }

    if ([_authToken.permissions isCaseInsensitiveLike: scope])
    {
        // We already have a token for these permissions; check if it has expired or not
        if ([[_authToken.expiry laterDate: [NSDate date]] isEqual: _authToken.expiry])
            validToken = YES;
    }

    if (validToken)
    {
        [self notifyDelegateForToken: _authToken withError: nil];
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

        // Retrieve token from web page
        if (_webViewController == nil)
        {
            _webViewController = [[PhWebViewController alloc] init];
            [NSBundle loadNibNamed: @"FacebookBrowser" owner: _webViewController];
        }

        // Prepare window but keep it ordered out. The _webViewController will make it visible
        // if it needs to.
        _webViewController.parent = self;
        _webViewController.permissions = scope;
        [_webViewController.webView setMainFrameURL: authURL];
    }
}

- (void) setAccessToken: (NSString*) accessToken expires: (NSTimeInterval) tokenExpires permissions: (NSString*) perms error: (NSString*) errorReason
{
	[self setAccessToken: accessToken expires: tokenExpires permissions: perms];
	[self notifyDelegateForToken: _authToken withError: errorReason];
}

- (NSString*) accessToken
{
    return _authToken.authenticationToken;
}

- (void) sendFacebookRequest: (NSDictionary*) allParams
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    if (_authToken)
    {
        NSString *request = [allParams objectForKey: @"request"];
        NSString *str = [NSString stringWithFormat: kFBGraphApiURL, request, _authToken.authenticationToken];
        
        NSDictionary *params = [allParams objectForKey:@"params"];
        if (params != nil) 
        {
            NSMutableString *strWithParams = [NSMutableString stringWithString: str];
            for (NSString *p in [params allKeys]) 
                [strWithParams appendFormat: @"&%@=%@", p, [params objectForKey: p]];
            str = strWithParams;
        }
        
        NSURLRequest *req = [NSURLRequest requestWithURL: [NSURL URLWithString: str]];
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest: req returningResponse: &response error: &error];

        if ([_delegate respondsToSelector: @selector(requestResult:)])
        {
            NSString *str = [[NSString alloc] initWithBytesNoCopy: (void*)[data bytes] length: [data length] encoding:NSASCIIStringEncoding freeWhenDone: NO];

            NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                str, @"result",
                request, @"request",
                self, @"sender",
                nil];
            [_delegate performSelectorOnMainThread:@selector(requestResult:) withObject: result waitUntilDone:YES];
            [str release];
        }
    }
    [pool drain];
}

- (void) sendRequest: (NSString*) request params: (NSDictionary*) params;
{
    NSMutableDictionary *allParams = [NSMutableDictionary dictionaryWithObject: request forKey: @"request"];
    if (params != nil)
        [allParams setObject: params forKey: @"params"];

	[NSThread detachNewThreadSelector: @selector(sendFacebookRequest:) toTarget: self withObject: allParams];    
}

- (void) sendRequest: (NSString*) request
{
    [self sendRequest: request params: nil];
}

#pragma mark Notifications

- (void) webViewWillShowUI
{
    if ([_delegate respondsToSelector: @selector(willShowUINotification:)])
        [_delegate performSelectorOnMainThread:@selector(willShowUINotification:) withObject: self waitUntilDone:YES];
}

@end
