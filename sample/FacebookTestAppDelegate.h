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
    NSTextField *request_label;
    NSTextField *request_text;
    NSTextView *result_text;
    NSImageView *profile_picture;
    NSButton *send_request;
    NSWindow *window;
}

@property (assign) IBOutlet NSTextField *token_label;
@property (assign) IBOutlet NSTextField *request_label;
@property (assign) IBOutlet NSTextField *request_text;
@property (assign) IBOutlet NSTextView *result_text;
@property (assign) IBOutlet NSImageView *profile_picture;
@property (assign) IBOutlet NSButton *send_request;
@property (assign) IBOutlet NSWindow *window;

- (IBAction) getAccessToken: (id) sender;
- (IBAction) sendRequest: (id) sender;

@end
