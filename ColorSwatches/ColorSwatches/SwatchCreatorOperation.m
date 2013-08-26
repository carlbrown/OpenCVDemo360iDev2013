//
//  SwatchCreatorOperation.m
//  ColorSwatches
//
//  Created by Carl Brown on 8/25/13.
//  Copyright (c) 2013 PDAgent. All rights reserved.
//

#import "SwatchCreatorOperation.h"
#import "AppDelegate.h"

@implementation SwatchCreatorOperation

-(void) main {
    if (!self.colorName) {
        NSLog(@"Missing color name");
        return;
    }
    NSString *libDir = [(AppDelegate *) [[UIApplication sharedApplication] delegate] applicationLibraryDirectory];
    NSString *swatchPath = [libDir stringByAppendingPathComponent:[self.colorName stringByAppendingPathExtension:@"jpg"]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:swatchPath]) {
        NSLog(@"Color File for %@ exists",self.colorName);
        return;
    }
    
    CGRect swatchRect = CGRectMake(0.0,0.0,44.0,44.0);
    UIColor *swatchColor = [[UIColor class] performSelector:NSSelectorFromString([self.colorName stringByAppendingString:@"Color"])];
    

    
    UIGraphicsBeginImageContextWithOptions(swatchRect.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, swatchColor.CGColor);
    CGContextFillRect(context,swatchRect);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage* image = [[UIImage alloc] initWithCGImage:imageRef];
    NSData* imageData = UIImageJPEGRepresentation(image, 0.9f);
    NSLog(@"Saving file %@",swatchPath);
    [imageData writeToFile:swatchPath atomically:YES];

}

@end
