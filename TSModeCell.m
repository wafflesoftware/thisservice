//
//  TSModeTabView.m
//  ThisService
//
//  Created by Jesper on 2007-08-03.
//  Copyright 2007-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import "TSModeCell.h"

#import "NSBezierPath+AttributedStringExtensions.h"

@implementation TSModeCell

- (NSRect)drawingRectForBounds:(NSRect)theRect {
	return theRect;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
//	NSLog(@"Told to draw with frame: %@ in view %@", NSStringFromRect(cellFrame), controlView);	

	BOOL flipped = [controlView isFlipped];
	NSRect insideRect; NSRect borderRect;
	NSDivideRect(cellFrame,&borderRect,&insideRect,1.0,(flipped ? NSMaxYEdge : NSMinYEdge));
	[self drawInteriorWithFrame:insideRect inView:controlView];
	[[[[NSColor shadowColor] highlightWithLevel:0.55] colorWithAlphaComponent:0.5] set];
	NSRectFill(borderRect);
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    
    static NSGradient *unselectedGradient = nil;
    static NSGradient *unselectedTextGradient = nil;
    static NSShadow *unselectedTextShadow = nil;
    static NSGradient *selectedGradient = nil;
    static NSGradient *selectedTextGradient = nil;
    static NSShadow *selectedTextShadow = nil;
    static NSGradient *selectedSpotlightGradient = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        unselectedGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.733 alpha:1.000]
                                                                       endingColor:[NSColor colorWithCalibratedWhite:0.529 alpha:1.000]];
        unselectedTextGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.270 alpha:1.000]
                                                                           endingColor:[NSColor colorWithCalibratedWhite:0.127 alpha:1.000]];
        unselectedTextShadow = [[NSShadow alloc] init];
        [unselectedTextShadow setShadowBlurRadius:0];
        [unselectedTextShadow setShadowOffset:NSMakeSize(0, -0.75)];
        [unselectedTextShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.8 alpha:1]];
        
        selectedGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.478 alpha:1.000]
                                                                     endingColor:[NSColor colorWithCalibratedWhite:0.320 alpha:1.000]];
        selectedTextGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.794 alpha:1.000]
                                                                         endingColor:[NSColor colorWithCalibratedWhite:0.957 alpha:1.000]];
        selectedTextShadow = [[NSShadow alloc] init];
        [selectedTextShadow setShadowBlurRadius:3.5];
        [selectedTextShadow setShadowOffset:NSMakeSize(0, -0.5)];
        [selectedTextShadow setShadowColor:[NSColor colorWithCalibratedWhite:0 alpha:0.6]];
        
        selectedSpotlightGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:1 alpha:0.03] endingColor:[NSColor colorWithCalibratedWhite:1 alpha:0]];

    });
    
        
    NSGradient *backgroundGradient = unselectedGradient;
    NSGradient *textGradient = unselectedTextGradient;
    NSShadow *textShadow = unselectedTextShadow;
    NSGradient *backgroundSpotlightGradient = nil;
    
	BOOL flipped = [controlView isFlipped];
	BOOL selected = [self state] == NSOnState;
	BOOL highlighted = [self isHighlighted];
	if (selected || highlighted) {
		backgroundGradient = selectedGradient;
        textGradient = selectedTextGradient;
        textShadow = selectedTextShadow;
        if (selected) {
            backgroundSpotlightGradient = selectedSpotlightGradient;
        }
	}
	
	int angle = (flipped ? (selected ? 270 : 90) : (selected ? 90 : 270));
	
	[backgroundGradient drawInRect:cellFrame angle:angle];
    
    if (backgroundSpotlightGradient) {
        [backgroundSpotlightGradient drawInRect:cellFrame relativeCenterPosition:NSMakePoint(0, 0.5)];
    }

    
    NSString *title = [self title];
    NSFont *font = [self font];
        
	NSRect attrRect = [self titleRectForBounds:cellFrame];
    
    NSAffineTransform *unflip = [NSAffineTransform transform];
    if (flipped) {
        [unflip translateXBy:0.0 yBy:cellFrame.size.height];
        [unflip scaleXBy:1 yBy:-1];
    }
    
    CGFloat yNudge = 3;
    
    NSAffineTransform *moveToPosition = [NSAffineTransform transform];
    [moveToPosition translateXBy:attrRect.origin.x yBy:(flipped ? attrRect.size.height - (attrRect.origin.y - yNudge) : attrRect.origin.y - yNudge)];
    
    NSBezierPath *bezierPathOfGlyphs = [NSBezierPath bezierPathWithString:title inFont:font];
    [bezierPathOfGlyphs transformUsingAffineTransform:moveToPosition];
    [bezierPathOfGlyphs transformUsingAffineTransform:unflip];

    [[NSGraphicsContext currentContext] saveGraphicsState];
    [textShadow set];
    [[textGradient interpolatedColorAtLocation:0.5] setFill];
    [bezierPathOfGlyphs fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];

    [textGradient drawInBezierPath:bezierPathOfGlyphs angle:-90];
	
	if (![self isEnabled]) {
		[[[NSColor grayColor] colorWithAlphaComponent:0.25] setFill];
		[NSBezierPath fillRect:cellFrame];
	}
    
}

- (NSRect)titleRectForBounds:(NSRect)bounds {
	NSAttributedString *attr = [self attributedTitle];
	NSSize size = [attr size];
	NSRect rect = NSMakeRect(NSMinX(bounds)+(bounds.size.width-size.width)/2.0,NSMinY(bounds)+(bounds.size.height-size.height)/2.0,size.width,size.height);
	rect = NSOffsetRect(rect,0.0,(size.height*0.05));
	return rect;
}
@end