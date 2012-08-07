//
//  TSExtraCollectionView.h
//  ThisService
//
//  Created by Jesper on 2012-07-09.
//  Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//
//

#import <Cocoa/Cocoa.h>

@interface TSExtraCollectionView : NSCollectionView {
    NSMutableDictionary *views;
    id whenRemovedTarget;
    SEL whenRemovedAction;
}
- (void)registerView:(NSView *)view forIdentifier:(NSString *)identifier;
- (void)registerWhenRemovedTarget:(id)target action:(SEL)action;
@end


@interface TSExtraCollectionItemView : NSView {
    NSCollectionViewItem *_item;
}
@property (assign) NSCollectionViewItem *item;
- (IBAction)removeItem:(id)sender;
@end