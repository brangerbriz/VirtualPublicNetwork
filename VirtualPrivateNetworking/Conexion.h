//
//  Conexion.h
//  FFMPEG
//
//  Created by Felipe Aragon on 23/03/15.
//  Copyright (c) 2015 Felipe Aragon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Response.h"

@interface Conexion : NSObject

+ (Conexion *)shareInstance;
+ (NSString *)getSerial;

-(NSMutableArray *)listMac;
-(NSMutableArray *)listMacLive;
-(Response *)joinRoom:(NSString *)idMac nameRoom:(NSString *)nameroom;
-(Response *)waitingstatus:(NSString *)idMac;
-(NSString *)updatestatus:(NSString *)idMac;
-(void)waiting:(NSString *)idMac;
-(void)logout:(NSString *)idMac;

@end
