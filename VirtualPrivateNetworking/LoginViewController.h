//
//  LoginViewController.h
//  VirtualPrivateNetworking
//
//  Created by Felipe Aragon on 7/04/15.
//  Copyright (c) 2015 Felipe Aragon. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LoginViewController : NSViewController<NSAlertDelegate>

@property (weak) IBOutlet NSTextField *textview_handler;
@property (weak) IBOutlet NSView *indicator;
@property (weak) IBOutlet NSButton *btn_join_room;

- (IBAction)goRoom:(id)sender;

@end
