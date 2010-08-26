//
//  FacebookTestAppDelegate.h
//  FacebookTest
//
//  Created by Philippe on 10-08-25.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <PhFacebook/PhFacebook.h>

@interface FacebookTestAppDelegate : NSObject <NSApplicationDelegate>
{
    PhFacebook *fb;
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
