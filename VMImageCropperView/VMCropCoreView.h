//
//  VMCropCoreView.h
//  VMImageCropperExample
//
//  Created by Sun Peng on 14-7-20.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kBorderWidth  8
#define kCornerLength 20

typedef enum : NSUInteger {
    None,
    Normal,
    Dragging,
} ViewStatus;

@interface VMCropCoreView : NSView

@property ViewStatus viewStatus;

@end
