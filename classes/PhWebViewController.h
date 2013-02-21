//
//  PhWebViewController.h
//  PhFacebook
//
//  Created by Philippe on 10-08-27.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class PhFacebook;
typedef void (^PhCompletionBlock)(NSDictionary *result);

@interface PhWebViewController : NSObject <NSWindowDelegate>
{
	// since the controller might be allocated to get a token (which could invoke a completion handler), the completion handler block must be specified
	PhCompletionBlock tokenResultCompletionHandler;
    NSString *permissions;
}

@property (retain) IBOutlet NSWindow *window;
@property (retain) IBOutlet WebView *webView;
@property (retain) IBOutlet NSButton *cancelButton;
@property (copy) PhCompletionBlock tokenResultCompletionHandler;
@property (retain) PhFacebook *parent;
@property (nonatomic, strong) NSString *permissions;

- (IBAction) cancel: (id) sender;

@end
