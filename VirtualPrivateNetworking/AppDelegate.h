//
//  AppDelegate.h
//  VirtualPrivateNetworking
//
//  Created by Felipe Aragon on 7/04/15.
//  Copyright (c) 2015 Felipe Aragon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property(strong, nonatomic) IBOutlet NSView *contentview;
@property(strong, nonatomic) NSViewController *contentviewController;

@end

