//
//  BVPrototype.m
//  FFMPEG
//
//  Created by Felipe Aragon on 25/03/15.
//  Copyright (c) 2015 Felipe Aragon. All rights reserved.
//

#import "BVPrototype.h"
#import "BVView.h"
#import "Imac.h"
#import "Constant.h"
#import "GlobalVar.h"

@interface BVPrototype ()

@end

@implementation BVPrototype

- (void)viewDidLoad {
    //[super viewDidLoad];
    // Do view setup here.
}

- (void)loadView {
    [self setView:[[BVView alloc] initWithFrame:NSZeroRect]];
    
    
}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
   
    if (representedObject!=nil) {
        Imac *mac=(Imac *)representedObject;
        BVView *view =(BVView *)[self view] ;
        if (mac.name_mac!=nil && mac.status!=nil) {
            /*view.txt_name.stringValue=mac.name_mac;
             view.txt_status.stringValue=mac.status;
             if ([mac.status isEqualToString:CONSTWAITING]) {
             [view.txt_status setTextColor:[NSColor redColor]];
             }
             if ([mac.status isEqualToString:CONSTLIVE]) {
             [ view.txt_status setTextColor:[NSColor colorWithCalibratedRed:68.f/255.f green:205.f/255.f blue:69.f/255.f alpha:1.0]];
             }
             */
            //view.imgview.image = [NSImage imageNamed:@"desktop.jpg"];
            view.name_mac=mac.name_mac;
            
            if (![mac.name_mac isEqualToString:@"Default"]) {
                
                NSString *identifierprofile = [NSString stringWithFormat:@"imacimage%d",mac.id_user_mac];
                if([[GlobalVar shareInstance].imageCache objectForKey:identifierprofile] != nil){
                    view.imgview.image = [[GlobalVar shareInstance].imageCache valueForKey:identifierprofile];
                }
                char const * s = [identifierprofile  UTF8String];
                dispatch_queue_t queue = dispatch_queue_create(s, 0);
                dispatch_async(queue, ^{
                    NSString *url =[NSString stringWithFormat:@"%@manage/image/%d.png",kBaseURL,mac.id_user_mac];
                    NSURLRequest *postRequest = [NSURLRequest requestWithURL:[NSURL URLWithString: url]];
                    NSHTTPURLResponse *response = nil;
                    NSError *error = nil;
                    NSData *responseData = [NSURLConnection sendSynchronousRequest:postRequest returningResponse:&response error:&error];
                    if (error==nil) {
                        NSImage *img =[[NSImage alloc] initWithData:responseData];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[GlobalVar shareInstance].imageCache setValue:img forKey:identifierprofile];
                            view.imgview.image =[[GlobalVar shareInstance].imageCache objectForKey:identifierprofile];
                        });
                    }
                });

            }
        }
    }
    
}

@end
