//
//  TSStubbornImageView.h
//  ThisService
//
//  Created by Jesper on 2011-07-13.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Cocoa/Cocoa.h>

@class TSStubbornImageView;

@protocol TSStubbornImageViewDelegate
- (void)stubbornImageView:(TSStubbornImageView *)imageView changedImage:(NSImage *)image isStubbornDefault:(BOOL)isDefault;
@end


@interface TSStubbornImageView : NSImageView {
	IBOutlet id<TSStubbornImageViewDelegate> delegate;
}
- (BOOL)isStubbornDefault;
@end
