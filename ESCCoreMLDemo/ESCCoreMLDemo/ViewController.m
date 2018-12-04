//
//  ViewController.m
//  ESCMachineLearningDemo
//
//  Created by xiang on 2018/12/4.
//  Copyright © 2018 xiang. All rights reserved.
//

#import "ViewController.h"
#import "Resnet50.h"
@import CoreVideo;
@import MobileCoreServices;

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property(nonatomic,strong)UIImagePickerController* imagePickerController;

@property(nonatomic,weak)UIImageView* imageView;

@property(nonatomic,weak)UILabel* photoNameLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *photoBtnItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                  target:self
                                                                                  action:@selector(takeCamera)];
    self.navigationItem.rightBarButtonItem = photoBtnItem;
    
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.delegate = self;
    self.imagePickerController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    self.imagePickerController.allowsEditing = YES;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 20, 300, 300)];
    [self.view addSubview:imageView];
    self.imageView = imageView;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    UILabel *photoNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 330, 200, 30)];
    self.photoNameLabel = photoNameLabel;
    [self.view addSubview:photoNameLabel];
    self.photoNameLabel.numberOfLines = 0;
    
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.imageView.frame = CGRectMake(20, 20, 300, 300);
    self.photoNameLabel.frame = CGRectMake(20, 350, 200, 200);
}

- (void)takeCamera {
    
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    self.imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    [self.navigationController presentViewController:self.imagePickerController
                                            animated:YES
                                          completion:nil];
}

#pragma mark -
#pragma mark - UIImageController Delegate
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType=[info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]){
        CGSize thesize = CGSizeMake(224, 224);
        UIImage *theimage = [self image:info[UIImagePickerControllerEditedImage] scaleToSize:thesize];
        self.imageView.image = theimage;
        
        CVPixelBufferRef imageRef = [self pixelBufferFromCGImage:theimage.CGImage];
        Resnet50 *resnet50Model = [[Resnet50 alloc] init];
        NSError *error = nil;
        Resnet50Output *output = [resnet50Model predictionFromImage:imageRef
                                                              error:&error];
        if (error == nil) {
            self.photoNameLabel.text = output.classLabel;
            NSLog(@"%@",output.classLabelProbs);
        } else {
            NSLog(@"Error is %@", error.localizedDescription);
        }
    }
    
    UIImagePickerController *imagePickerVC = picker;
    [imagePickerVC dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark - Image Helpful Tools
- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image {
    NSDictionary *options = @{
                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                              };
    
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(image),
                                          CGImageGetHeight(image), kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    if (status!=kCVReturnSuccess) {
        NSLog(@"Operation failed");
    }
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, CGImageGetWidth(image),
                                                 CGImageGetHeight(image), 8, 4*CGImageGetWidth(image), rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGAffineTransform flipVertical = CGAffineTransformMake( 1, 0, 0, -1, 0, CGImageGetHeight(image) );
    CGContextConcatCTM(context, flipVertical);
    CGAffineTransform flipHorizontal = CGAffineTransformMake( -1.0, 0.0, 0.0, 1.0, CGImageGetWidth(image), 0.0 );
    CGContextConcatCTM(context, flipHorizontal);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    return pxbuffer;
}

- (UIImage*)image:(UIImage *)image scaleToSize:(CGSize)size{
    
    UIGraphicsBeginImageContext(size);
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

@end
