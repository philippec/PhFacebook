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
@synthesize request_label;
@synthesize request_text;
@synthesize result_text;
@synthesize send_request;
@synthesize window;

- (void) applicationDidFinishLaunching: (NSNotification*) aNotification
{
    fb = [[PhFacebook alloc] initWithApplicationID: APPLICATION_ID delegate: self];
    self.token_label.stringValue = @"Invalid";
    [self.request_label setEnabled: NO];
    [self.request_text setEnabled: NO];
    [self.send_request setEnabled: NO];
    [self.result_text setEnabled: NO];
}

#pragma mark IBActions

- (IBAction) getAccessToken: (id) sender
{
    [fb getAccessTokenForPermissions: [NSArray arrayWithObject:@"read_stream"]];
}

- (IBAction) sendRequest: (id) sender
{
    NSLog(@"sending request {%@}", request_text.stringValue);
}

#pragma mark PhFacebookDelegate methods

- (void) validToken: (PhFacebook*) fbObject
{
    self.token_label.stringValue = @"Valid";
    [self.request_label setEnabled: YES];
    [self.request_text setEnabled: YES];
    [self.send_request setEnabled: YES];
    [self.result_text setEnabled: YES];
}

@end
