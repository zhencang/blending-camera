//
//  BCPathView.m
//  BlendingCamera
//
//  Created by 武田 祐一 on 2012/09/21.
//  Copyright (c) 2012年 武田 祐一. All rights reserved.
//

#import "BCPathView.h"
#import <QuartzCore/QuartzCore.h>

@interface BCPathView ()
@property (nonatomic, assign) CGPoint previousPoint;
@property (nonatomic, assign) CGPoint pointDif;
@end

@implementation BCPathView
static const CGFloat penColor[] = {1.0, 1.0, 1.0, 1.0}; // white
static const CGFloat penWidth = 5.0;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		self.backgroundColor = [UIColor clearColor];
		self.bitmapCopntext = [BCPathView newTransparentBitmapContextOfSize:frame.size];
		CGContextRetain(self.bitmapCopntext);
		
		self.pathLayer = [CALayer layer];
		self.pathLayer.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
		[self.layer addSublayer:self.pathLayer];

		self.currentPath = CGPathCreateMutable();

    }
    return self;
}


#pragma mark utility methods
+ (CGContextRef)newBlankBitmapContextOfSize:(CGSize)size
{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	int bytesPerRow = (int)size.width * 4; // 4 means channel
	void *bitmapData = malloc(bytesPerRow * (int)size.height);
	
	CGContextRef context = CGBitmapContextCreate(bitmapData, size.width, size.height, 8, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(colorSpace);
	return context;
}

+ (CGContextRef)newTransparentBitmapContextOfSize:(CGSize)size
{
	CGContextRef context = [BCPathView newBlankBitmapContextOfSize:size];
	CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 0.0);
	CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
	CGContextTranslateCTM(context, 0, size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	return context;
}



#pragma mark -- touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint point = [((UITouch *)[touches anyObject]) locationInView:self];
	if (CGPathIsEmpty(_currentPath)) {
		CGPathMoveToPoint(self.currentPath, NULL, point.x, point.y);
		[self initializeCurve:point];
	} else {
		CGPathAddLineToPoint(self.currentPath, nil, point.x, point.y);
		[self closedCurve:point];
	}

}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint point = [((UITouch *)[touches anyObject]) locationInView:self];
	CGPathAddLineToPoint(self.currentPath, nil, point.x, point.y);
	self.pathLayer.delegate = self;
	[_pathLayer setNeedsDisplay];
	[self closedCurve:point];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint point = [((UITouch *)[touches anyObject]) locationInView:self];
	CGPathAddLineToPoint(self.currentPath, nil, point.x, point.y);
	[self drawCurrentPath:self.bitmapCopntext];
	
	[self closedCurve:point];
	
	
}

#pragma mark -- calcuration
- (void)closedCurve:(CGPoint)currentPoint
{
	_pointDif.x += currentPoint.x - _previousPoint.x;
	_pointDif.y += currentPoint.y - _previousPoint.y;
	NSLog(@"previous = %.3f, .%.3f, current = %.3f, %.3f, diff= %.3f, %.3f", _previousPoint.x, _previousPoint.y, currentPoint.x, currentPoint.y, _pointDif.x, _pointDif.y);
	self.previousPoint = currentPoint;
}

- (void)initializeCurve:(CGPoint)firstPoint
{
	self.previousPoint = firstPoint;
}

- (BOOL)isCurveClosed
{
	CGFloat distance = _pointDif.x * _pointDif.x +_pointDif.y * _pointDif.y;
	NSLog(@"distance = %f", distance);
	return (distance < 10.0) ? YES : NO;
}


#pragma mark -- drawings
/*
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)drawCurrentPath:(CGContextRef)context
{
	if (self.currentPath != nil) {
		CGContextSetStrokeColor(context, penColor);
		CGContextBeginPath(context);
		CGContextAddPath(context, self.currentPath);
		CGContextSetLineWidth(context, penWidth);
		CGContextSetLineCap(context, kCGLineCapRound);
		CGContextSetLineJoin(context, kCGLineJoinRound);
		CGContextStrokePath(context);
	}
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	[self drawCurrentPath:ctx];
}

@end