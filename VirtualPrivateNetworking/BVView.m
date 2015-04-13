//
//  BVView.m
//  FFMPEG
//
//  Created by Felipe Aragon on 25/03/15.
//  Copyright (c) 2015 Felipe Aragon. All rights reserved.
//

#import "BVView.h"


static const NSSize itemSize = { 160, 90};
static const NSPoint text_nameOrigin = { 10, 50 };
static const NSSize text_nameSize = { 150, 20 };

static const NSPoint text_statusOrigin = { 0, 0 };
static const NSSize text_statusSize = { 150, 20 };

static const NSPoint imageviewOrigin = { 0, 0 };
static const NSSize imageviewSize = { 160, 90 };



@implementation BVView

NSImageView *imageviewback;
NSTextField *text_name;

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:(NSRect){frameRect.origin, itemSize}];
    if (self) {
        
        NSImageView *imageview=[[NSImageView alloc] initWithFrame:(NSRect){imageviewOrigin, imageviewSize}];
        imageview.image=[NSImage imageNamed:@""];
        [self addSubview:imageview];
        _imgview = imageview;
        
        NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:[self visibleRect]
                                                                     options:NSTrackingMouseEnteredAndExited | NSTrackingInVisibleRect |NSTrackingActiveAlways
                                                                       owner:self
                                                                    userInfo:nil];
        
        [self addTrackingArea:trackingArea];
        
        /*NSTextField *text_name=[[NSTextField alloc] initWithFrame:(NSRect){text_nameOrigin, text_nameSize}];
        [text_name setEditable:NO];
        [text_name setBordered:NO];
        [text_name setAlignment:NSCenterTextAlignment];
        [self addSubview:text_name];
        _txt_name = text_name;
        
        NSTextField *text_status=[[NSTextField alloc] initWithFrame:(NSRect){text_statusOrigin, text_statusSize}];
        [text_status setEditable:NO];
        [text_status setBordered:NO];
        [text_status setAlignment:NSCenterTextAlignment];
        [self addSubview:text_status];
         _txt_status = text_status;*/
        
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)mouseEntered:(NSEvent *)theEvent {
    //draw rollover
     //NSLog(@"mouseEntered");
    if (![_name_mac isEqualToString:@"Default"]) {
        imageviewback=[[NSImageView alloc] initWithFrame:(NSRect){imageviewOrigin, imageviewSize}];
        imageviewback.image=[NSImage imageNamed:@"backover"];
        [self addSubview:imageviewback];
        
        text_name=[[NSTextField alloc] initWithFrame:(NSRect){text_nameOrigin, text_nameSize}];
        [text_name setEditable:NO];
        [text_name setBordered:NO];
        [text_name setTextColor:[NSColor whiteColor]];
        [text_name setAlignment:NSCenterTextAlignment];
        [text_name setBackgroundColor:[NSColor clearColor]];
        [text_name setStringValue:_name_mac];
        [self addSubview:text_name];

    }
    
}

-(void)mouseExited:(NSEvent *)theEvent {
    //draw normal
    // NSLog(@"mouseExited");
    if (![_name_mac isEqualToString:@"Default"]) {
        [imageviewback removeFromSuperview];
        [text_name removeFromSuperview];
    }
    
}

-(void)mouseDown:(NSEvent *)theEvent {
    //draw selected
     NSLog(@"mouseDown");
}

-(void)mouseUp:(NSEvent *)theEvent {
    //draw normal
     NSLog(@"mouseUp");
}

@end
