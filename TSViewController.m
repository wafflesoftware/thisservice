//
//  TSViewController.m
//  ThisService
//
//  Created by Jesper on 2011-07-11.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import "TSViewController.h"
#import "TSWindowController.h"

@implementation TSViewController
- (id<TSViewControllerContainer>)container {
    return _currentContainer;
}

- (BOOL)shouldSwitchToViewController:(TSViewController *)otherViewController {
	return YES;
}

- (BOOL)shouldOpenFileAtPath:(NSString *)filePath {
	return NO;
}

- (void)viewWillAppearInContainer:(id<TSViewControllerContainer>)c {
//    NSLog(@"%@ will appear in container %@", self, c);
    _currentContainer = c;
    [self viewWillAppear];
}

- (void)viewWillAppear {
	
}

- (void)viewWillDisappear {
//    NSLog(@"%@ will disappear from container %@", self, _currentContainer);
    _currentContainer = nil;
}
@end
