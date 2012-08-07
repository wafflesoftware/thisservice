//
//  SRCommon.h (selected, extracted parts)
//  ShortcutRecorder
//
//  Copyright 2006-2007 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors (of these parts):
//      Jesper

#import <Cocoa/Cocoa.h>

// Image macros, for use in any bundle
//#define SRImage(name) [[[NSImage alloc] initWithContentsOfFile: [[NSBundle bundleForClass: [self class]] pathForImageResource: name]] autorelease]
#define SRResIndImage(name) [SRSharedImageProvider supportingImageWithName:name]
#define SRImage(name) SRResIndImage(name)

#pragma mark -
#pragma mark Image provider

@interface SRSharedImageProvider : NSObject
+ (NSImage *)supportingImageWithName:(NSString *)name;
@end
