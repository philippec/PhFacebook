//
//  PhWebViewController.m
//  PhFacebook
//
//  Created by Philippe on 10-08-27.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import "PhWebViewController.h"


@implementation PhWebViewController

@synthesize window;
@synthesize webView;

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

#pragma mark Delegate

- (void) webView: (WebView*) sender willPerformClientRedirectToURL: (NSURL*) URL
           delay: (NSTimeInterval) seconds
        fireDate: (NSDate*) date
        forFrame: (WebFrame*) frame
{
    NSLog(@"senderwillPerformClientRedirectToURL: %@", URL);
}


@end
