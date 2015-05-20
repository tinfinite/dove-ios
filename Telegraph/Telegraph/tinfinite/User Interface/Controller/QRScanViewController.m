
//
//  RootViewController.m
//  NewProject
//
//  Created by 学鸿 张 on 13-11-29.
//  Copyright (c) 2013年 Steven. All rights reserved.
//

#import "QRScanViewController.h"
#import "TGBackdropView.h"
#import "TGApplication.h"
#import "ZXingObjC.h"

@interface QRScanViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@end

@implementation QRScanViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    //cover
    UIImageView *coverTop = [[UIImageView alloc] init];
    coverTop.frame = CGRectMake(0, 0, screenSize.width, (screenSize.height-280)/2);
    coverTop.backgroundColor = [UIColor whiteColor];
    coverTop.alpha = 0.85f;
    [self.view addSubview:coverTop];
    
    UIImageView *coverLeft = [[UIImageView alloc] init];
    coverLeft.frame = CGRectMake(0, (screenSize.height-280)/2, (screenSize.width-280)/2, 280);
    coverLeft.backgroundColor = [UIColor whiteColor];
    coverLeft.alpha = 0.85f;
    [self.view addSubview:coverLeft];
    
    UIImageView *coverRight = [[UIImageView alloc] init];
    coverRight.frame = CGRectMake((screenSize.width+280)/2, (screenSize.height-280)/2, (screenSize.width-280)/2, 280);
    coverRight.backgroundColor = [UIColor whiteColor];
    coverRight.alpha = 0.85f;
    [self.view addSubview:coverRight];
    
    UIImageView *coverBottom = [[UIImageView alloc] init];
    coverBottom.frame = CGRectMake(0, (screenSize.height+280)/2, screenSize.width, (screenSize.height-280)/2);
    coverBottom.backgroundColor = [UIColor whiteColor];
    coverBottom.alpha = 0.85f;
    [self.view addSubview:coverBottom];
    
    TGBackdropView *backView = [TGBackdropView viewWithLightNavigationBarStyle];
    backView.frame = CGRectMake(0.0f, 0.0f, screenSize.width, 20 + 44);
    [self.view addSubview:backView];
    
	UIButton * scanButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [scanButton setTitle:TGLocalized(@"GroupInfo.Cancel") forState:UIControlStateNormal];
    [scanButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    scanButton.titleLabel.font = [UIFont systemFontOfSize:16];
    scanButton.frame = CGRectMake(0, 20, 80, 44);
    [scanButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    scanButton.titleEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
    scanButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    scanButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [backView addSubview:scanButton];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = TGLocalized(@"GroupInfo.QRCode");
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [titleLabel sizeToFit];
    titleLabel.center = CGPointMake(screenSize.width/2, 42);
    [backView addSubview:titleLabel];
    
    
    
    UILabel * labIntroudction= [[UILabel alloc] initWithFrame:CGRectMake(15, 40, 290, 50)];
    labIntroudction.center = CGPointMake(screenSize.width/2, screenSize.height/2-140-40);
    labIntroudction.numberOfLines=2;
    labIntroudction.textColor=UIColorRGB(0x4a4a4a);
    labIntroudction.textAlignment = NSTextAlignmentCenter;
    labIntroudction.text=TGLocalized(@"GroupInfo.ScanInfo");
    [self.view addSubview:labIntroudction];
    
    UIImageView *bottomLine = [[UIImageView alloc] init];
    bottomLine.frame = CGRectMake(15, screenSize.height-57, screenSize.width-30, 0.5);
    bottomLine.backgroundColor = UIColorRGB(0x979797);
    [self.view addSubview:bottomLine];
    
    UIButton *cameraBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [cameraBtn setTitle:TGLocalized(@"GroupInfo.UseORCodeImage") forState:UIControlStateNormal];
    cameraBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [cameraBtn addTarget:self action:@selector(enterCameraRoll) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraBtn];
    cameraBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:cameraBtn attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:cameraBtn attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:-33]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:cameraBtn attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:40]];
    
    upOrdown = NO;
    num =0;
    _line = [[UIImageView alloc] initWithFrame:CGRectMake(50, 110, 220, 2)];
    _line.center = CGPointMake(screenSize.width/2, screenSize.height/2-120);
    _line.image = [UIImage imageNamed:@"line.png"];
    [self.view addSubview:_line];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:.02 target:self selector:@selector(animation1) userInfo:nil repeats:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(void)animation1
{
    CGFloat baseY = [UIScreen mainScreen].bounds.size.height/2-120-1;
    if (upOrdown == NO) {
        num ++;
        _line.frame = CGRectMake(_line.frame.origin.x, baseY+2*num, 220, 2);
        if (2*num == 240) {
            upOrdown = YES;
        }
    }
    else {
        num --;
        _line.frame = CGRectMake(_line.frame.origin.x, baseY+2*num, 220, 2);
        if (num == 0) {
            upOrdown = NO;
        }
    }

}
-(void)backAction
{
    
    [self dismissViewControllerAnimated:YES completion:^{
        [timer invalidate];
    }];
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupCamera];
}

- (void)enterCameraRoll
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:^{
        [(TGApplication *)[UIApplication sharedApplication] forceSetStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

- (void)setupCamera
{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    // Device
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Input
    _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    // Output
    _output = [[AVCaptureMetadataOutput alloc]init];
    CGSize size = self.view.bounds.size;
    CGRect cropRect = CGRectMake((screenSize.width-280)/2, (screenSize.height-280)/2, 280, 280);
    CGFloat p1 = size.height/size.width;
    CGFloat p2 = 1920.f/1080.f;  //使用了1080p的图像输出
    if (p1 < p2) {
        CGFloat fixHeight = self.view.bounds.size.width * 1920.f / 1080.f;
        CGFloat fixPadding = (fixHeight - size.height)/2;
        _output.rectOfInterest = CGRectMake((cropRect.origin.y + fixPadding)/fixHeight,
                                                  cropRect.origin.x/size.width,
                                                  cropRect.size.height/fixHeight,
                                                  cropRect.size.width/size.width);
    } else {
        CGFloat fixWidth = self.view.bounds.size.height * 1080.f / 1920.f;
        CGFloat fixPadding = (fixWidth - size.width)/2;
        _output.rectOfInterest = CGRectMake(cropRect.origin.y/size.height,
                                                  (cropRect.origin.x + fixPadding)/fixWidth,
                                                  cropRect.size.height/size.height,
                                                  cropRect.size.width/fixWidth);
    }
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // Session
    _session = [[AVCaptureSession alloc]init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([_session canAddInput:self.input])
    {
        [_session addInput:self.input];
    }
    
    if ([_session canAddOutput:self.output])
    {
        [_session addOutput:self.output];
    }
    
    // 条码类型 AVMetadataObjectTypeQRCode
    _output.metadataObjectTypes =@[AVMetadataObjectTypeQRCode];
    
    // Preview
    _preview =[AVCaptureVideoPreviewLayer layerWithSession:self.session];
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _preview.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.preview atIndex:0];

    // Start
    [_session startRunning];
}
#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *) __unused captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *) __unused connection
{
   
    NSString *stringValue;
    
    if ([metadataObjects count] >0)
    {
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        stringValue = metadataObject.stringValue;
    }
    
    [_session stopRunning];
   [self dismissViewControllerAnimated:YES completion:^
    {
        [timer invalidate];
        
        
        
        if (self.scanSuccessBlock) {
            self.scanSuccessBlock(stringValue);
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *) __unused picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:^{
        [(TGApplication *)[UIApplication sharedApplication] forceSetStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        [self setNeedsStatusBarAppearanceUpdate];
    }];
    
    UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
    CGImageRef imageToDecode = [image CGImage];  // Given a CGImage in which we are looking for barcodes
    
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:imageToDecode];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    
    NSError *error = nil;
    
    // There are a number of hints we can give to the reader, including
    // possible formats, allowed lengths, and the string encoding.
    ZXDecodeHints *hints = [ZXDecodeHints hints];
    
    ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
    ZXResult *result = [reader decode:bitmap
                                hints:hints
                                error:&error];
    if (result) {
        // The coded result as a string. The raw data can be accessed with
        // result.rawBytes and result.length.
        NSString *content = result.text;
        [_session stopRunning];
        [self dismissViewControllerAnimated:YES completion:^
         {
             [timer invalidate];
             if (self.scanSuccessBlock) {
                 self.scanSuccessBlock(content);
             }
         }];
    } else {
        
        if (!_session.running) {
            [_session startRunning];
        }
        
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *) __unused picker
{
    [self dismissViewControllerAnimated:YES completion:^{
        [(TGApplication *)[UIApplication sharedApplication] forceSetStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        [self setNeedsStatusBarAppearanceUpdate];
    }];
    
    if (!_session.running) {
        [_session startRunning];
    }
}

@end
