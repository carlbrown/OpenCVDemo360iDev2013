//
//  AppDelegate.h
//  ColorSwatches
//
//  Created by Carl Brown on 8/25/13.
//  Copyright (c) 2013 PDAgent. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

- (NSString *) applicationLibraryDirectory;

@end
