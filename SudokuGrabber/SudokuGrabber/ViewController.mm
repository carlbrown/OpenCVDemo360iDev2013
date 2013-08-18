//
//  ViewController.m
//  SudokuGrabber
//
//  Created by Carl Brown on 8/15/13.
//  Copyright (c) 2013 PDAgent. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <opencv2/opencv.hpp>
#import <math.h>

#define EPS 0.1

using namespace std;
using namespace cv;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) UIImage *originalImage;
@property (strong, nonatomic) UIImage *perspectiveShiftedImage;
@property (strong, nonatomic) NSArray *cubeCorners;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.originalImage = self.imageView.image;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)contentScaleFactor
{
    CGFloat widthScale = self.imageView.bounds.size.width / self.imageView.image.size.width;
    CGFloat heightScale = self.imageView.bounds.size.height / self.imageView.image.size.height;
    
    if (self.imageView.contentMode == UIViewContentModeScaleToFill) {
        return (widthScale==heightScale) ? widthScale : NAN;
    }
    if (self.imageView.contentMode == UIViewContentModeScaleAspectFit) {
        return MIN(widthScale, heightScale);
    }
    if (self.imageView.contentMode == UIViewContentModeScaleAspectFill) {
        return MAX(widthScale, heightScale);
    }
    return 1.0;
    
}

/*
 Determine the intersection point of two line segments
 Return FALSE if the lines don't intersect
 
 Adapted from http://paulbourke.net/geometry/pointlineplane/pdb.c
 
 */
int LineIntersect(Vec4i l1, Vec4i l2)
{
    
    double x1=l1[0];
    double x2=l1[2];
    double x3=l2[0];
    double x4=l2[2];
    
    
    double y1=l1[1];
    double y2=l1[3];
    double y3=l2[1];
    double y4=l2[3];
    
    double mua,mub;
    double denom,numera,numerb;
    
    denom  = (y4-y3) * (x2-x1) - (x4-x3) * (y2-y1);
    numera = (x4-x3) * (y1-y3) - (y4-y3) * (x1-x3);
    numerb = (x2-x1) * (y1-y3) - (y2-y1) * (x1-x3);
    
    /* Are the line coincident? */
    if (ABS(numera) < EPS && ABS(numerb) < EPS && ABS(denom) < EPS) {
        return(FALSE);
    }
    
    /* Are the line parallel-ish */
    if (ABS(denom) < 1.0) {
        return(FALSE);
    }
    
    /* Is the intersection along the the segments */
    mua = numera / denom;
    mub = numerb / denom;
    if (mua < -0.1 || mua > 1.1 || mub < -0.1 || mub > 1.1) {
        return(FALSE);
    }
    return(TRUE);
}



- (IBAction)findPuzzlePressed:(id)sender {
    
        //Conversion from http://stackoverflow.com/a/10254561
        CGColorSpaceRef colorSpace = CGImageGetColorSpace(self.imageView.image.CGImage);
        CGFloat cols = self.imageView.image.size.width;
        CGFloat rows = self.imageView.image.size.height;
        
        cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
        
        CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                        cols,                      // Width of bitmap
                                                        rows,                     // Height of bitmap
                                                        8,                          // Bits per component
                                                        cvMat.step[0],              // Bytes per row
                                                        colorSpace,                 // Colorspace
                                                        kCGImageAlphaNoneSkipLast |
                                                        kCGBitmapByteOrderDefault); // Bitmap info flags
        
        CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), self.imageView.image.CGImage);
        CGContextRelease(contextRef);
        
        // Hough Line Transform example from
        //From http://docs.opencv.org/doc/tutorials/imgproc/imgtrans/hough_lines/hough_lines.html
        cv::Mat dst, ddst, cdst;
        Canny(cvMat, dst, 40, 120, 3);
        cvtColor(dst, cdst, CV_GRAY2BGR);
        
        vector<Vec4i> lines;
        HoughLinesP(dst, lines, 1, CV_PI/180, 50, 50, 10 );
        
        //Defaults for the corners - use as far away as possible, as we want min
        cv::Point ul = cv::Point(cvMat.cols, cvMat.rows); //upper left
        cv::Point ur = cv::Point(0, cvMat.rows); //upper right
        cv::Point ll = cv::Point(cvMat.cols, 0); //lower left
        cv::Point lr = cv::Point(0, 0); //lower right
        
        for( size_t i = 0; i < lines.size(); i++ )
        {
            Vec4i l = lines[i];
            for (size_t i2 = 0; i2 < lines.size(); i2++ ) {
                if (i != i2) {
                    Vec4i l2=lines[i2];
                    if (LineIntersect(l, l2)) {
                        line( cdst, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), Scalar(0,0,255), 3, CV_AA);
                        line( cvMat, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), Scalar(0,0,255), 3, CV_AA);
                        //Check for bounding corners (from Carl)
                        if (sqrt(l[0]*l[0]+l[1]*l[1]) < sqrt(ul.x*ul.x+ul.y*ul.y)) {
                            ul = cv::Point(l[0],l[1]);
                        }
                        if (sqrt((cvMat.cols -l[0])*(cvMat.cols -l[0])+l[1]*l[1]) < sqrt((cvMat.cols -ur.x)*(cvMat.cols -ur.x)+ur.y*ur.y)) {
                            ur = cv::Point(l[0],l[1]);
                        }
                        if (sqrt(l[0]*l[0]+(cvMat.rows -l[1])*(cvMat.rows -l[1])) < sqrt(ll.x*ll.x+(cvMat.rows -ll.y)*(cvMat.rows -ll.y))) {
                            ll = cv::Point(l[0],l[1]);
                        }
                        if (sqrt((cvMat.cols -l[0])*(cvMat.cols -l[0])+(cvMat.rows -l[1])*(cvMat.rows -l[1])) < sqrt((cvMat.cols -lr.x)*(cvMat.cols -lr.x)+(cvMat.rows -lr.y)*(cvMat.rows -lr.y))) {
                            lr = cv::Point(l[0],l[1]);
                        }
                        if (sqrt(l[2]*l[2]+l[3]*l[3]) < sqrt(ul.x*ul.x+ul.y*ul.y)) {
                            ul = cv::Point(l[2],l[3]);
                        }
                        if (sqrt((cvMat.cols -l[2])*(cvMat.cols -l[2])+l[3]*l[3]) < sqrt((cvMat.cols -ur.x)*(cvMat.cols -ur.x)+ur.y*ur.y)) {
                            ur = cv::Point(l[2],l[3]);
                        }
                        if (sqrt(l[2]*l[2]+(cvMat.rows -l[3])*(cvMat.rows -l[3])) < sqrt(ll.x*ll.x+(cvMat.rows -ll.y)*(cvMat.rows -ll.y))) {
                            ll = cv::Point(l[2],l[3]);
                        }
                        if (sqrt((cvMat.cols -l[2])*(cvMat.cols -l[2])+(cvMat.rows -l[3])*(cvMat.rows -l[3])) < sqrt((cvMat.cols -lr.x)*(cvMat.cols -lr.x)+(cvMat.rows -lr.y)*(cvMat.rows -lr.y))) {
                            lr = cv::Point(l[2],l[3]);
                        }
                        break;
                    }
                }
            }
        }
        
        circle( cvMat,
               ul,
               12.0,
               Scalar( 0, 255, 0 ),
               10,
               8 );
        circle( cvMat,
               ur,
               12.0,
               Scalar( 0, 255, 0 ),
               10,
               8 );
        circle( cvMat,
               ll,
               12.0,
               Scalar( 0, 255, 0 ),
               10,
               8 );
        circle( cvMat,
               lr,
               12.0,
               Scalar( 0, 255, 0 ),
               10,
               8 );
        
        NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
        
        if (cvMat.elemSize() == 1) {
            colorSpace = CGColorSpaceCreateDeviceGray();
        } else {
            colorSpace = CGColorSpaceCreateDeviceRGB();
        }
        
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
        
        CGImageRef imageRef = CGImageCreate(cvMat.cols,                                     // Width
                                            cvMat.rows,                                     // Height
                                            8,                                              // Bits per component
                                            8 * cvMat.elemSize(),                           // Bits per pixel
                                            cvMat.step[0],                                  // Bytes per row
                                            colorSpace,                                     // Colorspace
                                            kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                            provider,                                       // CGDataProviderRef
                                            NULL,                                           // Decode
                                            false,                                          // Should interpolate
                                            kCGRenderingIntentDefault);                     // Intent
        
        UIImage *newImage = [[UIImage alloc] initWithCGImage:imageRef];
        CGImageRelease(imageRef);
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpace);
        
        [self.imageView setImage:newImage];
    
    self.cubeCorners = @[
                         [NSNumber numberWithFloat:ul.x],
                         [NSNumber numberWithFloat:ul.y],
                         [NSNumber numberWithFloat:ur.x],
                         [NSNumber numberWithFloat:ur.y],
                         [NSNumber numberWithFloat:ll.x],
                         [NSNumber numberWithFloat:ll.y],
                         [NSNumber numberWithFloat:lr.x],
                         [NSNumber numberWithFloat:lr.y]
                         ];

    
    }

- (IBAction)squarePressed:(id)sender {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(self.originalImage.CGImage);
    CGFloat cols = self.originalImage.size.width;
    CGFloat rows = self.originalImage.size.height;
    
    cv::Mat originalMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(originalMat.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    originalMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), self.originalImage.CGImage);
    CGContextRelease(contextRef);
    
    Point2f src[4];
    Point2f dst[4];
    
    src[0]=cv::Point([self.cubeCorners[0] floatValue],[self.cubeCorners[1] floatValue]); //upper left
    src[1]=cv::Point([self.cubeCorners[2] floatValue],[self.cubeCorners[3] floatValue]); //upper right
    src[2]=cv::Point([self.cubeCorners[4] floatValue],[self.cubeCorners[5] floatValue]); //lower left
    src[3]=cv::Point([self.cubeCorners[6] floatValue],[self.cubeCorners[7] floatValue]); //lower right
    
    dst[0]=cv::Point(0,0);
    dst[1]=cv::Point(cols,0);
    dst[2]=cv::Point(0,rows);
    dst[3]=cv::Point(cols,rows);
    
    cv::Mat transform = cv::getPerspectiveTransform(src, dst);
    
    cv::Mat transformedimage = Mat::zeros( originalMat.rows, originalMat.cols, originalMat.type() );
    
    cv::warpPerspective(originalMat, transformedimage, transform, transformedimage.size() );
    
    
    NSData *data = [NSData dataWithBytes:transformedimage.data length:transformedimage.elemSize() * transformedimage.total()];
    
    if (transformedimage.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(transformedimage.cols,                                     // Width
                                        transformedimage.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * transformedimage.elemSize(),                           // Bits per pixel
                                        transformedimage.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    self.perspectiveShiftedImage = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    [self.imageView setImage:self.perspectiveShiftedImage];
    

}

@end
