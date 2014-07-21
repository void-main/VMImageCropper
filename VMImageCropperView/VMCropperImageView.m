//
//  VMCropperImageView.m
//  VMImageCropperExample
//
//  Created by Sun Peng on 14-7-20.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import "VMCropperImageView.h"
#import "VMCropCoreView.h"

#define kSideWidth 4

@interface VMCropperImageView (ImageSize)

- (CGSize)imageScale;
- (CGRect)imageRect;

@end

@interface VMCropperImageView (Draggables)

- (NSInteger)sideLineIndexForX:(NSInteger)x y:(NSInteger)y;
- (NSInteger)crossAtX:(NSInteger)x y:(NSInteger)y;

@end

@implementation VMCropperImageView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        _cropCoreView = [[VMCropCoreView alloc] initWithFrame:NSMakeRect(-10000, -10000, 0, 0)];
        [self addSubview:_cropCoreView];
    }

    return self;
}

- (void)setImage:(NSImage *)newImage
{
    [super setImage:newImage];

    _actualRect = [self imageRect];
    _cropCoreView.frame = _actualRect;
    [_cropCoreView setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Drag
- (void)viewDidMoveToWindow
{
    [self.window setAcceptsMouseMovedEvents:YES];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    NSPoint point = [theEvent locationInWindow];
    point = [self convertPoint:point fromView:nil];

    _dragType = Move;

    PointLineRelation horiRelation = [self point:point onBorder:_cropCoreView.frame horizontal:YES width:kBorderWidth];
    PointLineRelation vertRelation = [self point:point onBorder:_cropCoreView.frame horizontal:NO width:kBorderWidth];
    PointLineRelation horiCrossRelation = [self point:point onBorder:_cropCoreView.frame horizontal:YES width:kCornerLength];
    PointLineRelation vertCrossRelation = [self point:point onBorder:_cropCoreView.frame horizontal:NO width:kCornerLength];

    if (horiRelation == Outside || vertRelation == Outside) {
        _dragType = New;
    } else if (vertRelation == OnTop) {
        if (horiCrossRelation == OnLeft) {
            _dragType = CornerTL;
        } else if (horiCrossRelation == OnRight) {
            _dragType = CornerTR;
        } else {
            _dragType = Top;
        }
    } else if (vertRelation == OnBottom) {
        if (horiCrossRelation == OnLeft) {
            _dragType = CornerBL;
        } else if (horiCrossRelation == OnRight) {
            _dragType = CornerBR;
        } else {
            _dragType = Bottom;
        }
    } else if (horiRelation == OnLeft) {
        if (vertCrossRelation == OnTop) {
            _dragType = CornerTL;
        } else if (vertCrossRelation == OnBottom) {
            _dragType = CornerBL;
        } else {
            _dragType = Left;
        }
    } else if (horiRelation == OnRight) {
        if (vertCrossRelation == OnTop) {
            _dragType = CornerTR;
        } else if (vertCrossRelation == OnBottom) {
            _dragType = CornerBR;
        } else {
            _dragType = Right;
        }
    } // else => _dragType = None

    if (_dragType <= New) {
        [[NSCursor arrowCursor] set];
    } else if (_dragType <= Bottom) {
        [[NSCursor resizeUpDownCursor] set];
    } else if (_dragType <= Right) {
        [[NSCursor resizeLeftRightCursor] set];
    } else {
        [[NSCursor crosshairCursor] set];
    }
}

- (PointLineRelation)point:(NSPoint)point onBorder:(NSRect)border horizontal:(BOOL)horizontal width:(float)width
{
    if (NSPointInRect(point, border)) {
        point.x -= border.origin.x;
        point.y -= border.origin.y;

        if (horizontal) {
            if (point.x < width) {
                return OnLeft;
            } else if (point.x > (border.size.width - width)) {
                return OnRight;
            } else {
                return Inside;
            }
        } else {
            if (point.y < width) {
                return OnBottom;
            } else if (point.y > (border.size.height - width)) {
                return OnTop;
            } else {
                return Inside;
            }
        }
    }

    return Outside;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    _startPoint = [theEvent locationInWindow];
    _startFrame = _cropCoreView.frame;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint curPoint = [theEvent locationInWindow];

    CGFloat deltaX = curPoint.x - _startPoint.x;
    CGFloat deltaY = curPoint.y - _startPoint.y;

    CGFloat x = _startFrame.origin.x;
    CGFloat y = _startFrame.origin.y;
    CGFloat width = _startFrame.size.width;
    CGFloat height = _startFrame.size.height;

    switch (_dragType) {
        case New: {
            NSPoint newOrigin = [self convertPoint:_startPoint fromView:nil];
            x = newOrigin.x;
            y = newOrigin.y;
            width = deltaX;
            height = deltaY;
            break;
        }
        case Move: {
            x += deltaX;
            y += deltaY;
            break;
        }
        case Left: {
            x += deltaX;
            width -= deltaX;
            break;
        }
        case Right: {
            width += deltaX;
            break;
        }
        case Bottom: {
            y += deltaY;
            height -= deltaY;
            break;
        }
        case Top: {
            height += deltaY;
            break;
        }
        case CornerTL: {
            x += deltaX;
            width -= deltaX;
            height -= deltaX;
            break;
        }
        case CornerBL: {
            x += deltaX;
            y += deltaY;
            width -= deltaX;
            height -= deltaY;
            break;
        }
        case CornerBR: {
            y += deltaY;
            width += deltaX;
            height -= deltaY;
            break;
        }
        case CornerTR: {
            width += deltaX;
            height += deltaY;
            break;
        }
        default:
            break;
    }

    _cropCoreView.frame = NSMakeRect(x, y, width, height);
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [[NSCursor arrowCursor] set];
}

@end

#pragma mark -
#pragma mark Image Size
@implementation VMCropperImageView (ImageSize)

- (CGSize)imageScale
{
    CGFloat sx = self.frame.size.width / self.image.size.width;
    CGFloat sy = self.frame.size.height / self.image.size.height;
    CGFloat s = 1.0;
    switch (self.imageScaling) {
        case NSImageScaleProportionallyDown:
            s = fminf(fminf(sx, sy), 1);
            return CGSizeMake(s, s);
            break;

        case NSImageScaleProportionallyUpOrDown:
            s = fminf(sx, sy);
            return CGSizeMake(s, s);
            break;

        case NSImageScaleAxesIndependently:
            return CGSizeMake(sx, sy);

        default:
            return CGSizeMake(s, s);
    }
}

CGRect CGRectCenteredInCGRect(CGRect inner, CGRect outer)
{
    return CGRectMake((outer.size.width - inner.size.width) / 2.0, (outer.size.height - inner.size.height) / 2.0, inner.size.width, inner.size.height);
}

CGSize CGSizeScale(CGSize size, float scaleWidth, float scaleHeight)
{
    return CGSizeMake(size.width * scaleWidth, size.height * scaleHeight);
}

CGRect CGRectFromCGSize(CGSize size)
{
    return CGRectMake(0, 0, size.width, size.height);
}

- (CGRect)imageRect
{
    CGSize imgScale = [self imageScale];
    return CGRectCenteredInCGRect(CGRectFromCGSize(CGSizeScale(self.image.size, imgScale.width, imgScale.height)), self.frame);
}

@end
