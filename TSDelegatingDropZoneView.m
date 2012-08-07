//
//  TSDelegatingDropZoneView.m
//  ThisService
//
//  Created by Jesper on 2011-07-25.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import "TSDelegatingDropZoneView.h"


@implementation TSDelegatingDropZoneView


- (void)setDraggingDestination:(NSView *)aDraggingDestination {
	[self unregisterDraggedTypes];
	draggingDestination = aDraggingDestination;
	[self registerForDraggedTypes:[draggingDestination registeredDraggedTypes]];
}

- (NSView *)draggingDestination {
	return draggingDestination;
}

- (void)setDropHovering:(BOOL)dh {
	if (dh != drophovering) {
		drophovering = dh;
		[self setNeedsDisplay:YES];
	}
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	NSDragOperation operation = [draggingDestination draggingEntered:sender];
	[self setDropHovering:(operation != NSDragOperationNone)];
	return operation;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	NSDragOperation operation = [draggingDestination draggingUpdated:sender];
	[self setDropHovering:(operation != NSDragOperationNone)];
	return operation;	
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {
    if ([draggingDestination respondsToSelector:@selector(draggingEnded:)]) {
        [draggingDestination draggingEnded:sender];
    }
	[self setDropHovering:NO];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	[draggingDestination draggingExited:sender];
	[self setDropHovering:NO];	
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	BOOL result = [draggingDestination performDragOperation:sender];
	[self setDropHovering:result];
	return result;
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender {
	BOOL result = [draggingDestination prepareForDragOperation:sender];
	[self setDropHovering:result];
	return result;
}

- (BOOL)wantsPeriodicDraggingUpdates {
	return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	[draggingDestination concludeDragOperation:sender];
	[self setDropHovering:NO];
}

- (BOOL)isOpaque {
	return NO;
}

- (void)drawRect:(NSRect)rect {
	if (drophovering) {
		if (!NSEqualSizes(rect.size,[self frame].size)) {
			[self setNeedsDisplay:YES];
			return;
		}
		[[NSColor selectedControlColor] setStroke];
	} else {
		[[NSColor clearColor] setStroke];
	}
	[NSBezierPath strokeRect:rect];
	[NSBezierPath strokeRect:NSInsetRect(rect,1.0,1.0)];
}

@end
