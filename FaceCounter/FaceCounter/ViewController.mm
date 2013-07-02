//
//  ViewController.m
//  FaceCounter
//
//  Created by Carl Brown on 7/1/13.
//  Copyright (c) 2013 PDAgent. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <opencv2/opencv.hpp>

using namespace std;
using namespace cv;

/** Global variables */
CascadeClassifier face_cascade;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *facesImageView;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *faceCascadePath = [[NSBundle bundleForClass:[ViewController class]] pathForResource:@"lbpcascade_frontalface" ofType:@"xml"];

	// Do any additional setup after loading the view, typically from a nib.
    if( !face_cascade.load( [faceCascadePath cStringUsingEncoding:NSASCIIStringEncoding]) ){ NSLog(@"--(!)Error loading face_cascade\n"); };

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)contentScaleFactor
{
    CGFloat widthScale = self.facesImageView.bounds.size.width / self.facesImageView.image.size.width;
    CGFloat heightScale = self.facesImageView.bounds.size.height / self.facesImageView.image.size.height;
    
    if (self.facesImageView.contentMode == UIViewContentModeScaleToFill) {
        return (widthScale==heightScale) ? widthScale : NAN;
    }
    if (self.facesImageView.contentMode == UIViewContentModeScaleAspectFit) {
        return MIN(widthScale, heightScale);
    }
    if (self.facesImageView.contentMode == UIViewContentModeScaleAspectFill) {
        return MAX(widthScale, heightScale);
    }
    return 1.0;
    
}

- (IBAction)coreImageButtonPressed:(id)sender {
    for (UIView *subView in self.facesImageView.subviews) {
        [subView removeFromSuperview];
    }

    UIImage *image = [self.facesImageView image];
    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
    NSArray *features = [detector featuresInImage:ciImage];
    [self.countLabel setText:[NSString stringWithFormat:@"CoreImage found %d faces",[features count]]];

    for(CIFaceFeature* faceFeature in features)
    {
        
        // create a UIView using the bounds of the face
        CGRect frame = faceFeature.bounds;
        frame.size.width *= [self contentScaleFactor];
        frame.size.height *= [self contentScaleFactor];
        frame.origin.x *= [self contentScaleFactor];
        frame.origin.y *= [self contentScaleFactor];
        frame.origin.y = image.size.height*[self contentScaleFactor] - frame.origin.y - frame.size.height; //flip to CIImage Coords
        UIView* faceView = [[UIView alloc] initWithFrame:frame];
        
        // add a border around the newly created UIView
        faceView.layer.borderWidth = 1;
        faceView.layer.borderColor = [[UIColor redColor] CGColor];
        
        // add the new view to create a box around the face
        [self.facesImageView addSubview:faceView];
    }
}

- (IBAction)openCVButtonPressed:(id)sender {
    for (UIView *subView in self.facesImageView.subviews) {
        [subView removeFromSuperview];
    }

    std::vector<cv::Rect> faces;
    std::vector<cv::Rect> profiles;
    Mat frame_gray;
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(self.facesImageView.image.CGImage);
    CGFloat cols = self.facesImageView.image.size.width;
    CGFloat rows = self.facesImageView.image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), self.facesImageView.image.CGImage);
    CGContextRelease(contextRef);

    
    cvtColor( cvMat, frame_gray, CV_BGR2GRAY );
    equalizeHist( frame_gray, frame_gray );
    
    //-- Detect faces
    face_cascade.detectMultiScale( frame_gray, faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(30, 30) );

    [self.countLabel setText:[NSString stringWithFormat:@"OpenCV found %ld faces",faces.size()]];
    
    for( int i = 0; i < faces.size(); i++ )
    {
        // create a UIView using the bounds of the face
        CGRect frame = CGRectMake(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
        frame.size.width *= [self contentScaleFactor];
        frame.size.height *= [self contentScaleFactor];
        frame.origin.x *= [self contentScaleFactor];
        frame.origin.y *= [self contentScaleFactor];

        UIView* faceView = [[UIView alloc] initWithFrame:frame];
        
        // add a border around the newly created UIView
        faceView.layer.borderWidth = 1;
        faceView.layer.borderColor = [[UIColor redColor] CGColor];
        
        // add the new view to create a box around the face
        [self.facesImageView addSubview:faceView];

    }
    
}

- (IBAction)resetButtonPressed:(id)sender {
    [self.countLabel setText:@"Not currently Counting"];
    for (UIView *subView in self.facesImageView.subviews) {
        [subView removeFromSuperview];
    }
}
@end
