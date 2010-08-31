//
//  PhWebViewController.m
//  PhFacebook
//
//  Created by Philippe on 10-08-27.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import "PhWebViewController.h"
#import "PhFacebook_URLs.h"
#import "PhFacebook.h"
#import "Debug.h"


@implementation PhWebViewController

@synthesize window;
@synthesize webView;
@synthesize cancelButton;
@synthesize parent;
@synthesize permissions;

- (id) init
{
    if ((self = [super init]))
    {
    }

    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) awakeFromNib
{
    NSBundle *bundle = [NSBundle bundleForClass: [PhFacebook class]];
    self.window.title = [bundle localizedStringForKey: @"FBAuthWindowTitle" value: @"" table: nil];
    self.cancelButton.title = [bundle localizedStringForKey: @"FBAuthWindowCancel" value: @"" table: nil];;
}

#pragma mark Delegate

- (void) showUI
{
    // Facebook needs user input, show the window
    [self.window makeKeyAndOrderFront: self];
    // Notify parent that we're about to show UI
    [self.parent webViewWillShowUI];
}


- (void) webView: (WebView*) sender didCommitLoadForFrame: (WebFrame*) frame;
{
    NSString *url = [sender mainFrameURL];
    DebugLog(@"didCommitLoadForFrame: {%@}", url);

    NSComparisonResult res = [url compare: kFBUIServerURL options: NSCaseInsensitiveSearch range: NSMakeRange(0, [kFBUIServerURL length])];
    if (res == NSOrderedSame)
        [self showUI];
}

- (NSString*) extractParameter: (NSString*) param fromURL: (NSString*) url
{
    NSString *res = nil;

    NSRange paramNameRange = [url rangeOfString: param options: NSCaseInsensitiveSearch];
    if (paramNameRange.location != NSNotFound)
    {
        // Search for '&' or end-of-string
        NSRange searchRange = NSMakeRange(paramNameRange.location + paramNameRange.length, [url length] - (paramNameRange.location + paramNameRange.length));
        NSRange ampRange = [url rangeOfString: @"&" options: NSCaseInsensitiveSearch range: searchRange];
        if (ampRange.location == NSNotFound)
            ampRange.location = [url length];
        res = [url substringWithRange: NSMakeRange(searchRange.location, ampRange.location - searchRange.location)];
    }

    return res;
}

- (void) webView: (WebView*) sender didFinishLoadForFrame: (WebFrame*) frame
{
    NSString *url = [sender mainFrameURL];
    DebugLog(@"didFinishLoadForFrame: {%@}", url);

    NSComparisonResult res = [url compare: kFBLoginSuccessURL options: NSCaseInsensitiveSearch range: NSMakeRange(0, [kFBLoginSuccessURL length])];
    if (res == NSOrderedSame)
    {
        NSString *accessToken = [self extractParameter: kFBAccessToken fromURL: url];
        NSString *tokenExpires = [self extractParameter: kFBExpiresIn fromURL: url];
        NSString *errorReason = [self extractParameter: kFBErrorReason fromURL: url];

        [parent setAccessToken: accessToken expires: tokenExpires permissions: self.permissions error: errorReason];
    }

    res = [url compare: kFBLoginURL options: NSCaseInsensitiveSearch range: NSMakeRange(0, [kFBLoginURL length])];
    if (res == NSOrderedSame)
        [self showUI];
}



@end
