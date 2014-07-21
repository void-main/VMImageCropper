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
#define kCropWindowMinSize 8

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
        _cropCoreView.viewStatus = Normal;
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

- (NSImage *)croppedImage
{
    NSRect ratioRect = NSMakeRect((_cropCoreView.frame.origin.x - _actualRect.origin.x) / _actualRect.size.width,
                                  (_cropCoreView.frame.origin.y - _actualRect.origin.y) / _actualRect.size.height,
                                  _cropCoreView.frame.size.width / _actualRect.size.width,
                                  _cropCoreView.frame.size.height / _actualRect.size.height);

    NSRect actualRect = NSMakeRect(ratioRect.origin.x * self.image.size.width,
                                   ratioRect.origin.y * self.image.size.height,
                                   ratioRect.size.width * self.image.size.width,
                                   ratioRect.size.height * self.image.size.height);
    NSImage *cropped = [[NSImage alloc] initWithSize:actualRect.size];
    [cropped lockFocus];

    // Draw the cropped region
    [self.image drawInRect:NSMakeRect(0, 0, actualRect.size.width, actualRect.size.height) fromRect:actualRect operation:NSCompositeSourceOut fraction:1.0];

    [cropped unlockFocus];
    return cropped;
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

    if (NSPointInRect(_startPoint, _cropCoreView.frame)) {
        _cropCoreView.viewStatus = Dragging;
    }
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

            if (deltaX >= 0) {
                if (deltaY >= 0) {
                    x = newOrigin.x;
                    y = newOrigin.y;
                    width = fmaxf(deltaX, kCropWindowMinSize);
                    height = fmaxf(deltaY, kCropWindowMinSize);

                    if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                        width = _actualRect.origin.x + _actualRect.size.width - x;
                    }
                    if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                        height = _actualRect.origin.y + _actualRect.size.height - y;
                    }
                } else {
                    width = fmaxf(deltaX, kCropWindowMinSize);
                    height = fmaxf(-deltaY, kCropWindowMinSize);
                    x = newOrigin.x;
                    y = newOrigin.y - height;

                    if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                        width = _actualRect.origin.x + _actualRect.size.width - x;
                    }
                    if (y < _actualRect.origin.y) {
                        height += (y - _actualRect.origin.y);
                        y = _actualRect.origin.y;
                    }
                }
            } else {
                if (deltaY >= 0) {
                    width = fmaxf(-deltaX, kCropWindowMinSize);
                    height = fmaxf(deltaY, kCropWindowMinSize);
                    x = newOrigin.x - width;
                    y = newOrigin.y;

                    if (x < _actualRect.origin.x) {
                        width += (x - _actualRect.origin.x);
                        x = _actualRect.origin.x;
                    }
                    if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                        height = _actualRect.origin.y + _actualRect.size.height - y;
                    }
                } else {
                    width = fmaxf(-deltaX, kCropWindowMinSize);
                    height = fmaxf(-deltaY, kCropWindowMinSize);
                    x = newOrigin.x - width;
                    y = newOrigin.y - height;

                    if (x < _actualRect.origin.x) {
                        width += (x - _actualRect.origin.x);
                        x = _actualRect.origin.x;
                    }
                    if (y < _actualRect.origin.y) {
                        height += (y - _actualRect.origin.y);
                        y = _actualRect.origin.y;
                    }
                }
            }
            break;
        }
        case Move: {
            x += deltaX;
            y += deltaY;

            if (x < _actualRect.origin.x) {
                x = _actualRect.origin.x;
            }
            if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                x = _actualRect.origin.x + _actualRect.size.width - width;
            }
            if (y < _actualRect.origin.y) {
                y = _actualRect.origin.y;
            }
            if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                y = _actualRect.origin.y + _actualRect.size.height - height;
            }
            break;
        }
        case Left: {
            x += deltaX;
            width -= deltaX;

            if (width > 0) {
                if (x < _actualRect.origin.x) {
                    width += (x - _actualRect.origin.x);
                    x = _actualRect.origin.x;
                }
            } else {
                x += width;
                width = -width;
                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    width = _actualRect.origin.x + _actualRect.size.width - x;
                }
            }
            break;
        }
        case Right: {
            width += deltaX;

            if (width > 0) {
                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    width = _actualRect.origin.x + _actualRect.size.width - x;
                }
            } else {
                x += width;
                width = -width;
                if (x < _actualRect.origin.x) {
                    width += (x - _actualRect.origin.x);
                    x = _actualRect.origin.x;
                }
            }
            break;
        }
        case Bottom: {
            y += deltaY;
            height -= deltaY;

            if (height > 0) {
                if (y < _actualRect.origin.y) {
                    height += (y - _actualRect.origin.y);
                    y = _actualRect.origin.y;
                }
            } else {
                y += height;
                height = -height;
                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    height = _actualRect.origin.y + _actualRect.size.height - y;
                }
            }
            break;
        }
        case Top: {
            height += deltaY;

            if (height > 0) {
                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    height = _actualRect.origin.y + _actualRect.size.height - y;
                }
            } else {
                y += height;
                height = -height;
                if (y < _actualRect.origin.y) {
                    height += (y - _actualRect.origin.y);
                    y = _actualRect.origin.y;
                }
            }
            break;
        }
        case CornerTL: {
            x += deltaX;
            width -= deltaX;
            height += deltaY;

            if (width >= 0 && height >= 0) {
                if (x < _actualRect.origin.x) {
                    width += (x - _actualRect.origin.x);
                    x = _actualRect.origin.x;
                }
                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    height = _actualRect.origin.y + _actualRect.size.height - y;
                }
            } else if (width >= 0 && height < 0) {
                y += height;
                height = -height;

                if (x < _actualRect.origin.x) {
                    width += (x - _actualRect.origin.x);
                    x = _actualRect.origin.x;
                }
                if (y < _actualRect.origin.y) {
                    height += (y - _actualRect.origin.y);
                    y = _actualRect.origin.y;
                }
            } else if (width < 0 && height >= 0) {
                x += width;
                width = -width;

                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    width = _actualRect.origin.x + _actualRect.size.width - x;
                }
                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    height = _actualRect.origin.y + _actualRect.size.height - y;
                }
            } else {
                x += width;
                y += height;
                width = -width;
                height = -height;

                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    width = _actualRect.origin.x + _actualRect.size.width - x;
                }
                if (y < _actualRect.origin.y) {
                    height += (y - _actualRect.origin.y);
                    y = _actualRect.origin.y;
                }
            }

            break;
        }
        case CornerBL: {
            x += deltaX;
            y += deltaY;
            width -= deltaX;
            height -= deltaY;

            if (width >= 0 && height >= 0) {
                if (x < _actualRect.origin.x) {
                    width += (x - _actualRect.origin.x);
                    x = _actualRect.origin.x;
                }
                if (y < _actualRect.origin.y) {
                    height += (y - _actualRect.origin.y);
                    y = _actualRect.origin.y;
                }
            } else if (width >= 0 && height < 0) {
                y += height;
                height = -height;

                if (x < _actualRect.origin.x) {
                    width += (x - _actualRect.origin.x);
                    x = _actualRect.origin.x;
                }
                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    height = _actualRect.origin.y + _actualRect.size.height - y;
                }
            } else if (width < 0 && height >= 0) {
                x += width;
                width = -width;

                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    width = _actualRect.origin.x + _actualRect.size.width - x;
                }
                if (y < _actualRect.origin.y) {
                    height += (y - _actualRect.origin.y);
                    y = _actualRect.origin.y;
                }
            } else {
                x += width;
                y += height;
                width = -width;
                height = -height;

                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    width = _actualRect.origin.x + _actualRect.size.width - x;
                }
                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    height = _actualRect.origin.y + _actualRect.size.height - y;
                }
            }

            break;
        }
        case CornerBR: {
            y += deltaY;
            width += deltaX;
            height -= deltaY;

            if (width >= 0 && height >= 0) {
                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    width = _actualRect.origin.x + _actualRect.size.width - x;
                }
                if (y < _actualRect.origin.y) {
                    height += (y - _actualRect.origin.y);
                    y = _actualRect.origin.y;
                }
            } else if (width >= 0 && height < 0) {
                y += height;
                height = -height;

                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    width = _actualRect.origin.x + _actualRect.size.width - x;
                }
                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    height = _actualRect.origin.y + _actualRect.size.height - y;
                }
            } else if (width < 0 && height >= 0) {
                x += width;
                width = -width;

                if (x < _actualRect.origin.x) {
                    width += (x - _actualRect.origin.x);
                    x = _actualRect.origin.x;
                }
                if (y < _actualRect.origin.y) {
                    height += (y - _actualRect.origin.y);
                    y = _actualRect.origin.y;
                }
            } else {
                x += width;
                y += height;
                width = -width;
                height = -height;

                if (x < _actualRect.origin.x) {
                    width += (x - _actualRect.origin.x);
                    x = _actualRect.origin.x;
                }
                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    height = _actualRect.origin.y + _actualRect.size.height - y;
                }
            }

            break;
        }
        case CornerTR: {
            width += deltaX;
            height += deltaY;

            if (width >= 0 && height >= 0) {
                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    width = _actualRect.origin.x + _actualRect.size.width - x;
                }
                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    height = _actualRect.origin.y + _actualRect.size.height - y;
                }
            } else if (width >= 0 && height < 0) {
                y += height;
                height = -height;

                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    width = _actualRect.origin.x + _actualRect.size.width - x;
                }
                if (y < _actualRect.origin.y) {
                    height += (y - _actualRect.origin.y);
                    y = _actualRect.origin.y;
                }
            } else if (width < 0 && height >= 0) {
                x += width;
                width = -width;

                if (x < _actualRect.origin.x) {
                    width += (x - _actualRect.origin.x);
                    x = _actualRect.origin.x;
                }
                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    height = _actualRect.origin.y + _actualRect.size.height - y;
                }
            } else {
                x += width;
                y += height;
                width = -width;
                height = -height;

                if (x < _actualRect.origin.x) {
                    width += (x - _actualRect.origin.x);
                    x = _actualRect.origin.x;
                }
                if (y < _actualRect.origin.y) {
                    height += (y - _actualRect.origin.y);
                    y = _actualRect.origin.y;
                }
            }

            break;
        }
        default:
            break;
    }

    _cropCoreView.frame = NSMakeRect(x, y, width, height);
}

- (void)mouseUp:(NSEvent *)theEvent
{
    _cropCoreView.viewStatus = Normal;
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
