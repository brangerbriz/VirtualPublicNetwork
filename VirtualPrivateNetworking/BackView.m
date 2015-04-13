//
//  BackView.m
//  MCAexhibit
//
//  Created by Felipe Aragon on 11/03/15.
//  Copyright (c) 2015 Felipe Aragon. All rights reserved.
//

#import "BackView.h"

@implementation BackView


-(void)drawRect:(NSRect)dirtyRect{
    [super drawRect:dirtyRect];
    CGContextRef context= (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetRGBFillColor(context, 0.f/255.f ,0.f/255.f ,0.f/255.f , 1.0);
    CGContextFillRect(context, NSRectToCGRect(dirtyRect));
}


@end
