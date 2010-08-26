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

@synthesize window;

- (void) applicationDidFinishLaunching: (NSNotification*) aNotification 
{
    fb = [[PhFacebook alloc] initWithApplicationID: APPLICATION_ID];
}

@end
