//
//  TSStubbornImageView.m
//  ThisService
//
//  Created by Jesper on 2011-07-13.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import "TSStubbornImageView.h"


@implementation TSStubbornImageView

- (NSImage *)stubbornDefault {
	static NSImage *stubbornDefault = nil;
	if (stubbornDefault == nil) {
		stubbornDefault = [[NSImage imageNamed:@"emptyApp16x16"] retain];
	}
	return stubbornDefault;
}

- (BOOL)imageShouldBeResisted:(NSImage *)newImage {
	return (newImage == nil);
}

- (void)setImage:(NSImage *)newImage {
	if ([self imageShouldBeResisted:newImage]) {
		[super setImage:[self stubbornDefault]];
		[delegate stubbornImageView:self changedImage:[self image] isStubbornDefault:YES];
	} else {
		[super setImage:newImage];
		[delegate stubbornImageView:self changedImage:[self image] isStubbornDefault:NO];
	}
}

- (BOOL)isStubbornDefault {
	return ([[self image] isEqual:[self stubbornDefault]] || [self imageShouldBeResisted:[self image]]);
}

@end
