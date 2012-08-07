//
//  NSBezierPath+AttributedStringExtensions.h
//  ThisService
//
//  Created by Jesper on 2012-07-24.
//  Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//
//

#import <Cocoa/Cocoa.h>
#import <CoreText/CoreText.h>

// Adapted from http://amber-framework.googlecode.com/ under the same license.

@interface NSBezierPath (AttributedStringExtensions)
+ (NSBezierPath *)bezierPathWithString:(NSString *)text inFont:(NSFont *)font;
- (void)appendBezierPathWithString:(NSString *)text inFont:(NSFont *)font;
@end
