//
//  VMCropCoreView.m
//  VMImageCropperExample
//
//  Created by Sun Peng on 14-7-20.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import "VMCropCoreView.h"

@implementation VMCropCoreView

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    NSBezierPath *path = [NSBezierPath bezierPathWithRect:self.bounds];
    [path setLineWidth:kBorderWidth];
    [[NSColor grayColor] setStroke];
    [path stroke];

    [path setLineWidth:kBorderWidth * 0.5];
    [[NSColor blackColor] setStroke];
    [path stroke];

    if (self.bounds.size.width > 2 * kCornerLength && self.bounds.size.height > 2 * kCornerLength) {

        NSBezierPath *corners = [NSBezierPath bezierPath];
        // Bottom Left Corner
        [corners moveToPoint:NSMakePoint(0, 0)];
        [corners lineToPoint:NSMakePoint(kCornerLength, 0)];
        [corners moveToPoint:NSMakePoint(0, 0)];
        [corners lineToPoint:NSMakePoint(0, kCornerLength)];

        // Bottom Right Corner
        [corners moveToPoint:NSMakePoint(self.bounds.size.width, 0)];
        [corners lineToPoint:NSMakePoint(self.bounds.size.width, kCornerLength)];
        [corners moveToPoint:NSMakePoint(self.bounds.size.width, 0)];
        [corners lineToPoint:NSMakePoint(self.bounds.size.width - kCornerLength, 0)];

        // Top Left Corner
        [corners moveToPoint:NSMakePoint(0, self.bounds.size.height)];
        [corners lineToPoint:NSMakePoint(kCornerLength, self.bounds.size.height)];
        [corners moveToPoint:NSMakePoint(0, self.bounds.size.height)];
        [corners lineToPoint:NSMakePoint(0, self.bounds.size.height - kCornerLength)];

        // Top Right Corner
        [corners moveToPoint:NSMakePoint(self.bounds.size.width, self.bounds.size.height)];
        [corners lineToPoint:NSMakePoint(self.bounds.size.width - kCornerLength, self.bounds.size.height)];
        [corners moveToPoint:NSMakePoint(self.bounds.size.width, self.bounds.size.height)];
        [corners lineToPoint:NSMakePoint(self.bounds.size.width, self.bounds.size.height - kCornerLength)];
        
        [[NSColor greenColor] set];
        [corners setLineWidth:kBorderWidth];
        [corners stroke];
    }
}

@end
