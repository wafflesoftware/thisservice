//
//  TSServiceInputRulesWindowController.h
//  ThisService
//
//  Created by Jesper on 2011-07-17.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Cocoa/Cocoa.h>

#import "TSCheckedListDataSource.h"

@class TSServiceInputRules;

@class TSServiceInputRulesWindowController;

@protocol TSServiceInputRulesWindowControllerDelegate
- (void)serviceInputRulesWindowController:(TSServiceInputRulesWindowController *)windowController savedChanges:(TSServiceInputRules *)newRules;
- (void)serviceInputRulesWindowControllerCancelled:(TSServiceInputRulesWindowController *)windowController;
@end


@interface TSServiceInputRulesWindowController : NSWindowController <TSCheckedListDataSourceDelegate> {
	TSServiceInputRules *initialInputRules;
	id<TSServiceInputRulesWindowControllerDelegate> editor;
	
	IBOutlet NSPanel *inputRulesPanel;
	
	TSCheckedListDataSource *writingSystemCheckedListDataSource;
	IBOutlet NSTableView *writingSystemTableView;
	BOOL constrainsByWritingSystem;
	
	TSCheckedListDataSource *contentTypeCheckedListDataSource;
	IBOutlet NSTableView *contentTypeTableView;
	BOOL constrainsByContentType;
	
	TSCheckedListDataSource *languageCheckedListDataSource;
	IBOutlet NSTableView *languageTableView;
	BOOL constrainsByLanguage;
	
	BOOL constrainsByWordLimit;
	NSInteger wordLimit;
	
	
}

- (void)setEditor:(id<TSServiceInputRulesWindowControllerDelegate>)newEditor;
- (void)setInitialInputRules:(TSServiceInputRules *)initialInputRules;

- (void)setConstrainsByWritingSystem:(BOOL)c;
- (BOOL)constrainsByWritingSystem;

- (void)setConstrainsByContentType:(BOOL)c;
- (BOOL)constrainsByContentType;

- (void)setConstrainsByWordLimit:(BOOL)c;
- (BOOL)constrainsByWordLimit;

- (void)setConstrainsByLanguage:(BOOL)c;
- (BOOL)constrainsByLanguage;

- (void)setWordLimit:(NSInteger)wordLimit;
- (NSInteger)wordLimit;


- (IBAction)okayInputRulesSheet:(id)sender;
- (IBAction)cancelInputRulesSheet:(id)sender;

@end
