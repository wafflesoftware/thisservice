//
//  TSServiceAppFilter.h
//  ThisService
//
//  Created by Jesper on 2012-07-01.
//  Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//
//

#import <Foundation/Foundation.h>

@interface TSServiceAppFilter : NSObject {
    @private
    NSSet *_applicationIdentifiers;
}
@property (readonly, copy) NSSet *applicationIdentifiers;
+ (id)appFilterWithApplicationIdentifiers:(NSSet *)applicationIdentifiers;
@end
