//
//  TSTableView.h
//  ThisService
//
//  Created by Jesper on 2011-07-15.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Cocoa/Cocoa.h>

@interface NSObject (TSTableViewDelegate)
- (void)deleteSelectedRows;
@end

@interface TSTableView : NSTableView {

}

@end
