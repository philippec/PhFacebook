//
//  PhFacebook.h
//  PhFacebook
//
//  Created by Philippe on 10-08-25.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PhFacebook : NSObject 
{
    NSString *_appID;
}

- (id) initWithApplicationID: (const NSString*) appID;

@end
