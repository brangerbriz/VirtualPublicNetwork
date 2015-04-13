//
//  UsersMacViewcontroller.h
//  VirtualPrivateNetworking
//
//  Created by Felipe Aragon on 7/04/15.
//  Copyright (c) 2015 Felipe Aragon. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Cocoa/Cocoa.h>
#import "quicklibav.h"
#import "swscale.h"
#import "Response.h"

@interface UsersMacViewcontroller : NSViewController

@property (nonatomic, strong) Response* response;
@property (nonatomic, strong) NSMutableArray *list_mac;
@property (nonatomic, strong) NSMutableArray *list_mac_collection;
@property (nonatomic, weak) NSString *name;

@property (weak) IBOutlet NSScrollView *content_table;
@property (weak) IBOutlet NSClipView *viewclip;
@property (weak) IBOutlet NSTableView *tebleview;

@property (weak) IBOutlet NSButton *btn_list;
@property (weak) IBOutlet NSButton *btn_collection;

@property (weak) IBOutlet NSView *view_content_collection;
@property (weak) IBOutlet NSImageView *image_view;
@property (weak) IBOutlet NSImageView *image_view_back;
@property (weak) IBOutlet NSTextField *text_live;

@property BOOL init;

- (IBAction)print_list:(id)sender;
- (IBAction)print_collection:(id)sender;
-(void)logout;
-(void )startCapture;

@end
