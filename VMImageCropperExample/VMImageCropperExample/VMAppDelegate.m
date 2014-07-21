//
//  VMAppDelegate.m
//  VMImageCropperExample
//
//  Created by Sun Peng on 14-7-20.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import "VMAppDelegate.h"
#import "VMCropperImageView.h"

@implementation VMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSImage *testImage = [NSImage imageNamed:@"IMG.jpg"];
    self.cropperView.image = testImage;
}

@end
