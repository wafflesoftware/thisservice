//
//  TSWindowController.m
//  ThisService
//
//  Created by Jesper on 2011-07-11.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import "TSWindowController.h"
#import "TSViewController.h"

#import "TSCreateServiceViewController.h"
#import "TSPackUpViewController.h"

#import "TSModeMatrix.h"

#import "TSService.h"

@implementation TSWindowController

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
	return YES;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication {
	[[self window] makeKeyAndOrderFront:self];
	return YES;
}


- (void)awakeFromNib {
	NSArray *viewControllerClasses = [NSArray arrayWithObjects:[TSCreateServiceViewController class], [TSPackUpViewController class], nil];
	NSMutableArray *newViewControllers = [NSMutableArray arrayWithCapacity:[viewControllerClasses count]];
	for (Class cls in viewControllerClasses) {
		NSString *str = NSStringFromClass(cls);
		TSViewController *vc = [[cls alloc] initWithNibName:str bundle:nil];
		[newViewControllers addObject:[vc autorelease]];
	}
	
	viewControllers = [newViewControllers copy];
	
	[modeMatrix setContentInitialized];
}


- (TSViewController *)viewControllerForTag:(NSInteger)tag {
	if (tag == NSNotFound)
		return nil;
	
	TSViewController *viewController = (TSViewController *)[viewControllers objectAtIndex:tag];
	return viewController;
}

- (BOOL)modeMatrix:(TSModeMatrix *)matrix shouldSwitchFromTag:(NSInteger)previousTag toTag:(NSInteger)newTag {
	TSViewController *goingViewController = [self viewControllerForTag:previousTag];
	TSViewController *becomingViewController = [self viewControllerForTag:newTag];
	
	if (goingViewController == nil) return YES;
	
	if ([becomingViewController isEqual:goingViewController]) return NO;
	
	BOOL okay = [becomingViewController shouldSwitchToViewController:becomingViewController];
	
	return okay;
}

- (NSSize)contentViewSizeForViewWithSize:(NSSize)viewSize {
	CGFloat heightOfModeMatrix = [modeMatrix frame].size.height;
	
	return NSMakeSize(viewSize.width, viewSize.height + heightOfModeMatrix);
}

- (NSSize)contentViewSizeForView:(NSView *)view {
    return [self contentViewSizeForViewWithSize:[view frame].size];
}

- (NSRect)frameRectForModeMatrixGivenView:(NSView *)view {
	NSSize sizeContentView = [self contentViewSizeForView:view];
	CGFloat heightOfModeMatrix = [modeMatrix frame].size.height;
	
	return NSMakeRect(0, sizeContentView.height - heightOfModeMatrix, sizeContentView.width, heightOfModeMatrix);
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification {
	TSViewController *vc = [self viewControllerForTag:[modeMatrix selectedTag]];
	if (nil == vc) return;
	[vc viewWillAppearInContainer:self];
}

- (void)resizeViewController:(TSViewController *)vc toNewContentSize:(NSSize)size animate:(BOOL)animate {
    
    NSWindow *w = [self window];
    
    NSView *refreshingView = vc.view;
    
	NSView *contentView = [w contentView];
	
	NSSize newContentViewSize = [self contentViewSizeForViewWithSize:size];
	NSSize oldContentViewSize = [contentView frame].size;
	
	CGFloat diffBetweenSize = newContentViewSize.height - oldContentViewSize.height;
	
    NSRect newViewFrameRect = [refreshingView frame];
    newViewFrameRect.size = size;
    
	NSRect windowRect = [w frame];
	
	NSRect newFrameRect = [w frameRectForContentRect:NSMakeRect(windowRect.origin.x, windowRect.origin.y - diffBetweenSize, newContentViewSize.width, newContentViewSize.height)];
	
	NSSize contentSizeOfBecomingView = [refreshingView frame].size;
	[refreshingView setFrame:NSMakeRect(0, 0, contentSizeOfBecomingView.width, contentSizeOfBecomingView.height)];
	
    [subviewView setAutoresizesSubviews:YES];
    
	if (animate) {
        
		if (currentAnimation) {
			[currentAnimation stopAnimation];
		}
		
		NSViewAnimation *anim = [[NSViewAnimation alloc] initWithViewAnimations:
								 [NSArray arrayWithObjects:
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   w, NSViewAnimationTargetKey,
								   [NSValue valueWithRect:newFrameRect], NSViewAnimationEndFrameKey,
								   nil],
								  nil]
								 ];
        [anim setDelegate:self];
        [anim setDuration:[[self window] animationResizeTime:newFrameRect]*0.85];
		[anim startAnimation];
		currentAnimation = anim;
		
	} else {
		
		[w setFrame:newFrameRect display:YES];
	}
    
}

- (void)modeMatrix:(TSModeMatrix *)matrix switchFromTag:(NSInteger)previousTag toTag:(NSInteger)newTag animate:(BOOL)animate {
	TSViewController *goingViewController = [self viewControllerForTag:previousTag];
	TSViewController *becomingViewController = [self viewControllerForTag:newTag];
	
	if (!goingViewController && !becomingViewController) return;
	
	NSView *goingView = [goingViewController view];
	NSView *becomingView = [becomingViewController view];
	
	NSWindow *w = [self window];
	NSView *contentView = [w contentView];
	
	NSSize newContentViewSize = [self contentViewSizeForView:becomingView];
	NSSize oldContentViewSize = [contentView frame].size;
	
	CGFloat diffBetweenSize = newContentViewSize.height - oldContentViewSize.height;
	
	NSRect windowRect = [w frame];
	
	NSRect newFrameRect = [w frameRectForContentRect:NSMakeRect(windowRect.origin.x, windowRect.origin.y - diffBetweenSize, newContentViewSize.width, newContentViewSize.height)];
	
	NSSize contentSizeOfBecomingView = [becomingView frame].size;
	[becomingView setFrame:NSMakeRect(0, 0, contentSizeOfBecomingView.width, contentSizeOfBecomingView.height)];
	[subviewView addSubview:becomingView positioned:NSWindowBelow relativeTo:modeMatrix];

    [subviewView setAutoresizesSubviews:NO];
	
	[becomingViewController viewWillAppearInContainer:self];
	
	if (animate) {
	
		if (currentAnimation) {
			[currentAnimation stopAnimation];
		}
		
		NSViewAnimation *anim = [[NSViewAnimation alloc] initWithViewAnimations:
								 [NSArray arrayWithObjects:
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   goingView, NSViewAnimationTargetKey,
								   NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
								   nil],
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   becomingView, NSViewAnimationTargetKey,
								   NSViewAnimationFadeInEffect, NSViewAnimationEffectKey,
								   nil],
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   w, NSViewAnimationTargetKey,
								   [NSValue valueWithRect:newFrameRect], NSViewAnimationEndFrameKey,
								   nil],							  
								  nil]
								 ];
        [anim setDelegate:self];
        [anim setDuration:[[self window] animationResizeTime:newFrameRect]];
		[anim startAnimation];
		currentAnimation = anim;
		
	} else {
		
		[w setFrame:newFrameRect display:YES];
		if (goingView != becomingView) {
			[goingView setHidden:YES];
		}
		[becomingView setHidden:NO];
	}
	
	
/*	This is the code I would have liked to have used.
	It starts to animate and then falls apart in spectacular ways,
	including logging "unlockFocus called too many time." [sic].
	The internet tells me to balance my NSGraphicsContext saves and restores,
	of which I have none.
 
#define ANIMATE_IF_NEEDED(x)	(animate ? ([x animator]) : x)
 
	[becomingView setAlphaValue:0.0];
	[becomingView setHidden:NO];
	[goingView setAlphaValue:1.0];
 
	[ANIMATE_IF_NEEDED(w) setFrame:newFrameRect display:YES];
	if (goingView != becomingView) {
		[ANIMATE_IF_NEEDED(goingView) setAlphaValue:0.0];
		[ANIMATE_IF_NEEDED(goingView) setHidden:YES];
	}
	[ANIMATE_IF_NEEDED(becomingView) setAlphaValue:1.0];
	[ANIMATE_IF_NEEDED(becomingView) setHidden:NO];*/
	
    if (becomingViewController != goingViewController) {
        [goingViewController viewWillDisappear];
    }
	
}

-(void)animationDidEnd:(NSAnimation *)animation {
    [animation autorelease];
    if (animation != currentAnimation) return;
    currentAnimation = nil;
}

- (IBAction)showPackUp:(id)sender {
	[[self window] makeKeyAndOrderFront:nil];
	[modeMatrix goToTag:1];
}

- (IBAction)showCreateService:(id)sender {
	[[self window] makeKeyAndOrderFront:nil];
	[modeMatrix goToTag:0];
}


-(BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	TSViewController *vc = [self viewControllerForTag:[modeMatrix selectedTag]];
	if (nil == vc) return NO;
	return [vc shouldOpenFileAtPath:filename];
}

- (void)dealloc {
    [viewControllers release];
    [currentAnimation release];
    [super dealloc];
}

@end
