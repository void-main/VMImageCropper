//
//  VMAppDelegate.h
//  VMImageCropperExample
//
//  Created by Sun Peng on 14-7-20.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VMCropperImageView;
@interface VMAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet VMCropperImageView *cropperView;

@end
