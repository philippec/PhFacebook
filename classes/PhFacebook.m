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
    NSLog(@"Initialized with AppID '%@'", _appID);

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

- (void) getAccessTokenForPermissions: (NSArray*) permissions
{
    BOOL validToken = NO;
    NSString *scope = [permissions componentsJoinedByString: @","];

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

- (void) setAccessToken: (NSString*) accessToken expires: (NSString*) tokenExpires permissions: (NSString*) perms error: (NSString*) errorReason
{
    [_webViewController.window orderOut: self];

    [_authToken release];
    _authToken = nil;

    if (accessToken)
        _authToken = [[PhAuthenticationToken alloc] initWithToken: accessToken secondsToExpiry: [tokenExpires floatValue] permissions: perms];

    [self notifyDelegateForToken: _authToken withError: errorReason];
}

- (void) sendFacebookRequest: (NSString*) request
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    if (_authToken)
    {
        NSString *str = [NSString stringWithFormat: kFBGraphApiURL, request, _authToken.authenticationToken];
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

- (void) sendRequest: (NSString*) request
{
	[NSThread detachNewThreadSelector: @selector(sendFacebookRequest:) toTarget: self withObject: request];
}

@end
