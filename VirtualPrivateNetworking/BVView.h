//
//  BVView.h
//  FFMPEG
//
//  Created by Felipe Aragon on 25/03/15.
//  Copyright (c) 2015 Felipe Aragon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BVView : NSView

@property (weak)  NSTextField *txt_name;
@property (weak)  NSTextField *txt_status;
@property (strong)  NSImageView *imgview;
@property (nonatomic, strong) NSString *name_mac;

@end
