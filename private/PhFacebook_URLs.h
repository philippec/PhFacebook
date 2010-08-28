//
//  PhFacebook_URLs.h
//  PhFacebook
//
//  URLs used by the Facebook Graph API
//
//  Created by Philippe on 10-08-28.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//


static NSString *kFBAuthorizeURL = @"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=http://www.facebook.com/connect/login_success.html&type=user_agent&display=popup";

static NSString *kFBAuthorizeWithScopeURL = @"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=http://www.facebook.com/connect/login_success.html&scope=%@&type=user_agent&display=popup";
