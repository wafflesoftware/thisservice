//
//  NSWorkspace+SmallIcon.h
//  ThisService
//
//  Created by Jesper on 2012-07-01.
//  Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//
//

#import <Cocoa/Cocoa.h>

@interface NSWorkspace (SmallIcon)
- (NSImage *)smallIconForFileAtPath:(NSString *)path;
@end
