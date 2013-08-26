//
//  ViewController.mm
//  ColorSwatches
//
//  Created by Carl Brown on 8/25/13.
//  Copyright (c) 2013 PDAgent. All rights reserved.
//

#import "ViewController.h"
#import "SwatchCreatorOperation.h"
#import "UIImage+OpenCV.h"
#import "AppDelegate.h"

@interface ViewController ()
@property (nonatomic, strong) NSArray *colornames;
@property (nonatomic, strong) NSOperationQueue *opQueue;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.colornames = @[@"red",@"blue",@"green",@"orange",@"yellow",@"white",@"purple",@"magenta",@"brown",@"gray",@"black"];
    self.opQueue = [[NSOperationQueue alloc] init];
    for (NSString *color in self.colornames) {
        SwatchCreatorOperation *op = [[SwatchCreatorOperation alloc] init];
        op.colorName = color;
        [self.opQueue addOperation:op];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.colornames count];
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    [[cell textLabel] setText:[self.colornames objectAtIndex:indexPath.row]];
    NSString *libDir = [(AppDelegate *) [[UIApplication sharedApplication] delegate] applicationLibraryDirectory];
    NSString *swatchPath = [libDir stringByAppendingPathComponent:[[self.colornames objectAtIndex:indexPath.row] stringByAppendingPathExtension:@"jpg"]];
    UIImage *swatchImage = [UIImage imageWithContentsOfFile:swatchPath];
    if (swatchImage) {
        [cell.imageView setImage:swatchImage];
        
        cv::Mat swatchMat = [swatchImage CVMat];
        cv::Scalar avg = cv::mean(swatchMat);
        cv::Mat swatchHSV(swatchMat.rows, swatchMat.cols, swatchMat.type());
        
        cvtColor(swatchMat, swatchHSV, CV_RGB2HSV);
        cv::Scalar avgHue = cv::mean(swatchHSV);

        [cell.detailTextLabel setText:[NSString stringWithFormat:@"R:%.0f,G:%.0f,B:%.0f/H%.0f,S%.0f,V:%.0f",avg[0],avg[1],avg[2],avgHue[0],avgHue[1],avgHue[2]]];
    }
    
    return cell;
}

@end
