PhFacebook: easy-to-use MacOSX framework for the Facebook API
=============================================================

Summary
-------

PhFacebook is an embeddable MacOSX framework to easily access Facebook's API.

* Uses Facebook's new 'graph' API internally, handles OAuth in a WebView for you and returns JSON strings.

* Comes with a sample application to show you how to use it.

* Supports extended permissions.

* Localized in English and French.

How-to-use
----------

1.  Set your Facebook Application Type

    * Go to your [Facebook application page](https://developers.facebook.com/apps/).
    * Select your application in the left-hand column (if you have more than one application).
    * In the Summary section, note the "App ID/API Key". This is `YOUR_APPLICATION_ID`, used in section 3.

2.  Build PhFacebook.framework

    * Open "PhFacebook.xcodeproj" and "Build for Archiving" in the Product -> Build menu. This should build both the Debug and Release version. If it does not, check your Build Schemes in Product -> Edit Scheme…
    * Select "PhFacebook.framework" in the Finder. It should be in the "Release" folder; you probably don't want to embed the Debug version.
    * Drag it to your "Frameworks" folder in your Project list and add it to the appropriate target.
    * In your appropriate target, under "Build Settings", select "Runpath Search Paths" in the "Linking" category, and enter "@loader_path/../Frameworks" (without the quotes). This step is essential for linking, as the Framework is built with a "@rpath" search path, which will be replaced at runtime by your application.
    * In your appropriate target, add a "Copy" build phase. Set its destination to "Frameworks".
    * Drag "PhFacebook.framework" to this Copy build phase to ensure it is embedded in your application.
    * Verify that you can build and run your application and there are no linker or runtime errors.

3.  Prepare to use PhFacebook.framework

    * Import <PhFacebook/PhFacebook> where appropriate.
    * Create a new `PhFacebook*` object and set yourself as the delegate:
            PhFacebook* fb = [[PhFacebook alloc] initWithApplicationID: YOUR_APPLICATION_ID delegate: self];
    * Implement the PhFacebookDelegate protocol:
            - (void) tokenResult: (NSDictionary*) result;
            - (void) requestResult: (NSDictionary*) result;
            @optional
            - (void) willShowUINotification: (PhFacebook*) sender;
            - (void) didDismissUI: (PhFacebook*) sender;
      These methods will be called by PhFacebook when an authorization token was requested or an API request was made.
      More information below.
    * __See the sample application if you have any issues__.

4.  Request an authorization token:
        [fb getAccessTokenForPermissions: [NSArray arrayWithObjects: @"read_stream", @"publish_stream", nil]];
    * Just list the permissions you need in an array, or nil if you don't require special permissions.
    * There is a [list of permissions](http://developers.facebook.com/docs/authentication/permissions).
    * Your delegate's `tokenResult:` will get called with a dictionary. If `[[result valueForKey: @"valid"] boolValue]` is YES, the authorization request was successful.
    * If PhFacebook needs to display some UI (such as the Facebook Authentication dialog), your delegate's `willShowUINotification:` will get called. Take this opportunity to notify the user via a Dock bounce, for instance.
    * If the authorization was not successful, check `[result valueForKey: @"error"]`.
    * __Note:__ the framework may put up an authorization window from Facebook. Subsequent requests are cached and/or hidden from the user as much as possible.
    * __Therefore:__ request a new token (and check its validity) for every series of operations. If some time elapses (for instance, you auto-check every hour), a new token is in order. _It is cheap to call this method_.

5.  Make API requests
    * You do not need to provide the URL or authorization token, PhFacebook takes care of that:
            [fb sendRequest: @"me/friends"];
    * Your delegate's `requestResult:` will get called with a dictionary, whose "result" key's value is a JSON string from Facebook.
    * You can use a JSON parser to turn the string into an NSDictionary, for instance SBJSON.
    * If the JSON string contains no data, check that you requested an authorization token with the correct permissions.
    * [The API is documented](http://developers.facebook.com/docs/api).

Notes
-----

> The sample application requires your Application ID to function properly. The first time you build the application, it will create a (non-versioned) file called `ApplicationID.h`.
> You __must__ edit this file with your Application ID from [this Facebook page](http://www.facebook.com/developers/apps.php) before the sample app will build.

Tips and Tricks
---------------

* Embedding a framework is easier if you set up a common build folder in Xcode -> Preferences -> Building -> Customized location.
* Linking frameworks can sometimes be a black art. You may have to add `@loader_path/../Frameworks` to the "Runpath search paths" in Xcode (thanks to Oscar Del Ben for the tip).
* You can `#define ALWAYS_SHOW_UI` in PhWebViewController.m to help you debug the framework, since by default the framework tries to hide UI as much as possible. 
