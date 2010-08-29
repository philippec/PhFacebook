//
//  FacebookTestAppDelegate.h
//  FacebookTest
//
//  Created by Philippe on 10-08-25.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <PhFacebook/PhFacebook.h>

@interface FacebookTestAppDelegate : NSObject <PhFacebookDelegate>
{
    PhFacebook *fb;

    NSTextField *token_label;
    NSWindow *window;
}

@property (assign) IBOutlet NSTextField *token_label;
@property (assign) IBOutlet NSWindow *window;

- (IBAction) getAccessToken: (id) sender;

@end
