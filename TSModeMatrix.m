//
//  TSModeMatrix.m
//  ThisService
//
//  Created by Jesper on 2007-08-04.
//  Copyright 2007-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import "TSModeMatrix.h"


@implementation TSModeMatrix

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self != nil) {
		lastTag = NSNotFound;
	}
	return self;
}

- (void)finishInitializing {
	[self selectCellWithTag:0];
	[self reconfigureWithAnimation:NO];
}

- (void)setContentInitialized {
	contentHasInitialized = YES;
	[self finishInitializing];
}

- (void)awakeFromNib {
	if (contentHasInitialized) return;
	[self finishInitializing];
}

- (void)goToTag:(int)tag {
	[self selectCellWithTag:tag];
	[self selectMe:[self cellWithTag:tag]];
}

- (void)selectMe:(id)sender {
	id dlx = [self delegate]; 
	//NSLog(@"do we have a delegate? %@; sender: %@", dlx, sender);
	if ([dlx respondsToSelector:@selector(modeMatrix:shouldSwitchFromTag:toTag:)]) {
		//NSLog(@"yes, and it responds to the selector");
		if (![dlx modeMatrix:self shouldSwitchFromTag:lastTag toTag:[self selectedTag]]) {
			//NSLog(@"it responded no. last tag: %d", lastTag);
			if ([self selectedTag] != lastTag) {
				[self selectCellWithTag:lastTag];
				[self selectMe:[self cellWithTag:lastTag]];	
			}
			return;
		}
	}
//	NSLog(@"go ahead");
	[self reconfigureWithAnimation:YES];
}

- (id<TSModeMatrixDelegate>)delegate {
	return (id<TSModeMatrixDelegate>)[super delegate];
}
- (void)reconfigureWithAnimation:(BOOL)anim {
	NSInteger previousTag = lastTag;
	lastTag = [self selectedTag];
//	NSLog(@"lastTag set to %llu; previousTag is %llu", (unsigned long long)lastTag, (unsigned long long)previousTag);
	NSInteger newTag = lastTag;
	
	[[self delegate] modeMatrix:self switchFromTag:previousTag toTag:newTag animate:anim];
}
@end
