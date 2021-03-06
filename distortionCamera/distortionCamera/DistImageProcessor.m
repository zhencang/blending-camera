//
//  DistImageProcessor.m
//  distortionCamera
//
//  Created by 武田 祐一 on 2012/12/26.
//  Copyright (c) 2012年 武田 祐一. All rights reserved.
//

#import "DistImageProcessor.h"
#import "DistOptions.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface DistImageProcessor ()
@end

@implementation DistImageProcessor

- (id)initWithEAGLContext:(EAGLContext *)eaglContext
{
    self = [super init];
    if (self) {
        self.ciContext = [CIContext contextWithEAGLContext:eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]}];
        [self initializeFilter];
        [self setupFaceDetection];
        [self applyOptions];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyOptions) name:NSUserDefaultsDidChangeNotification object:nil];
    }
    return self;
}

- (void)initializeFilter
{
    NSDictionary *filter = [DistFilter buildInFilters][0];
    self.distFilter = [[DistFilter alloc] initWithDict:filter];
}

- (void)changeFilter:(NSDictionary *)filterDict
{
    self.distFilter = [[DistFilter alloc] initWithDict:filterDict];
}

- (void)setupFaceDetection
{
    NSString *accuracy = [DistOptions loadDetectorAccuray];
    NSDictionary *option = @{CIDetectorAccuracy : accuracy, CIDetectorTracking : @YES};
    self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:_ciContext options:option];
    NSLog(@"face detection option changed");
}


- (void)applyOptions
{
    if ([DistOptions loadAutoIntensityCollection]) {
        self.colorAdjustmentFilter = [CIFilter filterWithName:@"CIColorControls"];
        [_colorAdjustmentFilter setDefaults];
        [_colorAdjustmentFilter setValue:@1.0 forKey:@"inputSaturation"];
        [_colorAdjustmentFilter setValue:@0.01 forKey:@"inputBrightness"];
        [_colorAdjustmentFilter setValue:@1.0 forKey:@"inputContrast"];
    } else {
        self.colorAdjustmentFilter = nil;
    }

    [self setupFaceDetection];
}

- (CIImage *)applyEffect:(CIImage *)srcImage options:(NSDictionary *)options
{
    if (![options[CIDetectorImageOrientation] isKindOfClass:[NSNumber class]]) {
        return [srcImage copy];
    }

    NSArray *faceFeatures = [_faceDetector featuresInImage:srcImage options:options];
    CIImage *bufferImage = [srcImage copy];

    for (CIFaceFeature *f in faceFeatures) {

        bufferImage = [_distFilter applyEffect:bufferImage feature:f];

    }

    if (_colorAdjustmentFilter) {
        [_colorAdjustmentFilter setValue:bufferImage forKey:@"inputImage"];
        bufferImage = _colorAdjustmentFilter.outputImage;
    }
    return [bufferImage copy];

}

// utility routine used after taking a still image to write the resulting image to the camera roll
+ (void)writeCGImageToCameraRoll:(CGImageRef)cgImage withMetadata:(NSDictionary *)metadata
{
	CFMutableDataRef destinationData = CFDataCreateMutable(kCFAllocatorDefault, 0);
	CGImageDestinationRef destination = CGImageDestinationCreateWithData(destinationData,
																		 CFSTR("public.jpeg"),
																		 1,
																		 NULL);
	BOOL success = (destination != NULL);
    
	const float JPEGCompQuality = 0.85f; // JPEGHigherQuality
	CFMutableDictionaryRef optionsDict = NULL;
	CFNumberRef qualityNum = NULL;
    
	qualityNum = CFNumberCreate(0, kCFNumberFloatType, &JPEGCompQuality);
	if ( qualityNum ) {
		optionsDict = CFDictionaryCreateMutable(0, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		if ( optionsDict )
			CFDictionarySetValue(optionsDict, kCGImageDestinationLossyCompressionQuality, qualityNum);
		CFRelease( qualityNum );
	}
    
	CGImageDestinationAddImage( destination, cgImage, optionsDict );
	success = CGImageDestinationFinalize( destination );
    
	if ( optionsDict )
		CFRelease(optionsDict);
    
    
	CFRetain(destinationData);
	ALAssetsLibrary *library = [ALAssetsLibrary new];
	[library writeImageDataToSavedPhotosAlbum:(id)CFBridgingRelease(destinationData) metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
		if (destinationData)
			CFRelease(destinationData);
	}];
    
}

@end