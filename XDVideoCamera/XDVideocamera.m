//
//  XDVideocamera.m
//  摄像
//
//  Created by 谢兴达 on 2017/3/1.
//  Copyright © 2017年 谢兴达. All rights reserved.
//

#import "XDVideocamera.h"
#import "VideoUI.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "XDVideoManager.h"
#import "StoreFileManager.h"

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface XDVideocamera ()<VideoUIDelegate,AVCaptureFileOutputRecordingDelegate>
@property (strong,nonatomic) AVCaptureSession *session;                     //会话管理
@property (strong,nonatomic) AVCaptureDeviceInput *deviceInput;             //负责从AVCaptureDevice获得输入数据
@property (strong,nonatomic) AVCaptureMovieFileOutput *movieFileOutput;     //视频输出流
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer; //相机拍摄预览图层

@property (nonatomic, strong) NSMutableArray *videoArray;

@property (strong,nonatomic) CALayer *previewLayer; //视频预览layer层
@property (strong,nonatomic) UIView *focusView;     //聚焦
@property (assign,nonatomic) BOOL enableRotation;   //是否允许旋转（注意在视频录制过程中禁止屏幕旋转）
@property (assign,nonatomic) CGRect *lastBounds;    //旋转的前大小
@property (assign,nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;//后台任务标识

@end

@implementation XDVideocamera

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.session startRunning];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.session stopRunning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _videoArray = [[NSMutableArray alloc]init];
    [self creatMainUI];
}

//UI
- (void)creatMainUI {
    VideoUI *uiView = [[VideoUI alloc]initWithFrame:self.view.frame];
    [uiView viewsLinkBlock:^(UIView *focusView, SelectView *previewView) {
        _previewLayer = previewView.layer;
        _previewLayer.masksToBounds = YES;
        _focusView = focusView;
    }];
    uiView.delegate = self;
    self.view = uiView;
    
    [self configSessionManager];
}

-(BOOL)shouldAutorotate{
    return self.enableRotation;
}

//屏幕旋转时调整预览图层
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    AVCaptureConnection *connection = [self.videoPreviewLayer connection];
    connection.videoOrientation = (AVCaptureVideoOrientation)toInterfaceOrientation;
}

//旋转后重新设置大小
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    _videoPreviewLayer.frame = self.previewLayer.bounds;
}

#pragma mark -- 会话管理初始化
- (void)configSessionManager {
    //初始化会话
    _session = [[AVCaptureSession alloc]init];
    [self changeConfigurationWithSession:_session block:^(AVCaptureSession *session) {
        if ([session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            [session setSessionPreset:AVCaptureSessionPresetHigh];
        }
        
        //获取输入设备
        AVCaptureDevice *device = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
        if (!device) {
            NSLog(@"获取后置摄像头失败");
            return;
        }
        
        //添加一个音频输入设备
        AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio]firstObject];
        if (!audioDevice) {
            NSLog(@"获取麦克风失败");
        }
        
        //用当前设备初始化输入数据
        NSError *error = nil;
        _deviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:device error:&error];
    
        if (error) {
            NSLog(@"获取视频输入对象失败 原因:%@",error.localizedDescription);
            return;
        }
        
        //用当前音频设备初始化音频输入
        AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:audioDevice error:&error];
        if (error) {
            NSLog(@"获取音频输入对象失败 原因:%@",error.localizedDescription);
        }
        
        //初始化设备输出对象
        _movieFileOutput = [[AVCaptureMovieFileOutput alloc]init];
        
        //将设备的输入输出添加到会话管理
        if ([session canAddInput:_deviceInput]) {
            [session addInput:_deviceInput];
            [session addInput:audioInput];
        }
        
        if ([session canAddOutput:_movieFileOutput]) {
            [session addOutput:_movieFileOutput];
        }
        
        //创建视频预览层，用于实时展示摄像头状态
        _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:session];
        
        _videoPreviewLayer.frame = _previewLayer.bounds;
        _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        [_previewLayer insertSublayer:_videoPreviewLayer below:_focusView.layer];
        
        _enableRotation = YES;
        [self addNotificationToDevice:device];
    }];
}

#pragma mark - 通知
/**
 给输入设备添加通知
 */
-(void)addNotificationToDevice:(AVCaptureDevice *)captureDevice{
    //注意添加区域改变捕获通知必须首先设置设备允许捕获
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        captureDevice.subjectAreaChangeMonitoringEnabled=YES;
    }];
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    //捕获区域发生改变
    [notificationCenter addObserver:self selector:@selector(areaChanged:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
    //链接成功
    [notificationCenter addObserver:self selector:@selector(deviceConnected:) name:AVCaptureDeviceWasConnectedNotification object:captureDevice];
    //链接断开
    [notificationCenter addObserver:self selector:@selector(deviceDisconnected:) name:AVCaptureDeviceWasDisconnectedNotification object:captureDevice];
}


-(void)removeNotificationFromDevice:(AVCaptureDevice *)captureDevice{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
    [notificationCenter removeObserver:self name:AVCaptureDeviceWasConnectedNotification object:captureDevice];
    [notificationCenter removeObserver:self name:AVCaptureDeviceWasDisconnectedNotification object:captureDevice];
}

/**
 移除所有通知
 */
-(void)removeNotification{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
}

-(void)addNotificationToCaptureSession:(AVCaptureSession *)captureSession{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    //会话出错
    [notificationCenter addObserver:self selector:@selector(sessionError:) name:AVCaptureSessionRuntimeErrorNotification object:captureSession];
}

/**
 设备连接成功
 
 @param notification 通知对象
 */
-(void)deviceConnected:(NSNotification *)notification{
    NSLog(@"设备已连接...");
}

/**
 设备连接断开
 
 @param notification 通知对象
 */
-(void)deviceDisconnected:(NSNotification *)notification{
    NSLog(@"设备已断开.");
}

/**
 捕获区域改变
 
 @param notification 通知对象
 */
-(void)areaChanged:(NSNotification *)notification{
    NSLog(@"区域改变...");
    CGPoint cameraPoint = [self.videoPreviewLayer captureDevicePointOfInterestForPoint:self.view.center];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

/**
 会话出错
 
 @param notification 通知对象
 */
-(void)sessionError:(NSNotification *)notification{
    NSLog(@"会话错误.");
}

#pragma mark -- 工具方法
/**
 取得指定位置的摄像头
 
 @param position 摄像头位置

 @return 摄像头设备
 */
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}

/**
 改变设备属性的统一操作方法
 
 @param propertyChange 属性改变操作
 */
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice= [self.deviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        if (propertyChange) {
           propertyChange(captureDevice);
        }
        [captureDevice unlockForConfiguration];
        
    }else{
        NSLog(@"出错了，错误信息：%@",error.localizedDescription);
    }
}

/**
 改变会话同意操作方法

 @param currentSession self.session
 @param block Session操作区域
 */
- (void)changeConfigurationWithSession:(AVCaptureSession *)currentSession block:(void (^)(AVCaptureSession *session))block {
    [currentSession beginConfiguration];
    if (block) {
        block(currentSession);
    }
    [currentSession commitConfiguration];
}

/**
 获取时间

 @return 返回日期，用日期命名
 */
- (NSString *)getCurrentDate {
    //用日期做为视频文件名称
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    return dateStr;
}

/**
 提示框

 @param title 提示内容
 @param btn 取消按钮
 @return 提示框
 */
- (UIAlertView *)noticeAlertTitle:(NSString *)title cancel:(NSString *)btn {
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:title message:nil delegate:self cancelButtonTitle:btn otherButtonTitles:nil, nil];
    [alert show];
    return alert;
}

/**
 清除视频Url路径下的缓存

 @param urlArray _videoArray
 */
- (void)freeArrayAndItemsInUrlArray:(NSArray *)urlArray {
    if (urlArray.count <= 0) {
        return;
    }
    for (NSURL *url in urlArray) {
        [[StoreFileManager defaultManager] removeItemAtUrl:url];
    }
}

#pragma mark -- 按钮点击方法
//取消按钮
- (void)cancelClick {
    [self dismissViewControllerAnimated:YES completion:^{
        [self freeArrayAndItemsInUrlArray:_videoArray];
        [_videoArray removeAllObjects];
    }];
}


/**
 切换摄像头

 @return 返回bool值用于改变按钮状态
 */
- (BOOL)changeBtClick {
    bool isBackground;
    //获取当前设备
    AVCaptureDevice *currentDevice = [self.deviceInput device];
    AVCaptureDevicePosition currentPosition = [currentDevice position];
    [self removeNotificationFromDevice:currentDevice];
    AVCaptureDevice *toDevice;
    AVCaptureDevicePosition toPosition;
    if (currentPosition == AVCaptureDevicePositionUnspecified || currentPosition == AVCaptureDevicePositionFront) {
        toPosition = AVCaptureDevicePositionBack;
        isBackground = YES;
    } else {
        toPosition = AVCaptureDevicePositionFront;
        isBackground = NO;
    }
    
    toDevice = [self getCameraDeviceWithPosition:toPosition];
    [self addNotificationToDevice:toDevice];
    
    //获得要调整的设备输入对象
    NSError *error = nil;
    AVCaptureDeviceInput *toDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:toDevice error:&error];
    if (error) {
        NSLog(@"获取设备失败");
    }
    
    [self changeConfigurationWithSession:_session block:^(AVCaptureSession *session) {
        //移除原有输入对象
        [session removeInput:self.deviceInput];
        self.deviceInput = nil;
        //添加新输入对象
        if ([session canAddInput:toDeviceInput]) {
            [session addInput:toDeviceInput];
            self.deviceInput = toDeviceInput;
        }
    }];
    
    return isBackground;
}


/**
 录制

 @return 返回bool值用于改变按钮状态
 */
- (BOOL)videoBtClick {
    //根据设备输出获得链接
    AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    //根据链接取出设备输出的数据
    if (![self.movieFileOutput isRecording]) {
        self.enableRotation = NO;
        
        //如果支持多任务则开启多任务
        if ([[UIDevice currentDevice] isMultitaskingSupported]) {
            self.backgroundTaskIdentifier=[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        }
        
        //预览图层和视频方向保持一致
        connection.videoOrientation = [self.videoPreviewLayer connection].videoOrientation;
        
        //视频防抖模式
        if ([connection isVideoStabilizationSupported]) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        
        //用日期做为视频文件名称
        NSString *str = [self getCurrentDate];
        
        NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"%@%@",str,@"myMovie.mov"]];
        
        NSURL *fileUrl = [NSURL fileURLWithPath:outputFilePath];
        [self.movieFileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
        return YES;
        
    }
    [self.movieFileOutput stopRecording];
    return NO;
}

/**
 开始合并视频
 */
- (void)mergeClick {
    if (_videoArray.count <= 0) {
        [self noticeAlertTitle:@"请先录制视频，然后后在合并" cancel:@"确定"];
        return;
    }
    
    if ([self.movieFileOutput isRecording]) {
        NSLog(@"请录制完成后在合并");
        [self noticeAlertTitle:@"请录制完成后在合并" cancel:@"确定"];
        return;
    }
    
    UIAlertView *alert = [self noticeAlertTitle:@"处理中..." cancel:nil];
    NSString *pathStr = [self getCurrentDate];
    [[XDVideoManager defaultManager]
     mergeVideosToOneVideo:_videoArray
     toStorePath:pathStr
     WithStoreName:@"xiaoxie"
     backGroundTask:_backgroundTaskIdentifier
     success:^(NSString *info){
         NSLog(@"%@",info);
         [_videoArray removeAllObjects];
         
         [alert dismissWithClickedButtonIndex:-1 animated:YES];

     } failure:^(NSString *error){
         NSLog(@"%@", error);
        [_videoArray removeAllObjects];
    }];
}

/**
 点击屏幕聚焦

 @param view 手势所在的视图
 @param gesture 手势
 */
- (void)videoLayerClick:(SelectView *)view gesture:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:view];
    NSLog(@"位置：%f",point.y);
    CGPoint cameraPoint = [self.videoPreviewLayer captureDevicePointOfInterestForPoint:point];
    
    [self setFocusViewWithPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

/**
 设置聚焦光标位置
 
 @param point 光标位置
 */
-(void)setFocusViewWithPoint:(CGPoint)point{
    self.focusView.center=point;
    self.focusView.transform=CGAffineTransformMakeScale(1.5, 1.5);
    self.focusView.alpha=1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusView.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusView.alpha=0;
        
    }];
}

/**
 设置聚焦点
 
 @param point 聚焦点
 */
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:focusMode];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:exposureMode];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

#pragma mark -- 视频输出代理
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"开始录制...");
    [_videoArray addObject:fileURL];
    NSLog(@"%@",fileURL);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    NSLog(@"视频录制完成");
    self.enableRotation = YES;
    NSLog(@"%@",outputFileURL);
}

@end
