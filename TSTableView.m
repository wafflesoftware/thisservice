//
//  TSTableView.m
//  ThisService
//
//  Created by Jesper on 2011-07-15.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import "TSTableView.h"

@implementation TSTableView

- (void)keyDown:(NSEvent *)theEvent {
	
	static NSNumber *hasPerformClickOnCell = nil;
	if (!hasPerformClickOnCell) {
		hasPerformClickOnCell = [[NSNumber numberWithBool:[self respondsToSelector:@selector(performClickOnCellAtColumn:row:)]] retain];
	}
	if (![hasPerformClickOnCell boolValue]) {
		[super keyDown:theEvent];
		return;
	}
	
	NSUInteger keyboardModifiers = (NSShiftKeyMask | NSAlternateKeyMask | NSCommandKeyMask | NSControlKeyMask);
	if (([theEvent modifierFlags] & keyboardModifiers) == 0) {
        const int backspace = 51;
        const int delete = 117;
        if ([theEvent keyCode] == backspace || [theEvent keyCode] == delete) {
            if ([self.delegate respondsToSelector:@selector(deleteSelectedRows)]) {
                [self.delegate performSelector:@selector(deleteSelectedRows)];
                return;
            }
        }
		if ([[theEvent characters] isEqualToString:@" "]) {
			NSInteger selectedRow = [self selectedRow];
			if (selectedRow != NSNotFound) {
				NSCell *cell = [self preparedCellAtColumn:0 row:selectedRow];
				if ([cell isKindOfClass:[NSButtonCell class]]) {
					NSButtonCell *buttonCell = (NSButtonCell *)cell;
					if ([buttonCell isEnabled]) {
						[self performClickOnCellAtColumn:0 row:selectedRow];
						return;
					}
				}
			}
		}
	}
	
	[super keyDown:theEvent];
}
@end
