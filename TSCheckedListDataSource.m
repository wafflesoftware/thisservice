//
//  TSCheckedListDataSource.m
//  ThisService
//
//  Created by Jesper on 2011-07-14.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import "TSCheckedListDataSource.h"


@implementation TSCheckedListDataSource

+ (NSIndexSet *)indexSetOfSelectedIndexesForRowData:(NSArray *)rowData selectedValues:(NSSet *)values {
	NSMutableIndexSet *selectedIndexSet = [NSMutableIndexSet indexSet];
	
	if ([values count] == 0) return selectedIndexSet;
	
	NSUInteger i = 0;
	for (NSDictionary *row in rowData) {
		if ([values containsObject:[row objectForKey:@"value"]]) {
			[selectedIndexSet addIndex:i];
		}
		i++;
	}
	
	return selectedIndexSet;
}

- (id)initWithRowData:(NSArray *)rowData_ selectedChoices:(NSIndexSet *)selectedIndexes_ labelKey:(NSString *)labelKey_ delegate:(id<TSCheckedListDataSourceDelegate>)aDelegate {
	self = [super init];
	if (self != nil) {
		rowData = [rowData_ retain];
		NSUInteger indexGreaterThanMaxValidIndex = (selectedIndexes_ == nil ? NSNotFound : [selectedIndexes_ indexGreaterThanIndex:(NSUInteger)[rowData_ count]-1]);
		if (indexGreaterThanMaxValidIndex != NSNotFound) {
			[NSException raise:@"Can't construct checked list data source; selected choices extend beyond choices" format:@""];
		}
		selectedIndexes = selectedIndexes_ == nil ? [[NSMutableIndexSet alloc] init] : [selectedIndexes_ mutableCopy];
		delegate = aDelegate;
		labelKey = [labelKey_ retain];
	}
	return self;
}

- (BOOL)anyChoicesSelected {
	return [selectedIndexes count] > 0;
}

- (NSArray *)selectedChoiceValues {
	return [[self selectedChoices] valueForKey:@"value"];
}

- (NSArray *)selectedChoices {
	return [rowData objectsAtIndexes:selectedIndexes];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [rowData count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSUInteger idxOfColumn = [[tableView tableColumns] indexOfObject:tableColumn];
	if (idxOfColumn == 0) {
		return ([NSNumber numberWithInt:[selectedIndexes containsIndex:row] ? NSOnState : NSOffState]);
	} else {
		NSDictionary *columns = (NSDictionary *)[rowData objectAtIndex:row];
		NSString *columnValue = (NSString *)[columns objectForKey:[tableColumn identifier]];
		
		return columnValue == nil ? @"" : columnValue;
	}
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSUInteger idxOfColumn = [[tableView tableColumns] indexOfObject:tableColumn];
	if (idxOfColumn != 0) return;
	NSCellStateValue state = (NSCellStateValue)[(NSNumber *)object intValue];
	if (state == NSOnState) {
		[selectedIndexes addIndex:(NSUInteger)row];
	} else if (state == NSOffState) {
		[selectedIndexes removeIndex:(NSUInteger)row];
	}
	
	[delegate dataSource:self checkedChoicesChanged:[self selectedChoices]];
	
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if (tableColumn == nil) return;
	NSUInteger idxOfColumn = [[tableView tableColumns] indexOfObject:tableColumn];
	if (idxOfColumn == 0) {
		NSString *label = (NSString *)[(NSDictionary *)[rowData objectAtIndex:row] objectForKey:labelKey];
		NSButtonCell *checkBox = (NSButtonCell *)aCell;
		[checkBox setTitle:label];
		[checkBox setButtonType:NSSwitchButton];
		[checkBox setState:([selectedIndexes containsIndex:row] ? NSOnState : NSOffState)];
	} else {
		NSDictionary *columns = (NSDictionary *)[rowData objectAtIndex:row];
		NSString *columnValue = (NSString *)[columns objectForKey:[tableColumn identifier]];
		columnValue = (columnValue == nil ? @"" : columnValue);
		
		NSTextFieldCell *textCell = (NSTextFieldCell *)aCell;
		[textCell setStringValue:columnValue];
		[textCell setTextColor:[NSColor disabledControlTextColor]];
		[textCell setBordered:NO];
		[textCell setEditable:NO];
	}
}

- (void)dealloc {
    [rowData release];
    [selectedIndexes release];
    [labelKey release];
    [super dealloc];
}

@end
