//
//  FacebookTestAppDelegate.m
//  FacebookTest
//
//  Created by Philippe on 10-08-25.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import "FacebookTestAppDelegate.h"
#import "ApplicationID.h"

@implementation FacebookTestAppDelegate

@synthesize token_label;
@synthesize window;

- (void) applicationDidFinishLaunching: (NSNotification*) aNotification 
{
    fb = [[PhFacebook alloc] initWithApplicationID: APPLICATION_ID delegate: self];
}

#pragma mark IBActions

- (IBAction) getAccessToken: (id) sender
{
    NSLog(@"Getting access token...");
}

#pragma mark PhFacebookDelegate methods

- (void) validToken: (PhFacebook*) fbObject
{
    NSLog(@"Received valid token for %@", fb);
}

@end
