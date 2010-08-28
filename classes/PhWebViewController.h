//
//  PhWebViewController.h
//  PhFacebook
//
//  Created by Philippe on 10-08-27.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface PhWebViewController : NSObject
{
    IBOutlet NSWindow *window;
    IBOutlet WebView *webView;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet WebView *webView;

@end
