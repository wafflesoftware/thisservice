//
//  TSModeMatrix.h
//  ThisService
//
//  Created by Jesper on 2007-08-04.
//  Copyright 2007-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Cocoa/Cocoa.h>

@class TSModeMatrix;

@protocol TSModeMatrixDelegate <NSMatrixDelegate>
- (BOOL)modeMatrix:(TSModeMatrix *)matrix shouldSwitchFromTag:(NSInteger)previousTag toTag:(NSInteger)newTag;
- (void)modeMatrix:(TSModeMatrix *)matrix switchFromTag:(NSInteger)previousTag toTag:(NSInteger)newTag animate:(BOOL)animate;
@end

@interface TSModeMatrix : NSMatrix {
	double baseHeight;
	double bottomHeight;
	NSInteger lastTag;
	BOOL contentHasInitialized;
	
	BOOL animationIsBlocked;
}
- (IBAction)selectMe:(id)sender;
- (void)goToTag:(int)tag;
- (void)reconfigureWithAnimation:(BOOL)anim;
- (id<TSModeMatrixDelegate>)delegate;
- (void)setContentInitialized;
@end

