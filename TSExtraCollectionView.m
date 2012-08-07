//
//  TSExtraCollectionView.m
//  ThisService
//
//  Created by Jesper on 2012-07-09.
//  Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//
//

#import "TSExtraCollectionView.h"
#import <objc/runtime.h>

@implementation TSExtraCollectionView

-(void)awakeFromNib {
    views = [[NSMutableDictionary alloc] init];
}

- (void)registerView:(NSView *)view forIdentifier:(NSString *)identifier {
    [views setObject:view forKey:identifier];
}

- (void)registerWhenRemovedTarget:(id)target action:(SEL)action {
    whenRemovedTarget = [target retain];
    whenRemovedAction = action;
}

- (void)callWhenRemoved {
    [whenRemovedTarget performSelector:whenRemovedAction withObject:self];
}

- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object {
    NSCollectionViewItem *newItem = [super newItemForRepresentedObject:object];
    
//    NSLog(@"new item %@", newItem);
    
    NSView *v = [newItem view];
    TSExtraCollectionItemView *itemView = (TSExtraCollectionItemView *)v;
    [itemView setItem:newItem];
    
    NSButton *button = [itemView viewWithTag:888];
    [button setTarget:itemView];
    [button setAction:@selector(removeItem:)];
    
//    NSLog(@"itemView: %@", itemView);
    
    NSView *view = [views objectForKey:object];
    [itemView addSubview:view];
    
    return newItem;
}

@end


@implementation TSExtraCollectionItemView
@synthesize item = _item;
- (IBAction)removeItem:(id)sender {
    NSMutableArray *c = [[[_item.collectionView content] mutableCopy] autorelease];
    [c removeObject:_item.representedObject];
    
    
    id plainCollectionView = _item.collectionView;
    TSExtraCollectionView *collectionView = nil;
    if ([plainCollectionView isKindOfClass:[TSExtraCollectionView class]]) {
        collectionView = plainCollectionView;
    }
    
    [_item.collectionView setContent:c];
    
    if (collectionView) {
        [collectionView callWhenRemoved];
    }
    
}
@end