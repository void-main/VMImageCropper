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

@implementation VMCropConstraints

@synthesize description = _description;

- (void)setDescription:(NSString *)description
{
    [self willChangeValueForKey:@"description"];
    _description = description;
    [self didChangeValueForKey:@"description"];
}

- (NSString *)description
{
    if ([_description rangeOfString:@"$DIMEN"].location != NSNotFound) {
        NSString *dimen = [NSString stringWithFormat:@"%.0f × %.0f", self.width, self.height];
        return [_description stringByReplacingOccurrencesOfString:@"$DIMEN" withString:dimen];
    }
    return _description;
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        self.width = [[dictionary objectForKey:@"Width"] floatValue];
        self.height = [[dictionary objectForKey:@"Height"] floatValue];
        self.description = [dictionary objectForKey:@"Description"];
    }

    return self;
}

@end

@interface VMCropperImageView (ImageSize)

- (CGSize)imageScale;
- (CGRect)imageRect;

@end

@interface VMCropperImageView (Draggables)

- (NSInteger)sideLineIndexForX:(NSInteger)x y:(NSInteger)y;
- (NSInteger)crossAtX:(NSInteger)x y:(NSInteger)y;

@end

@implementation VMCropperImageView

@synthesize avaliableConstraints = _avaliableConstraints;
@synthesize currentConstraintIndex = _currentConstraintIndex;

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
#pragma mark Constraints
- (void)setConstraintsFilePath:(NSString *)filepath
{
    NSArray *extraConstraints = [NSArray arrayWithContentsOfFile:filepath];
    NSMutableArray *constraints = [[NSMutableArray alloc] initWithArray:[self builtInConstraints]];
    for (NSDictionary *constraintDict in extraConstraints) {
        VMCropConstraints *constraint = [[VMCropConstraints alloc] initWithDictionary:constraintDict];
        [constraints addObject:constraint];
    }

    self.avaliableConstraints = [constraints copy];;
    self.currentConstraintIndex = 0; // Reset to none
}

- (NSArray *)avaliableConstraints
{
    if (!_avaliableConstraints) {
        _avaliableConstraints = [self builtInConstraints];
    }
    return _avaliableConstraints;
}

- (void)setAvaliableConstraints:(NSArray *)avaliableConstraints
{
    [self willChangeValueForKey:@"avaliableConstraints"];
    _avaliableConstraints = avaliableConstraints;
    [self didChangeValueForKey:@"avaliableConstraints"];
}

- (NSUInteger)currentConstraintIndex
{
    return _currentConstraintIndex;
}

- (void)setCurrentConstraintIndex:(NSUInteger)currentConstraintIndex
{
    [self willChangeValueForKey:@"currentConstraintIndex"];
    _currentConstraintIndex = currentConstraintIndex;

    float imageAspect = self.image.size.width / self.image.size.height;
    VMCropConstraints *curConstraint = [self.avaliableConstraints objectAtIndex:currentConstraintIndex];
    float width = _actualRect.size.width;
    float height = _actualRect.size.height;
    if (curConstraint.width > 0 && curConstraint.height > 0) {
        float constraintAspect = curConstraint.width / curConstraint.height;
        if (imageAspect >= constraintAspect) {
            height = _actualRect.size.height;
            width = height * constraintAspect;
        } else {
            width = _actualRect.size.width;
            height = width / constraintAspect;
        }
    }
    _cropCoreView.frame = NSMakeRect(_actualRect.origin.x + (_actualRect.size.width - width) * 0.5,
                                     _actualRect.origin.y + (_actualRect.size.height - height) * 0.5,
                                     width,
                                     height);

    [self didChangeValueForKey:@"currentConstraintIndex"];
}

- (NSArray *)builtInConstraints {
    NSMutableArray *builtInConstraints = [[NSMutableArray alloc] init];
    VMCropConstraints *noneConstraints = [[VMCropConstraints alloc] init];
    noneConstraints.description = @"None";
    noneConstraints.width = -1;
    noneConstraints.height = -1;
    [builtInConstraints addObject:noneConstraints];

    VMCropConstraints *originSize = [[VMCropConstraints alloc] init];
    originSize.description = @"$DIMEN (Original Size)";
    originSize.width = self.image.size.width;
    originSize.height = self.image.size.height;
    [builtInConstraints addObject:originSize];

    VMCropConstraints *resolutionConstraints = [[VMCropConstraints alloc] init];
    NSScreen *mainScreen = [NSScreen mainScreen];
    resolutionConstraints.description = @"$DIMEN (Screen Resolution)";
    resolutionConstraints.width = mainScreen.frame.size.width;
    resolutionConstraints.height = mainScreen.frame.size.height;
    [builtInConstraints addObject:resolutionConstraints];

    return [builtInConstraints copy];
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

    _cropCoreView.viewStatus = Dragging;

    [self.window disableCursorRects];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint curPoint = [theEvent locationInWindow];

    CGFloat deltaX = curPoint.x - _startPoint.x;
    CGFloat deltaY = curPoint.y - _startPoint.y;

    VMCropConstraints *curCrop = [self.avaliableConstraints objectAtIndex:self.currentConstraintIndex];
    float aspectRatio = -1;
    if (curCrop.width > 0 && curCrop.height > 0) {
        aspectRatio = curCrop.width / curCrop.height;
    }

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

                    if (aspectRatio > 0) {
                        float curAspectRatio = width / height;
                        if (curAspectRatio >= aspectRatio) {
                            height = width / aspectRatio;
                        } else {
                            width = height * aspectRatio;
                        }
                    }

                    if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                        width = _actualRect.origin.x + _actualRect.size.width - x;

                        if (aspectRatio > 0) {
                            height = width / aspectRatio;
                        }
                    }
                    if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                        height = _actualRect.origin.y + _actualRect.size.height - y;

                        if (aspectRatio > 0) {
                            width = height * aspectRatio;
                        }
                    }
                } else {
                    width = fmaxf(deltaX, kCropWindowMinSize);
                    height = fmaxf(-deltaY, kCropWindowMinSize);

                    if (aspectRatio > 0) {
                        float curAspectRatio = width / height;
                        if (curAspectRatio >= aspectRatio) {
                            height = width / aspectRatio;
                        } else {
                            width = height * aspectRatio;
                        }
                    }

                    x = newOrigin.x;
                    y = newOrigin.y - height;

                    if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                        width = _actualRect.origin.x + _actualRect.size.width - x;
                        if (aspectRatio > 0) {
                            height = width / aspectRatio;
                            y = newOrigin.y - height;
                        }
                    }
                    if (y < _actualRect.origin.y) {
                        height += (y - _actualRect.origin.y);
                        if (aspectRatio > 0) {
                            width = height * aspectRatio;
                        }
                        y = _actualRect.origin.y;
                    }
                }
            } else {
                if (deltaY >= 0) {
                    width = fmaxf(-deltaX, kCropWindowMinSize);
                    height = fmaxf(deltaY, kCropWindowMinSize);

                    if (aspectRatio > 0) {
                        float curAspectRatio = width / height;
                        if (curAspectRatio >= aspectRatio) {
                            height = width / aspectRatio;
                        } else {
                            width = height * aspectRatio;
                        }
                    }

                    x = newOrigin.x - width;
                    y = newOrigin.y;

                    if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                        height = _actualRect.origin.y + _actualRect.size.height - y;

                        if (aspectRatio > 0) {
                            width = height * aspectRatio;
                            x = newOrigin.x - width;
                        }
                    }
                    if (x < _actualRect.origin.x) {
                        width += (x - _actualRect.origin.x);

                        if (aspectRatio > 0) {
                            height = width / aspectRatio;
                        }

                        x = _actualRect.origin.x;
                    }
                } else {
                    width = fmaxf(-deltaX, kCropWindowMinSize);
                    height = fmaxf(-deltaY, kCropWindowMinSize);

                    if (aspectRatio > 0) {
                        float curAspectRatio = width / height;
                        if (curAspectRatio >= aspectRatio) {
                            height = width / aspectRatio;
                        } else {
                            width = height * aspectRatio;
                        }
                    }

                    x = newOrigin.x - width;
                    y = newOrigin.y - height;

                    if (x < _actualRect.origin.x) {
                        width += (x - _actualRect.origin.x);
                        x = _actualRect.origin.x;

                        if (aspectRatio > 0) {
                            height = width / aspectRatio;
                            y = newOrigin.y - height;
                        }
                    }
                    if (y < _actualRect.origin.y) {
                        height += (y - _actualRect.origin.y);
                        y = _actualRect.origin.y;

                        if (aspectRatio > 0) {
                            width = height * aspectRatio;
                            x = newOrigin.x - width;
                        }
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
            float heightDiff = 0;

            if (width > 0) {
                if (aspectRatio > 0) {
                    heightDiff = width / aspectRatio - height;
                    height = width / aspectRatio;
                    y -= heightDiff * 0.5;
                }

                if (x < _actualRect.origin.x) {
                    width += (x - _actualRect.origin.x);
                    if (aspectRatio > 0) {
                        heightDiff = width / aspectRatio - height;
                        height = width / aspectRatio;
                        y -= heightDiff * 0.5;
                    }
                    x = _actualRect.origin.x;
                }

                if (y < _actualRect.origin.y) {
                    if (aspectRatio > 0) {
                        float diff = _actualRect.origin.y - y;
                        y = _actualRect.origin.y;
                        height -= 2 * diff;
                        width -= 2 * diff / aspectRatio;
                        x += 2 * diff;
                    }
                }
                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    if (aspectRatio > 0) {
                        float diff = y - (_actualRect.origin.y + _actualRect.size.height - height);
                        height -= 2 * diff;
                        width -= 2 * diff / aspectRatio;
                        x += 2 *diff;
                        y = _actualRect.origin.y + _actualRect.size.height - height;
                    }
                }
            } else {
                x += width;
                width = -width;

                if (aspectRatio > 0) {
                    heightDiff = width / aspectRatio - height;
                    height = width / aspectRatio;
                    y -= heightDiff * 0.5;
                }

                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    width = _actualRect.origin.x + _actualRect.size.width - x;

                    if (aspectRatio > 0) {
                        heightDiff = width / aspectRatio - height;
                        height = width / aspectRatio;
                        y -= heightDiff * 0.5;
                    }
                }

                if (y < _actualRect.origin.y) {
                    if (aspectRatio > 0) {
                        float diff = _actualRect.origin.y - y;
                        y = _actualRect.origin.y;
                        height -= 2 * diff;
                        width -= 2 * diff / aspectRatio;
                    }
                }
                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    if (aspectRatio > 0) {
                        float diff = y - (_actualRect.origin.y + _actualRect.size.height - height);
                        height -= 2 * diff;
                        width -= 2 * diff / aspectRatio;
                        y = _actualRect.origin.y + _actualRect.size.height - height;
                    }
                }
            }
            break;
        }
        case Right: {
            width += deltaX;
            float heightDiff = 0;

            if (width > 0) {
                if (aspectRatio > 0) {
                    heightDiff = width / aspectRatio - height;
                    height = width / aspectRatio;
                    y -= heightDiff * 0.5;
                }

                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    width = _actualRect.origin.x + _actualRect.size.width - x;

                    if (aspectRatio > 0) {
                        heightDiff = width / aspectRatio - height;
                        height = width / aspectRatio;
                        y -= heightDiff * 0.5;
                    }
                }

                if (y < _actualRect.origin.y) {
                    if (aspectRatio > 0) {
                        float diff = _actualRect.origin.y - y;
                        y = _actualRect.origin.y;
                        height -= 2 * diff;
                        width -= 2 * diff / aspectRatio;
                    }
                }
                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    if (aspectRatio > 0) {
                        float diff = y - (_actualRect.origin.y + _actualRect.size.height - height);
                        height -= 2 * diff;
                        width -= 2 * diff / aspectRatio;
                        y = _actualRect.origin.y + _actualRect.size.height - height;
                    }
                }
            } else {
                x += width;
                width = -width;

                if (aspectRatio > 0) {
                    heightDiff = width / aspectRatio - height;
                    height = width / aspectRatio;
                    y -= heightDiff * 0.5;
                }

                if (x < _actualRect.origin.x) {
                    width += (x - _actualRect.origin.x);
                    if (aspectRatio > 0) {
                        heightDiff = width / aspectRatio - height;
                        height = width / aspectRatio;
                        y -= heightDiff * 0.5;
                    }
                    x = _actualRect.origin.x;
                }

                if (y < _actualRect.origin.y) {
                    if (aspectRatio > 0) {
                        float diff = _actualRect.origin.y - y;
                        y = _actualRect.origin.y;
                        height -= 2 * diff;
                        width -= 2 * diff / aspectRatio;
                        x += 2 * diff;
                    }
                }
                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    if (aspectRatio > 0) {
                        float diff = y - (_actualRect.origin.y + _actualRect.size.height - height);
                        height -= 2 * diff;
                        width -= 2 * diff / aspectRatio;
                        x += 2 *diff;
                        y = _actualRect.origin.y + _actualRect.size.height - height;
                    }
                }
            }
            break;
        }
        case Bottom: {
            y += deltaY;
            height -= deltaY;
            float widthDiff = 0;

            if (height > 0) {
                if (aspectRatio > 0) {
                    widthDiff = height * aspectRatio - width;
                    width = height * aspectRatio;
                    x -= widthDiff * 0.5;
                }

                if (y < _actualRect.origin.y) {
                    height += (y - _actualRect.origin.y);

                    if (aspectRatio > 0) {
                        widthDiff = height * aspectRatio - width;
                        width = height * aspectRatio;
                        x -= widthDiff * 0.5;
                    }

                    y = _actualRect.origin.y;
                }

                if (x < _actualRect.origin.x) {
                    if (aspectRatio > 0) {
                        float diff = _actualRect.origin.x - x;
                        x = _actualRect.origin.x;
                        width -= 2 * diff;
                        height -= 2 * diff * aspectRatio;
                        y += 2 * diff;
                    }
                }
                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    if (aspectRatio > 0) {
                        float diff = x - (_actualRect.origin.x + _actualRect.size.width - width);
                        width -= 2 * diff;
                        height -= 2 * diff * aspectRatio;
                        y += 2 *diff;
                        x = _actualRect.origin.x + _actualRect.size.width - width;
                    }
                }
            } else {
                y += height;
                height = -height;

                if (aspectRatio > 0) {
                    widthDiff = height * aspectRatio - width;
                    width = height * aspectRatio;
                    x -= widthDiff * 0.5;
                }

                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    height = _actualRect.origin.y + _actualRect.size.height - y;

                    if (aspectRatio > 0) {
                        widthDiff = height * aspectRatio - width;
                        width = height * aspectRatio;
                        x -= widthDiff * 0.5;
                    }
                }

                if (x < _actualRect.origin.x) {
                    if (aspectRatio > 0) {
                        float diff = _actualRect.origin.x - x;
                        x = _actualRect.origin.x;
                        width -= 2 * diff;
                        height -= 2 * diff * aspectRatio;
                    }
                }
                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    if (aspectRatio > 0) {
                        float diff = x - (_actualRect.origin.x + _actualRect.size.width - width);
                        width -= 2 * diff;
                        height -= 2 * diff * aspectRatio;
                        x = _actualRect.origin.x + _actualRect.size.width - width;
                    }
                }
            }
            break;
        }
        case Top: {
            height += deltaY;
            float widthDiff = 0;

            if (height > 0) {
                if (aspectRatio > 0) {
                    widthDiff = height * aspectRatio - width;
                    width = height * aspectRatio;
                    x -= widthDiff * 0.5;
                }

                if (y + height > _actualRect.origin.y + _actualRect.size.height) {
                    height = _actualRect.origin.y + _actualRect.size.height - y;

                    if (aspectRatio > 0) {
                        widthDiff = height * aspectRatio - width;
                        width = height * aspectRatio;
                        x -= widthDiff * 0.5;
                    }
                }

                if (x < _actualRect.origin.x) {
                    if (aspectRatio > 0) {
                        float diff = _actualRect.origin.x - x;
                        x = _actualRect.origin.x;
                        width -= 2 * diff;
                        height -= 2 * diff * aspectRatio;
                    }
                }
                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    if (aspectRatio > 0) {
                        float diff = x - (_actualRect.origin.x + _actualRect.size.width - width);
                        width -= 2 * diff;
                        height -= 2 * diff * aspectRatio;
                        x = _actualRect.origin.x + _actualRect.size.width - width;
                    }
                }
            } else {
                y += height;
                height = -height;
                if (aspectRatio > 0) {
                    widthDiff = height * aspectRatio - width;
                    width = height * aspectRatio;
                    x -= widthDiff * 0.5;
                }

                if (y < _actualRect.origin.y) {
                    height += (y - _actualRect.origin.y);

                    if (aspectRatio > 0) {
                        widthDiff = height * aspectRatio - width;
                        width = height * aspectRatio;
                        x -= widthDiff * 0.5;
                    }

                    y = _actualRect.origin.y;
                }

                if (x < _actualRect.origin.x) {
                    if (aspectRatio > 0) {
                        float diff = _actualRect.origin.x - x;
                        x = _actualRect.origin.x;
                        width -= 2 * diff;
                        height -= 2 * diff * aspectRatio;
                        y += 2 * diff;
                    }
                }
                if (x + width > _actualRect.origin.x + _actualRect.size.width) {
                    if (aspectRatio > 0) {
                        float diff = x - (_actualRect.origin.x + _actualRect.size.width - width);
                        width -= 2 * diff;
                        height -= 2 * diff * aspectRatio;
                        y += 2 *diff;
                        x = _actualRect.origin.x + _actualRect.size.width - width;
                    }
                }
            }
            break;
        }
        case CornerTL: { // Origin is BR
            NSPoint newOrigin = NSMakePoint(_cropCoreView.frame.origin.x + _cropCoreView.frame.size.width, _cropCoreView.frame.origin.y);
            _startPoint = [self convertPoint:newOrigin toView:nil];
            _dragType = New;
            break;
        }
        case CornerBL: { // Origin is TR
            NSPoint newOrigin = NSMakePoint(_cropCoreView.frame.origin.x + _cropCoreView.frame.size.width, _cropCoreView.frame.origin.y + _cropCoreView.frame.size.height);
            _startPoint = [self convertPoint:newOrigin toView:nil];
            _dragType = New;
            break;
        }
        case CornerBR: { // Origin is TL
            NSPoint newOrigin = NSMakePoint(_cropCoreView.frame.origin.x, _cropCoreView.frame.origin.y + _cropCoreView.frame.size.height);
            _startPoint = [self convertPoint:newOrigin toView:nil];
            _dragType = New;
            break;
        }
        case CornerTR: { // Origin is BL
            NSPoint newOrigin = NSMakePoint(_cropCoreView.frame.origin.x, _cropCoreView.frame.origin.y);
            _startPoint = [self convertPoint:newOrigin toView:nil];
            _dragType = New;
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

    [self.window enableCursorRects];
    [self.window resetCursorRects];
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
