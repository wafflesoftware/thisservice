//
//  TSWindowController.h
//  ThisService
//
//  Created by Jesper on 2011-07-11.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Cocoa/Cocoa.h>

#import "TSModeMatrix.h"
#import "TSViewController.h"

@interface TSWindowController : NSWindowController <NSApplicationDelegate, TSModeMatrixDelegate, TSViewControllerContainer, NSAnimationDelegate> {
	NSArray *viewControllers;
	IBOutlet TSModeMatrix *modeMatrix;
	IBOutlet NSView *subviewView;
	
	NSViewAnimation *currentAnimation;
}

- (IBAction)showPackUp:(id)sender;
- (IBAction)showCreateService:(id)sender;

@end

@interface TSViewController ()
- (void)viewWillAppearInContainer:(id<TSViewControllerContainer>)c;
@end