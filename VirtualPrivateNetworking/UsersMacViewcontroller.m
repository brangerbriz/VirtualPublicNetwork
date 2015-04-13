//
//  UsersMacViewcontroller.m
//  VirtualPrivateNetworking
//
//  Created by Felipe Aragon on 7/04/15.
//  Copyright (c) 2015 Felipe Aragon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UsersMacViewcontroller.h"
#import "Conexion.h"
#import "Imac.h"
#import "BVPrototype.h"
#import "Constant.h"
#import "GlobalVar.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

#pragma mark Basic Profiling Tools
// Set to 1 to enable basic profiling. Profiling information is logged to console.
#ifndef PROFILE_WINDOW_GRAB
#define PROFILE_WINDOW_GRAB 0
#endif

#if PROFILE_WINDOW_GRAB
#define StopwatchStart() AbsoluteTime start = UpTime()
#define Profile(img) CFRelease(CGDataProviderCopyData(CGImageGetDataProvider(img)))
#define StopwatchEnd(caption) do { Duration time = AbsoluteDeltaToDuration(UpTime(), start); double timef = time < 0 ? time / -1000000.0 : time / 1000.0; NSLog(@"%s Time Taken: %f seconds", caption, timef); } while(0)
#else
#define StopwatchStart()
#define Profile(img)
#define StopwatchEnd(caption)
#endif


@interface UsersMacViewcontroller ()<AVCaptureVideoDataOutputSampleBufferDelegate,NSTableViewDataSource,NSTableViewDelegate,NSCollectionViewDelegate>{
    AVCaptureSession *captureSession;
    AVCaptureScreenInput *captureScreenInput;
    CGDirectDisplayID           selectedDisplayId;
    
    QuickVideoOutput *qvo;
    AVFrame *raw_picture;
    AVFrame *tmp_picture;
    
    enum PixelFormat src_pix_fmt;
    
    // is or not first frame
    BOOL _firstFrame;
    // fps value
    int _producerFps;
    
    struct SwsContext *img_convert_ctx;
    double video_pts;
    
    //timer finish streaming
    NSTimer *_timerStreaming;
    //timer waiting
    NSTimer *_timerWaiting;
    //timer refresh status
    NSTimer *_timerStatus;
    //timer refresh list
    NSTimer *_timerList;
    //timer upload
    NSTimer *_timerUpload;
    //live btn
    NSTimer *_timerLiveinit;
    //live time
    NSTimer *_timerLiveNow;
    //Bool active table
    BOOL active_table;
    //total time
    int total_time;
    //finish live
    BOOL finish;
}

@end

@implementation UsersMacViewcontroller

//collection
NSCollectionView *cv ;


-(void)awakeFromNib{

    if (!_init) {
        //init view
        _list_mac = [[NSMutableArray alloc] init];
        _list_mac_collection = [[NSMutableArray alloc] init];
        _content_table.hidden=YES;
        _view_content_collection.hidden=YES;
        _image_view_back.hidden=YES;
        total_time=TOTAL_TIME;
        
        NSColor *color = [NSColor colorWithCalibratedRed:158.f/255.f green:27.f/255.f blue:102.f/255.f alpha:1.0];
        NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[_btn_list attributedTitle]];
        NSRange titleRange = NSMakeRange(0, [colorTitle length]);
        [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
        [_btn_list setAttributedTitle:colorTitle];
        [[_btn_list cell] setBackgroundColor:((__bridge CGColorRef)([NSColor blackColor]))];
        [_btn_list setBordered:NO];
        
        
        color = [NSColor whiteColor];
        colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[_btn_collection attributedTitle]];
        titleRange = NSMakeRange(0, [colorTitle length]);
        [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
        [_btn_collection setAttributedTitle:colorTitle];
        [[_btn_collection cell] setBackgroundColor:((__bridge CGColorRef)([NSColor blackColor]))];
        [_btn_collection setBordered:NO];
        
        //[self setPreferredContentSize:NSMakeSize(480,300)];
        
        //init table load
        active_table=YES;
        [self tableload];
        
        //init cache image
        [GlobalVar shareInstance].imageCache=[[NSMutableDictionary alloc] init];
        
        //init capture
        [self initcapture];
        
        
        //status init
        if ([_response.status isEqualToString:CONSTWAITING]) {
            _text_live.stringValue=@"[ waiting in line ]";
            //add timer waiting
            _timerWaiting= [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(_timerFinihWaiting:) userInfo:nil repeats:YES];
            
        }
        
        if ([_response.status isEqualToString:CONSTLIVE]) {
            //add timers
            _timerStreaming = [NSTimer scheduledTimerWithTimeInterval:TOTAL_TIME target:self selector:@selector(_timerFinishStreming:) userInfo:nil repeats:YES];
            _timerLiveNow = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(_timerNow:) userInfo:nil repeats:YES];
            
        }
        
        //init timers
        _timerStatus = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(_timerFinisStatus:) userInfo:nil repeats:YES];
        _timerList = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(_timerFinisList:) userInfo:nil repeats:YES];
        _timerUpload = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(_timerFinisUpload:) userInfo:nil repeats:YES];
        _timerLiveinit = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(_timerFinisLiveinit:) userInfo:nil repeats:YES];
        
        [self uploadImage];
        _init=true;
    }
    
}



- (void)_timerNow:(NSTimer *)timer {
    
    total_time=total_time-1;
    if (total_time>=0) {
        _text_live.stringValue=[self formattedStringForDuration:total_time];
    }
}

- (NSString*)formattedStringForDuration:(int)duration
{
    NSInteger minutes = floor(duration/60);
    NSInteger seconds = round(duration - minutes * 60);
    return [NSString stringWithFormat:@"[ TO 00:%02ld:%02ld ]", (long)minutes, (long)seconds];
}

- (void)stopFinishNow{
    if ([_timerLiveNow isValid]) {
        [_timerLiveNow invalidate];
    }
    _timerLiveNow = nil;
}


- (void)_timerFinisLiveinit:(NSTimer *)timer {
    [self startCapture];
    [self stopFinishinit];
    
}

- (void)stopFinishinit{
    if ([_timerLiveinit isValid]) {
        [_timerLiveinit invalidate];
    }
    _timerLiveinit = nil;
}



- (void)_timerFinisUpload:(NSTimer *)timer {
    [self uploadImage];
}

- (void)stopFinishUpload{
    if ([_timerUpload isValid]) {
        [_timerUpload invalidate];
    }
    _timerUpload = nil;
}



- (void)_timerFinisList:(NSTimer *)timer {
    if (active_table) {
        [self tableload];
    }else {
        [self reloaddataCollection];
    }
}

- (void)stopFinishList{
    if ([_timerList isValid]) {
        [_timerList invalidate];
    }
    _timerList = nil;
}


- (void)_timerFinisStatus:(NSTimer *)timer {
    dispatch_async(kBgQueue, ^{
        NSString *status=[[Conexion shareInstance] updatestatus:[Conexion getSerial]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([status isEqualToString:CONSTOFF] && !finish) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    finish=true;
                    [self stopFinishNow];
                    [self stopFinishStreming];
                    [self stopFinishList];
                    [self stopFinishStatus];
                    [self stopFinishWaiting];
                    //[self stopFinishLiveBtn];
                    [self stopFinishUpload];
                    [captureSession stopRunning];
                    close_quick_video_ouput(qvo);
                    //[self dismissViewController:self];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"LogoutNotification" object:nil];
                    
                });
            }
        });
    });
}

- (void)stopFinishStatus{
    if ([_timerStatus isValid]) {
        [_timerStatus invalidate];
    }
    _timerStatus = nil;
}


- (void)_timerFinihWaiting:(NSTimer *)timer {
    
    dispatch_async(kBgQueue, ^{
        Response *response=[[Conexion shareInstance] waitingstatus:[Conexion getSerial]];
        dispatch_async(dispatch_get_main_queue(), ^{
            _response=response;
            if ([_response.status isEqualToString:CONSTWAITING]) {
                _text_live.stringValue=@"[ waiting in line ]";
            }
            
            if ([_response.status isEqualToString:CONSTLIVE]) {
                [self startCapture];
                _text_live.stringValue=@"";
                //add timers
                _timerStreaming = [NSTimer scheduledTimerWithTimeInterval:TOTAL_TIME target:self selector:@selector(_timerFinishStreming:) userInfo:nil repeats:YES];
                _timerLiveNow = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(_timerNow:) userInfo:nil repeats:YES];
                [self stopFinishWaiting];
            }
            
        });
    });
}

- (void)stopFinishWaiting{
    if ([_timerWaiting isValid]) {
        [_timerWaiting invalidate];
    }
    _timerWaiting = nil;
}



- (void)_timerFinishStreming:(NSTimer *)timer {
    dispatch_async(kBgQueue, ^{
        [[Conexion shareInstance] logout:[Conexion getSerial]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!finish) {
                finish=true;
                [self stopFinishNow];
                [self stopFinishStreming];
                [self stopFinishList];
                [self stopFinishStatus];
                [self stopFinishWaiting];
                //[self stopFinishLiveBtn];
                [self stopFinishUpload];
                [captureSession stopRunning];
                close_quick_video_ouput(qvo);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"LogoutNotification" object:nil];
            }
        });
    });
}

- (void)stopFinishStreming{
    if ([_timerStreaming isValid]) {
        [_timerStreaming invalidate];
    }
    _timerStreaming = nil;
}


-(void)tableload{
    if (active_table) {
        dispatch_async(kBgQueue, ^{
            
            _list_mac=[[Conexion shareInstance] listMac ];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                _content_table.hidden=NO;
                [_tebleview reloadData];
                
            });
        });
    }
}

-(void)collectionLoad{
    dispatch_async(kBgQueue, ^{
        
        _list_mac_collection=[[Conexion shareInstance] listMacLive ];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            cv = [[NSCollectionView alloc]
                  initWithFrame:(NSRect){{0,0}  , {480,274}}];
            [cv setItemPrototype:[BVPrototype new]];
            [cv setContent:[NSArray arrayWithArray:_list_mac_collection]];
            cv.minItemSize =NSMakeSize(160, 90);
            [cv setAutoresizingMask:(NSViewMinXMargin
                                     | NSViewWidthSizable
                                     | NSViewMaxXMargin
                                     | NSViewMinYMargin
                                     | NSViewHeightSizable
                                     | NSViewMaxYMargin)];
            [cv setBackgroundColors:[NSArray arrayWithObjects:[NSColor clearColor], nil]];
            
            [_view_content_collection addSubview:cv];
            //[cv setNeedsDisplay:YES];
            
        });
    });
}

-(void)reloaddataCollection{
    if (!active_table) {
        dispatch_async(kBgQueue, ^{
            
            _list_mac_collection=[[Conexion shareInstance] listMacLive ];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [cv setContent:[NSArray arrayWithArray:_list_mac_collection]];
            });
        });
    }
}


#pragma streaming Video

-(void)initcapture{
    
    
    _producerFps = STREAM_FRAME_RATE;
    
    // Do any additional setup after loading the view.
    /****** This code snippet is used to set up the capture callbacks********************** */
    /* Create a capture session. */
    captureSession = [[AVCaptureSession alloc] init];
    if ([captureSession canSetSessionPreset:AVCaptureSessionPresetHigh])
    {
        /* Specifies capture settings suitable for high quality video and audio output. */
        [captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    }
    
    //selectedDisplayId = CGMainDisplayID();
    /*Add display as a capture input. */
    // selectedDisplayId is defined prior to calling this code snippet */
    captureScreenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:selectedDisplayId];
    if ([captureSession canAddInput:captureScreenInput])
    {
        [captureSession addInput:captureScreenInput];
    }
    else
    {
        NSLog(@"Could not add main display to capture input\n");
    }
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setAlwaysDiscardsLateVideoFrames:YES];
    output.videoSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    _firstFrame=YES;
    
    /*We create a serial queue to handle the processing of our frames*/
    dispatch_queue_t queue = dispatch_queue_create("elegantcloud", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    [captureSession addOutput:output];
    
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in output.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }
    if (videoConnection) {
        videoConnection.videoMinFrameDuration = CMTimeMake(1, _producerFps);
        // videoConnection.videoMaxFrameDuration = videoConnection.videoMinFrameDuration;
        if (videoConnection.isVideoOrientationSupported) {
            videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
    }
    
}

-(void )startCapture{
    /* Start the capture session. */
    printf("*** Start capture session ***\n");
    
    // initialize QuickVideoOutput
    qvo = (QuickVideoOutput*)malloc(sizeof(QuickVideoOutput));
    
    NSScreen *screen = [NSScreen mainScreen];
    qvo->width = /*192*/1280;
    qvo->height = /*144*/720;
    if (screen.frame.size.width==1366 && screen.frame.size.height==768 ) {
        qvo->width = 1152;
        qvo->height =720;
    }
    
    NSString *ip_rtmp=_response.ip;
    int ret = init_quick_video_output(qvo, [ip_rtmp cString], "flv");
    if (ret < 0) {
        NSLog(@"quick video ouput initial failed");
        free(qvo);
        qvo = NULL;
        return;
    }
    enum PixelFormat dst_pix_fmt = qvo->video_stream->codec->pix_fmt;
    src_pix_fmt = PIX_FMT_RGB32;
    
    raw_picture = alloc_picture(dst_pix_fmt, qvo->width, qvo->height);
    tmp_picture = avcodec_alloc_frame();
    raw_picture->pts = 0;
    
    video_pts = 0;
    
    [captureSession startRunning];
    
    /****** ********* This code snippet is used to set up the capture callbacks **********************/
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    // pass frame to encoder
    //[_encoder encodeFrame:sampleBuffer];
    
    NSLog(@"capture output..");
    // 捕捉数据输出 要怎么处理随你便
    CVPixelBufferRef _pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    /*Lock the buffer*/
    if(CVPixelBufferLockBaseAddress(_pixelBuffer, 0) == kCVReturnSuccess){
        //UInt8 *_bufferPtr = (UInt8 *)CVPixelBufferGetBaseAddress(_pixelBuffer);
        //size_t _buffeSize = CVPixelBufferGetDataSize(_pixelBuffer);
        
        if(_firstFrame){
            if(1){
                // 第一次数据要求：宽高，类型
                //int _width = CVPixelBufferGetWidth(_pixelBuffer);
                //int _height = CVPixelBufferGetHeight(_pixelBuffer);
                
                int _pixelFormat = CVPixelBufferGetPixelFormatType(_pixelBuffer);
                
                switch (_pixelFormat) {
                    case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
                        //TMEDIA_PRODUCER(producer)->video.chroma = tmedia_nv12; // iPhone 3GS or 4
                        NSLog(@"Capture pixel format=NV12");
                        break;
                    case kCVPixelFormatType_422YpCbCr8:
                        //TMEDIA_PRODUCER(producer)->video.chroma = tmedia_uyvy422; // iPhone 3
                        NSLog(@"Capture pixel format=UYUY422");
                        break;
                    case kCVPixelFormatType_32BGRA:
                        NSLog(@"Capture pixel format=RGB32");
                        break;
                    default:
                        //TMEDIA_PRODUCER(producer)->video.chroma = tmedia_rgb32;
                        NSLog(@"Capture pixel format=RGB32");
                        break;
                }
                
                _firstFrame = NO;
            }
        }
        /*We unlock the buffer*/
        CVPixelBufferUnlockBaseAddress(_pixelBuffer, 0);
    }
    
    /*We create an autorelease pool because as we are not in the main_queue our code is
     not executed in the main thread. So we have to create an autorelease pool for the thread we are in*/
    @autoreleasepool {
        // Code, such as a loop that creates a large number of temporary objects.
        CVImageBufferRef _imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        /*Lock the image buffer*/
        CVPixelBufferLockBaseAddress(_imageBuffer,0);
        /*Get information about the image*/
        uint8_t *_baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(_imageBuffer);
        //size_t _bytesPerRow = CVPixelBufferGetBytesPerRow(_imageBuffer);
        size_t _width = CVPixelBufferGetWidth(_imageBuffer);
        size_t _height = CVPixelBufferGetHeight(_imageBuffer);
        
        //  NSLog(@"raw image width: %zul heigth: %zul ", _width, _height);
        
        
        
        /*Create a CGImageRef from the CVImageBufferRef*/
        
        CGColorSpaceRef _colorSpace = CGColorSpaceCreateDeviceRGB();
        if (_colorSpace == nil) {
            NSLog(@"CGColorSpaceCreateDeviceRGB failure");
            
            return ;
        }
        
        // get image
        /*CGContextRef _newContext = CGBitmapContextCreate(_baseAddress, _width, _height, 8, _bytesPerRow, _colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
         CGImageRef _newImage = CGBitmapContextCreateImage(_newContext);
         
         CGContextRelease(_newContext);
         */
        // another to get image
        /*
         size_t _bufferSize = CVPixelBufferGetDataSize(_imageBuffer);
         
         // Create a Quartz direct-access data provider that uses data we supply
         CGDataProviderRef _provider = CGDataProviderCreateWithData(NULL, _baseAddress, _bufferSize, NULL);
         // Create a bitmap image from data supplied by our data provider
         CGImageRef cgImage = CGImageCreate(_width, _height, 8, 32, _bytesPerRow, _colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little, _provider, NULL, true, kCGRenderingIntentDefault);
         CGDataProviderRelease(_provider);
         */
        
        /*We release some components*/
        CGColorSpaceRelease(_colorSpace);
        
        /* We display the result on the custom layer. All the display stuff must be done in the
         * main thread because UIKit is no thread safe, and as we are not in the main thread
         * (remember we didn't use the main_queue) we use performSelectorOnMainThread to call our
         * CALayer and tell it to display the CGImage.
         */
        // [_customLayer performSelectorOnMainThread:@selector(setContents:) withObject:(__bridge id)_newImage waitUntilDone:YES];
        
        /* We display the result on the image view (We need to change the orientation of the image
         * so that the video is displayed correctly). Same thing as for the CALayer we are not in
         * the main thread so ...
         */
        /*CIImage *_image= [CIImage imageWithCGImage:_newImage ];
         
         CGImageRelease(_newImage);
         
         [_mLocalVideoView performSelectorOnMainThread:@selector(setImage:) withObject:_image waitUntilDone:YES];*/
        
        
        /*We unlock the  image buffer*/
        CVPixelBufferUnlockBaseAddress(_imageBuffer,0);
        
        [self process_raw_frame:_baseAddress andWidth:_width andHeight:_height];
        
    }
    
    
}

-(void) process_raw_frame: (uint8_t *)buffer_base_address andWidth: (int)width andHeight: (int)height{
    NSLog(@"origin image width: %d height: %d", width, height);
    
    if (!qvo) {
        return;
    }
    
    
    AVCodecContext *c = qvo->video_stream->codec;
    
    avpicture_fill((AVPicture *)tmp_picture, buffer_base_address, src_pix_fmt, width, height);
    NSLog(@"raw picture to encode width: %d height: %d", c->width, c->height);
    
    img_convert_ctx = sws_getCachedContext(img_convert_ctx, width, height, src_pix_fmt, qvo->width, qvo->height, c->pix_fmt, SWS_BILINEAR, NULL, NULL, NULL);
    
    // convert RGB32 to YUV420
    sws_scale(img_convert_ctx, tmp_picture->data, tmp_picture->linesize, 0, height, raw_picture->data, raw_picture->linesize);
    
    int out_size = write_video_frame(qvo, raw_picture);
    
    // NSLog(@"stream pts val: %lld time base: %d / %d",qvo->video_stream->pts.val, qvo->video_stream->time_base.num, qvo->video_stream->time_base.den);
    video_pts = (double)qvo->video_stream->pts.val * qvo->video_stream->time_base.num / qvo->video_stream->time_base.den;
    NSLog(@"write video frame - size: %d video pts: %f", out_size, video_pts);
    
    raw_picture->pts++;
    
}

#pragma Tableview

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return [_list_mac count];
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    
    
    NSString *identifiquer=[tableColumn identifier];
    NSTableCellView *result;
    if ([identifiquer isEqualToString:@"name_mac"]) {
        result = [tableView makeViewWithIdentifier:@"name_cell" owner:self];
    }
    
    if (_list_mac.count>0) {
        Imac *imac=[_list_mac objectAtIndex:row];
        result.textField.stringValue = [imac valueForKey:identifiquer];
        result.textField.alignment=NSCenterTextAlignment;
        if ([[imac valueForKey:@"status"] isEqualToString:CONSTLIVE]) {
            result.textField.textColor=[NSColor colorWithCalibratedRed:158.f/255.f green:27.f/255.f blue:102.f/255.f alpha:1.0];
        }else{
            result.textField.textColor=[NSColor whiteColor];
        }
    }
    
    /* if ([identifiquer isEqualToString:@"status"]) {
     result = [tableView makeViewWithIdentifier:@"status_cell" owner:self];
     if ([[imac valueForKey:identifiquer] isEqualToString:CONSTWAITING]) {
     [result.textField setTextColor:[NSColor redColor]];
     }
     if ([[imac valueForKey:identifiquer] isEqualToString:CONSTLIVE]) {
     [result.textField setTextColor:[NSColor colorWithCalibratedRed:68.f/255.f green:205.f/255.f blue:69.f/255.f alpha:1.0]];
     }
     
     }*/
    
    // Return the result
    return result;
}

- (IBAction)print_list:(id)sender {
    active_table=YES;
    _content_table.hidden=NO;
    _image_view.hidden=NO;
    _view_content_collection.hidden=YES;
    _image_view_back.hidden=YES;
    [cv removeFromSuperview];
    [self tableload];
    
    NSColor *color = [NSColor colorWithCalibratedRed:158.f/255.f green:27.f/255.f blue:102.f/255.f alpha:1.0];
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[_btn_list attributedTitle]];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
    [_btn_list setAttributedTitle:colorTitle];
    [[_btn_list cell] setBackgroundColor:((__bridge CGColorRef)([NSColor blackColor]))];
    [_btn_list setBordered:NO];
    
    
    color = [NSColor whiteColor];
    colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[_btn_collection attributedTitle]];
    titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
    [_btn_collection setAttributedTitle:colorTitle];
    [[_btn_collection cell] setBackgroundColor:((__bridge CGColorRef)([NSColor blackColor]))];
    [_btn_collection setBordered:NO];
    
}

- (IBAction)print_collection:(id)sender {
    active_table=NO;
    _content_table.hidden=YES;
     _image_view.hidden=YES;
    _view_content_collection.hidden=NO;
    _image_view_back.hidden=NO;
    [self collectionLoad];
    
    NSColor *color = [NSColor whiteColor];
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[_btn_list attributedTitle]];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
    [_btn_list setAttributedTitle:colorTitle];
    [[_btn_list cell] setBackgroundColor:((__bridge CGColorRef)([NSColor blackColor]))];
    [_btn_list setBordered:NO];
    
    
    color = [NSColor colorWithCalibratedRed:158.f/255.f green:27.f/255.f blue:102.f/255.f alpha:1.0];
    colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[_btn_collection attributedTitle]];
    titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
    [_btn_collection setAttributedTitle:colorTitle];
    [[_btn_collection cell] setBackgroundColor:((__bridge CGColorRef)([NSColor blackColor]))];
    [_btn_collection setBordered:NO];

}

-(void)logout{
    dispatch_async(kBgQueue, ^{
        [[Conexion shareInstance] logout:[Conexion getSerial]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!finish) {
                finish=true;
                [self stopFinishNow];
                [self stopFinishStreming];
                [self stopFinishList];
                [self stopFinishStatus];
                [self stopFinishWaiting];
                [self stopFinishUpload];
                [captureSession stopRunning];
                close_quick_video_ouput(qvo);
            }
            
            
        });
    });
}

-(void)uploadImage
{
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:[self createScreenShot]];
    // Create an NSImage and add the bitmap rep to it...
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation:bitmapRep];
    bitmapRep = nil;
    
    // COnvert Image to NSData
    NSData *dataImage = [self PNGRepresentationOfImage:[self imageResize:image newSize:NSMakeSize(140, 70)]];
    dispatch_async(kBgQueue, ^{
        // set your URL Where to Upload Image
        NSString *urlString = [NSString stringWithFormat:@"%@/manage/upload",kBaseURL];
        
        // set your Image Name
        NSString *filename =[NSString stringWithFormat:@"%@.png",[Conexion getSerial]];
        
        // Create 'POST' MutableRequest with Data and Other Image Attachment.
        NSMutableURLRequest* request= [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:urlString]];
        [request setHTTPMethod:@"POST"];
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
        NSMutableData *postbody = [NSMutableData data];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[[NSString stringWithFormat:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[NSData dataWithData:dataImage]];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPBody:postbody];
        
        // Get Response of Your Request
        // NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        // NSString *responseString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
        //NSLog(@"Response  %@",responseString);
        [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    });
}

- (NSData *) PNGRepresentationOfImage:(NSImage *) image {
    // Create a bitmap representation from the current image
    
    [image lockFocus];
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, image.size.width, image.size.height)];
    [image unlockFocus];
    
    return [bitmapRep representationUsingType:NSPNGFileType properties:Nil];
}


-(CGImageRef)createScreenShot
{
    // This just invokes the API as you would if you wanted to grab a screen shot. The equivalent using the UI would be to
    // enable all windows, turn off "Fit Image Tightly", and then select all windows in the list.
    StopwatchStart();
    CGImageRef screenShot = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault);
    Profile(screenShot);
    StopwatchEnd("Screenshot");
    
    return screenShot;
}

- (NSImage *)imageResize:(NSImage*)anImage newSize:(NSSize)newSize {
    NSImage *sourceImage = anImage;
    [sourceImage setScalesWhenResized:YES];
    
    // Report an error if the source isn't a valid image
    if (![sourceImage isValid]){
        NSLog(@"Invalid Image");
    } else {
        NSImage *smallImage = [[NSImage alloc] initWithSize: newSize];
        [smallImage lockFocus];
        [sourceImage setSize: newSize];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, newSize.width, newSize.height) operation:NSCompositeCopy fraction:1.0];
        [smallImage unlockFocus];
        return smallImage;
    }
    return nil;

}
@end
