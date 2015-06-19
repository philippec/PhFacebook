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
@private
    PhFacebook *_fb;

    NSTextField *_token_label;
    NSTextField *_request_label;
    NSTextField *_request_text;
    NSTextView *_result_text;
    NSImageView *_profile_picture;
    NSButton *_send_request;
    NSWindow *_window;
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
