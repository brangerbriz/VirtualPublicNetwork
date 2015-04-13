//
//  Conexion.m
//  FFMPEG
//
//  Created by Felipe Aragon on 23/03/15.
//  Copyright (c) 2015 Felipe Aragon. All rights reserved.
//

#import "Conexion.h"
#import "Constant.h"
#import "Imac.h"

@implementation Conexion

+ (Conexion *)shareInstance {
    static Conexion *__singletion;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __singletion=[[self alloc]init];
    });
    return __singletion;
}

-(Response *)joinRoom:(NSString *)idMac nameRoom:(NSString *)nameroom{

    NSString *restCallString = [NSString stringWithFormat:@"%@manage/register/%@/%@", kBaseURL,idMac,nameroom];
    NSLog(@"join %@",restCallString);
    NSData *resp = [self makeRestAPICall: restCallString];
    
    NSError *localError = nil;
    NSDictionary *parsedObject=nil;
    if (resp!=nil) {
        parsedObject = [NSJSONSerialization JSONObjectWithData:resp options:0 error:&localError];
    }
    if (localError != nil) {
        return nil;
    }
    
    Response *response=[[Response alloc]init];
    response.status=[parsedObject objectForKey:@"status"];
    response.ip=[parsedObject objectForKey:@"ip_raspberry"];
    return response;

}

-(NSMutableArray *)listMac{
    
    NSString *restCallString = [NSString stringWithFormat:@"%@manage/list", kBaseURL];
    NSData *resp = [self makeRestAPICall: restCallString];
    
    NSError *localError = nil;
    NSDictionary *parsedObject=nil;
    if (resp!=nil) {
        parsedObject = [NSJSONSerialization JSONObjectWithData:resp options:0 error:&localError];
    }
    if (localError != nil) {
        return nil;
    }
    
    NSString *resultload=[parsedObject objectForKey:@"status"];
    NSMutableArray *listmac=[[NSMutableArray alloc] init];
    if ([resultload isEqualToString:@"OK"]) {
        NSArray *list=[parsedObject objectForKey:@"result"];
        Imac *imac;
        for (NSDictionary *dic in list) {
            imac=[[Imac alloc] init];
            [imac setId_user_mac:[[dic objectForKey:@"id"] intValue]];
            [imac setName_mac:[dic objectForKey:@"name"]];
            [imac setStatus:[dic objectForKey:@"status"]];
            [listmac addObject:imac];
        }
        
    }
    
    return listmac;
}

-(NSMutableArray *)listMacLive{
    
    NSString *restCallString = [NSString stringWithFormat:@"%@manage/listlive", kBaseURL];
    NSData *resp = [self makeRestAPICall: restCallString];
    
    NSError *localError = nil;
    NSDictionary *parsedObject=nil;
    if (resp!=nil) {
        parsedObject = [NSJSONSerialization JSONObjectWithData:resp options:0 error:&localError];
    }
    if (localError != nil) {
        return nil;
    }
    
    NSString *resultload=[parsedObject objectForKey:@"status"];
    NSMutableArray *listmac=[[NSMutableArray alloc] init];
    if ([resultload isEqualToString:@"OK"]) {
        NSArray *list=[parsedObject objectForKey:@"result"];
        Imac *imac;
        for (NSDictionary *dic in list) {
            imac=[[Imac alloc] init];
            [imac setId_user_mac:[[dic objectForKey:@"id"] intValue]];
            [imac setName_mac:[dic objectForKey:@"name"]];
            [imac setStatus:[dic objectForKey:@"status"]];
            [listmac addObject:imac];
        }
        
    }
    
    return listmac;
}


-(Response *)waitingstatus:(NSString *)idMac{
    
    NSString *restCallString = [NSString stringWithFormat:@"%@manage/waitingstatus/%@", kBaseURL,idMac];
    NSData *resp = [self makeRestAPICall: restCallString];
    
    NSError *localError = nil;
    NSDictionary *parsedObject=nil;
    if (resp!=nil) {
        parsedObject = [NSJSONSerialization JSONObjectWithData:resp options:0 error:&localError];
    }
    if (localError != nil) {
        return nil;
    }
    
    Response *response=[[Response alloc]init];
    response.status=[parsedObject objectForKey:@"status"];
    response.ip=[parsedObject objectForKey:@"ip_raspberry"];
    return response;
}

-(NSString *)updatestatus:(NSString *)idMac{
    NSString *restCallString = [NSString stringWithFormat:@"%@manage/updatestatus/%@", kBaseURL,idMac];
    NSData *resp =[self makeRestAPICall: restCallString];
    NSError *localError = nil;
    NSDictionary *parsedObject=nil;
    if (resp!=nil) {
        parsedObject = [NSJSONSerialization JSONObjectWithData:resp options:0 error:&localError];
    }
    if (localError != nil) {
        return nil;
    }
    
    return [parsedObject objectForKey:@"status"];
}

-(void)logout:(NSString *)idMac{
    NSString *restCallString = [NSString stringWithFormat:@"%@manage/logout/%@", kBaseURL,idMac];
    [self makeRestAPICall: restCallString];
}

-(void)waiting:(NSString *)idMac{
    NSString *restCallString = [NSString stringWithFormat:@"%@manage/waiting/%@", kBaseURL,idMac];
    [self makeRestAPICall: restCallString];
}


-(NSData*) makeRestAPICall : (NSString*) reqURLStr
{
    NSData *data = [reqURLStr dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    reqURLStr = [[NSString alloc] initWithData:data  encoding:NSASCIIStringEncoding];
    NSString *properlyEscapedURL = [reqURLStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURLRequest *Request = [NSURLRequest requestWithURL:[NSURL URLWithString: properlyEscapedURL]];
    NSURLResponse *resp = nil;
    NSError *error = nil;
    NSData *response = [NSURLConnection sendSynchronousRequest: Request returningResponse: &resp error: &error];
    if (error != nil) {
        return nil;
    }
    return response;
}

+(NSString *)getSerial{
    NSTask *ioregTask   = [[NSTask alloc] init];
    NSTask *awkTask     = [[NSTask alloc] init];
    NSPipe *ioregPipe   = [[NSPipe alloc] init];
    NSPipe *awkPipe     = [[NSPipe alloc] init];
    
    [ioregTask setLaunchPath: @"/usr/sbin/ioreg"];
    [ioregTask setArguments:[NSArray arrayWithObjects:@"-l", nil]];
    [ioregTask setStandardOutput: ioregPipe];
    [ioregTask setStandardError: ioregPipe];
    [ioregTask launch];
    
    [awkTask setStandardOutput:awkPipe];
    [awkTask setStandardInput:ioregPipe];
    [awkTask setLaunchPath:@"/usr/bin/awk"];
    [awkTask setArguments:[NSArray arrayWithObjects:@" /IOPlatformSerialNumber/ { print $4; }", nil]];
    
    NSFileHandle *file = [awkPipe fileHandleForReading];
    [awkTask launch];
    
    NSData   *data      = [file readDataToEndOfFile];
    NSString *serial    = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSArray  *split     = [serial componentsSeparatedByString:@"\""];
    
    serial =[split objectAtIndex:1];
    
    return serial;
}


/*+ (NSString *)serialNumber
{
    io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                                 
                                                                 IOServiceMatching("IOPlatformExpertDevice"));
    CFStringRef serialNumberAsCFString = NULL;
    
    if (platformExpert) {
        serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,
                                                                 CFSTR(kIOPlatformSerialNumberKey),
                                                                 kCFAllocatorDefault, 0);
        IOObjectRelease(platformExpert);
    }
    
    NSString *serialNumberAsNSString = nil;
    if (serialNumberAsCFString) {
        serialNumberAsNSString = [NSString stringWithString:(__bridge NSString *)serialNumberAsCFString];
        CFRelease(serialNumberAsCFString);
    }
    
    return serialNumberAsNSString;
}*/



@end
