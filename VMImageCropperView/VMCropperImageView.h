//
//  VMCropperImageView.h
//  VMImageCropperExample
//
//  Created by Sun Peng on 14-7-20.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    OnLeft = 1,
    OnRight = 2,
    OnTop = 4,
    OnBottom = 8,
    Inside = 0,
    Outside = -1,
} PointLineRelation;

typedef enum : NSUInteger {
    Move,
    New,
    Top,
    Bottom,
    Left,
    Right,
    CornerTL,
    CornerTR,
    CornerBL,
    CornerBR,
} DragType;

@class VMCropCoreView;
@interface VMCropperImageView : NSImageView {
    CGRect _actualRect;
    CGRect _cropRect;

    DragType _dragType;

    NSPoint _startPoint;
    NSRect  _startFrame;

    VMCropCoreView *_cropCoreView;
}

@end
