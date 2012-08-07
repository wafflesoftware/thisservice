//
//  TSServiceAppFilterWindowController.h
//  ThisService
//
//  Created by Jesper on 2012-07-01.
//  Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Cocoa/Cocoa.h>

@class TSServiceAppFilterWindowController;
@class TSServiceAppFilter;

@protocol TSServiceAppFilterWindowControllerDelegate
- (void)serviceAppFilterWindowController:(TSServiceAppFilterWindowController *)windowController savedChanges:(TSServiceAppFilter *)newRules;
- (void)serviceAppFilterWindowControllerCancelled:(TSServiceAppFilterWindowController *)windowController;
@end

@interface TSServiceAppFilterWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {
    NSMutableArray *apps;
    NSSet *appIDsInUse;
    NSTableView *tableView;
    TSServiceAppFilter *initialAppFilter;
	id<TSServiceAppFilterWindowControllerDelegate> editor;
    NSPopUpButton *applicationDropDown;
    NSButton *okButton;
}
@property (assign) IBOutlet NSPopUpButton *applicationDropDown;
@property (assign) IBOutlet NSButton *okButton;

- (void)setEditor:(id<TSServiceAppFilterWindowControllerDelegate>)newEditor;
- (void)setInitialAppFilter:(TSServiceAppFilter *)initialAppFilter;

@property (assign) IBOutlet NSTableView *tableView;
- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)deleteSelectedRowsByButton:(id)sender;

@end
