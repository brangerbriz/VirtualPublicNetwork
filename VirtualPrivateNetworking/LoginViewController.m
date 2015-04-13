//
//  LoginViewController.m
//  VirtualPrivateNetworking
//
//  Created by Felipe Aragon on 7/04/15.
//  Copyright (c) 2015 Felipe Aragon. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <IOKit/IOKitLib.h>
#import "LoginViewController.h"
#import "Response.h"
#import "Conexion.h"
#import "AppDelegate.h"


#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@interface LoginViewController ()

@end

@implementation LoginViewController


-(void)awakeFromNib{
    _indicator.hidden=YES;
    
    NSColor *color = [NSColor whiteColor];
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[_btn_join_room attributedTitle]];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
    [_btn_join_room setAttributedTitle:colorTitle];
    [[_btn_join_room cell] setBackgroundColor:((__bridge CGColorRef)([NSColor blackColor]))];
    [_btn_join_room setBordered:NO];
    
    
    
    CIFilter *lighten = [CIFilter filterWithName:@"CIColorControls"];
    [lighten setDefaults];
    [lighten setValue:@1 forKey:@"inputBrightness"];
    [_indicator setContentFilters:[NSArray arrayWithObjects:lighten, nil]];
    
    
    [[self.view window] makeFirstResponder:_textview_handler];
    
}


- (IBAction)goRoom:(id)sender {
    [_btn_join_room setEnabled: NO];
    if (![[_textview_handler stringValue] isEqualToString:@""]) {
        _indicator.hidden=NO;
        
        
        dispatch_async(kBgQueue, ^{
            
            Response *response=[[Conexion shareInstance] joinRoom:[Conexion getSerial] nameRoom:[_textview_handler stringValue]];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (response) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginNotification" object:response];
                    [_btn_join_room setEnabled: YES];
                }else {
                    _indicator.hidden=YES;
                    [self showSimpleInformationalAlert:@"Conection Failed !"];
                    [_btn_join_room setEnabled: YES];
                }
            });
        });
    }else{
        [self showSimpleInformationalAlert:@"Please make sure that the field handler is filled."];
        [_btn_join_room setEnabled: YES];
    }
}

-(void)showSimpleInformationalAlert:(NSString *)msg
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:@"Error Joining Room"];
    [alert setInformativeText:msg];
    [alert setAlertStyle:NSInformationalAlertStyle];
    // ALT 1: Trying to attach it to appdel>window
    [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];

}

- (void) alertDidEnd:(NSAlert *) alert returnCode:(int) returnCode contextInfo:(int *) contextInfo
{
    NSLog(@"alert close");
}


@end
