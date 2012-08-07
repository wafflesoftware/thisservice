//
//  TSServiceAppFilter.m
//  ThisService
//
//  Created by Jesper on 2012-07-01.
//  Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//
//

#import "TSServiceAppFilter.h"

@implementation TSServiceAppFilter
@synthesize applicationIdentifiers=_applicationIdentifiers;

- (id)initWithApplicationIdentifiers:(NSSet *)applicationIdentifiers
{
    self = [super init];
    if (self) {
        _applicationIdentifiers = [applicationIdentifiers copy];
    }
    return self;
}

+(id)appFilterWithApplicationIdentifiers:(NSSet *)applicationIdentifiers {
    return [[[self alloc] initWithApplicationIdentifiers:applicationIdentifiers] autorelease];
}


@end
