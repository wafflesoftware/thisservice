//
//  TSViewController.h
//  ThisService
//
//  Created by Jesper on 2011-07-11.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Cocoa/Cocoa.h>

@class TSViewController;

@protocol TSViewControllerContainer <NSObject>
- (void)resizeViewController:(TSViewController *)vc toNewContentSize:(NSSize)size animate:(BOOL)animate;
@end

@interface TSViewController : NSViewController {
	@private
        id<TSViewControllerContainer> _currentContainer;
}
@property (assign, readonly) id<TSViewControllerContainer> container;
- (void)viewWillAppear;
- (void)viewWillDisappear;
- (BOOL)shouldSwitchToViewController:(TSViewController *)otherViewController;
- (BOOL)shouldOpenFileAtPath:(NSString *)filePath;
@end
