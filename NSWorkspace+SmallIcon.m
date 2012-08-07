//
//  NSWorkspace+SmallIcon.m
//  ThisService
//
//  Created by Jesper on 2012-07-01.
//  Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//
//

#import "NSWorkspace+SmallIcon.h"

@implementation NSWorkspace (SmallIcon)
- (NSImage *)smallIconForFileAtPath:(NSString *)path {
    NSImage *icon = [[self iconForFile:path] copy];
    NSSize s16x16 = NSMakeSize(16, 16);
    [icon setSize:s16x16];
    
    // This category previously used to toss every non-16x16 icon since NSImage notoriously
    // would pick a larger image and scale it down instead of using a crisp exact icon.
    // With Retina displays, I can't keep doing that. It's not a problem to find the high-res/@2x
    // version of the 16x16 icon instead, but you might move the window to a low-res screen,
    // and the image can't magically contain the right icon at that time.
    
    // Maybe in the future, I will return an image with an NSCustomImageRep drawing the right image.
    
    return [icon autorelease];
}
@end
