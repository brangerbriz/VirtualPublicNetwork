//
//  GlobalVar.h
//  FFMPEG
//
//  Created by Felipe Aragon on 31/03/15.
//  Copyright (c) 2015 Felipe Aragon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GlobalVar : NSObject

@property(nonatomic,strong) NSMutableDictionary *imageCache;

+ (GlobalVar *)shareInstance;

@end
