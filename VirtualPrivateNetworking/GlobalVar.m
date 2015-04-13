//
//  GlobalVar.m
//  FFMPEG
//
//  Created by Felipe Aragon on 31/03/15.
//  Copyright (c) 2015 Felipe Aragon. All rights reserved.
//

#import "GlobalVar.h"

@implementation GlobalVar

+ (GlobalVar *)shareInstance {
    static GlobalVar *__singletion;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __singletion=[[self alloc] init];
    });
    return __singletion;
}

@end
