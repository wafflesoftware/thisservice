//
//  SRCommon.m (selected, extracted parts)
//  ShortcutRecorder
//
//  Copyright 2006-2007 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors (of these parts):
//      Jesper

#import "SRCommon.h"

static NSMutableDictionary *SRSharedImageCache = nil;

@interface SRSharedImageProvider (Private)
+ (void)_drawSRRemoveShortcut:(id)anNSCustomImageRep;
+ (NSValue *)_sizeSRRemoveShortcut;
+ (void)_drawSRRemoveShortcutRollover:(id)anNSCustomImageRep;
+ (NSValue *)_sizeSRRemoveShortcutRollover;
+ (void)_drawSRRemoveShortcutPressed:(id)anNSCustomImageRep;
+ (NSValue *)_sizeSRRemoveShortcutPressed;

+ (void)_drawARemoveShortcutBoxUsingRep:(id)anNSCustomImageRep opacity:(double)opacity;
@end

@implementation SRSharedImageProvider
+ (NSImage *)supportingImageWithName:(NSString *)name {
//	NSLog(@"supportingImageWithName: %@", name);
	if (nil == SRSharedImageCache) {
		SRSharedImageCache = [[NSMutableDictionary dictionary] retain];
//		NSLog(@"inited cache");
	}
	NSImage *cachedImage = nil;
	if (nil != (cachedImage = [SRSharedImageCache objectForKey:name])) {
//		NSLog(@"returned cached image: %@", cachedImage);
		return cachedImage;
	}
	
//	NSLog(@"constructing image");
	NSSize size;
	NSValue *sizeValue = [self performSelector:NSSelectorFromString([NSString stringWithFormat:@"_size%@", name])];
	size = [sizeValue sizeValue];
//	NSLog(@"size: %@", NSStringFromSize(size));
	
	NSCustomImageRep *customImageRep = [[NSCustomImageRep alloc] initWithDrawSelector:NSSelectorFromString([NSString stringWithFormat:@"_draw%@:", name]) delegate:self];
	[customImageRep setSize:size];
	[customImageRep setAlpha:YES];
//	NSLog(@"created customImageRep: %@", customImageRep);
	NSImage *returnImage = [[NSImage alloc] initWithSize:size];
	[returnImage addRepresentation:[customImageRep autorelease]];
	[returnImage setScalesWhenResized:YES];
	[SRSharedImageCache setObject:returnImage forKey:name];
	
//	NSLog(@"returned image: %@", returnImage);
	return [returnImage autorelease];
}
@end

@implementation SRSharedImageProvider (Private)

#define MakeRelativePoint(x,y)	NSMakePoint(x*hScale, y*vScale)

+ (NSValue *)_sizeSRRemoveShortcut {
	return [NSValue valueWithSize:NSMakeSize(14.0,14.0)];
}
+ (NSValue *)_sizeSRRemoveShortcutRollover { return [self _sizeSRRemoveShortcut]; }
+ (NSValue *)_sizeSRRemoveShortcutPressed { return [self _sizeSRRemoveShortcut]; }
+ (void)_drawARemoveShortcutBoxUsingRep:(id)anNSCustomImageRep opacity:(double)opacity {
	
//	NSLog(@"drawARemoveShortcutBoxUsingRep: %@ opacity: %f", anNSCustomImageRep, opacity);
	
	NSCustomImageRep *rep = anNSCustomImageRep;
	NSSize size = [rep size];
	[[NSColor colorWithCalibratedWhite:0.0 alpha:1-opacity] setFill];
	double hScale = (size.width/14.0);
	double vScale = (size.height/14.0);
	
	[[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0.0,0.0,size.width,size.height)] fill];
	
	[[NSColor whiteColor] setStroke];
	
	NSBezierPath *cross = [[NSBezierPath alloc] init];
	[cross setLineWidth:hScale*1.2];
	
	[cross moveToPoint:MakeRelativePoint(4,4)];
	[cross lineToPoint:MakeRelativePoint(10,10)];
	[cross moveToPoint:MakeRelativePoint(10,4)];
	[cross lineToPoint:MakeRelativePoint(4,10)];
		
	[cross stroke];
	
	[cross release];
}
+ (void)_drawSRRemoveShortcut:(id)anNSCustomImageRep {
	
//	NSLog(@"drawSRRemoveShortcut using: %@", anNSCustomImageRep);
	
	[self _drawARemoveShortcutBoxUsingRep:anNSCustomImageRep opacity:0.75];
}
+ (void)_drawSRRemoveShortcutRollover:(id)anNSCustomImageRep {
	
//	NSLog(@"drawSRRemoveShortcutRollover using: %@", anNSCustomImageRep);
	
	[self _drawARemoveShortcutBoxUsingRep:anNSCustomImageRep opacity:0.65];	
}
+ (void)_drawSRRemoveShortcutPressed:(id)anNSCustomImageRep {
	
//	NSLog(@"drawSRRemoveShortcutPressed using: %@", anNSCustomImageRep);
	
	[self _drawARemoveShortcutBoxUsingRep:anNSCustomImageRep opacity:0.55];
}
@end
