//
//  TSCheckedListDataSource.h
//  ThisService
//
//  Created by Jesper on 2011-07-14.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Cocoa/Cocoa.h>

@class TSCheckedListDataSource;

@protocol TSCheckedListDataSourceDelegate
- (void)dataSource:(TSCheckedListDataSource *)dataSource checkedChoicesChanged:(NSArray *)selectedChoices;
@end


@interface TSCheckedListDataSource : NSObject <NSTableViewDelegate, NSTableViewDataSource> {
	NSArray *rowData;
	NSMutableIndexSet *selectedIndexes;
	NSString *labelKey;
	id<TSCheckedListDataSourceDelegate> delegate;
}
- (id)initWithRowData:(NSArray *)rowData selectedChoices:(NSIndexSet *)selectedIndexes labelKey:(NSString *)labelKey delegate:(id<TSCheckedListDataSourceDelegate>)delegate;
- (NSArray *)selectedChoices;
- (NSArray *)selectedChoiceValues;
- (BOOL)anyChoicesSelected;

+ (NSIndexSet *)indexSetOfSelectedIndexesForRowData:(NSArray *)rowData selectedValues:(NSSet *)values;
@end
