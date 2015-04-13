//
//  AppDelegate.m
//  VirtualPrivateNetworking
//
//  Created by Felipe Aragon on 7/04/15.
//  Copyright (c) 2015 Felipe Aragon. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "UsersMacViewcontroller.h"
#import "Response.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    _contentviewController=[[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
    [_contentview addSubview:[_contentviewController view]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveLoginNotification:) name:@"LoginNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveLogoutNotification:) name:@"LogoutNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:self.window];
}

- (void) receiveLoginNotification:(NSNotification *) notification
{
    // [notification name] should always be @"TestNotification"
    // unless you use this method for observation of other notifications
    // as well.
    
    if ([[notification name] isEqualToString:@"LoginNotification"]){
        if ([notification.object isKindOfClass:[Response class]]) {
            [[_contentviewController view] removeFromSuperview];
            _contentviewController=[[UsersMacViewcontroller alloc] initWithNibName:@"UsersMacViewcontroller" bundle:nil];
            UsersMacViewcontroller *controller=(UsersMacViewcontroller *)_contentviewController;
            Response *object=(Response *)notification.object;
            controller.response=object;
            [_contentview addSubview:[_contentviewController view]];
            //[controller startCapture];
        }
        
    }
    
}

- (void) receiveLogoutNotification:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"LogoutNotification"]){
        [[_contentviewController view] removeFromSuperview];
        _contentviewController=[[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        [_contentview addSubview:[_contentviewController view]];
    }
    
}

- (void)windowWillClose:(NSNotification *)notification{
    if ([_contentviewController isKindOfClass:[UsersMacViewcontroller class]]) {
        UsersMacViewcontroller *controller=(UsersMacViewcontroller *)_contentviewController;
        [controller logout];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
   
}

@end
