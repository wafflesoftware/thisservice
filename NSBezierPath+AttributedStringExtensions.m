//
//  NSBezierPath+AttributedStringExtensions.m
//  ThisService
//
//  Created by Jesper on 2012-07-24.
//  Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//
//

#import "NSBezierPath+AttributedStringExtensions.h"

// Adapted from http://amber-framework.googlecode.com/ under the same license.

@implementation NSBezierPath (AttributedStringExtensions)

+ (NSBezierPath *)bezierPathWithString:(NSString *)text inFont:(NSFont *)font {
	NSBezierPath *textPath = [self bezierPath];
	[textPath appendBezierPathWithString:text inFont:font];
	return textPath;
}

- (void)appendBezierPathWithString:(NSString *)text inFont:(NSFont *)font {
	if ([self isEmpty]) [self moveToPoint:NSZeroPoint];
	
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text];
	CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attributedString);
	[attributedString release];
	
	CFArrayRef glyphRuns = CTLineGetGlyphRuns(line);
	CFIndex count = CFArrayGetCount(glyphRuns);
	
	for (CFIndex index = 0; index < count; index++) {
		CTRunRef currentRun = CFArrayGetValueAtIndex(glyphRuns, index);
		
		CFIndex glyphCount = CTRunGetGlyphCount(currentRun);
		
		CGGlyph glyphs[glyphCount];
		CTRunGetGlyphs(currentRun, CTRunGetStringRange(currentRun), glyphs);
		
		NSGlyph bezierPathGlyphs[glyphCount];
		for (CFIndex glyphIndex = 0; glyphIndex < glyphCount; glyphIndex++)
			bezierPathGlyphs[glyphIndex] = glyphs[glyphIndex];
		
		[self appendBezierPathWithGlyphs:bezierPathGlyphs count:glyphCount inFont:font];
	}
	
	CFRelease(line);
}
@end
