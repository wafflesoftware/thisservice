//
//  TSServiceInputRules.h
//  ThisService
//
//  Created by Jesper on 2011-07-17.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Cocoa/Cocoa.h>


@interface TSServiceInputRules : NSObject {
	NSSet *writingSystems;
	NSSet *contentTypes;
	NSNumber *wordLimit;
	NSSet *applicationIdentifiers;
	NSSet *languages;
}

- (id)initWithWritingSystems:(NSSet *)writingSystems
				contentTypes:(NSSet *)contentTypes
				   wordLimit:(NSNumber *)wordLimit 
	  applicationIdentifiers:(NSSet *)applicationIdentifiers
				   languages:(NSSet *)languages;

- (NSSet *)writingSystems;
- (NSSet *)contentTypes;
- (NSNumber *)wordLimit;
- (NSSet *)applicationIdentifiers;
- (NSSet *)languages;

- (NSDictionary *)infoPlistRequiredContextDictionary;
+ (TSServiceInputRules *)singleInputRulesFromInfoPlistRequiredContext:(NSDictionary *)requiredContextEntryDictionary;
+ (NSArray *)allInputRulesFromInfoPlistRequiredContext:(id)requiredContextEntry;

- (BOOL)isEmpty;
@end
