//
//  TSDelegatingDropZoneView.h
//  ThisService
//
//  Created by Jesper on 2011-07-25.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Cocoa/Cocoa.h>


@interface TSDelegatingDropZoneView : NSView {
	BOOL drophovering;
	NSView *draggingDestination;
}
- (void)setDraggingDestination:(NSView *)draggingDestination;
- (NSView *)draggingDestination;
@end
