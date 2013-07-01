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

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *facesImageView;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
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
    UIImage *image = [self.facesImageView image];
    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
    NSArray *features = [detector featuresInImage:ciImage];
    [self.countLabel setText:[NSString stringWithFormat:@"Found %d faces",[features count]]];

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
}

- (IBAction)resetButtonPressed:(id)sender {
}
@end
