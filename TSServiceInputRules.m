//
//  TSServiceInputRules.m
//  ThisService
//
//  Created by Jesper on 2011-07-17.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import "TSServiceInputRules.h"


@implementation TSServiceInputRules

- (id)initWithWritingSystems:(NSSet *)writingSystems_
				contentTypes:(NSSet *)contentTypes_
				   wordLimit:(NSNumber *)wordLimit_
	  applicationIdentifiers:(NSSet *)applicationIdentifiers_
				   languages:(NSSet *)languages_ {
	self = [super init];
	if (self != nil) {
		writingSystems = [writingSystems_ copy];
		contentTypes = [contentTypes_ copy];
		wordLimit = [wordLimit_ retain];
		applicationIdentifiers = [applicationIdentifiers_ copy];
		languages = [languages_ retain];
	}
	return self;
}

- (NSSet *)writingSystems {
	return writingSystems;
}

- (NSSet *)contentTypes {
	return contentTypes;
}

- (NSNumber *)wordLimit {
	return wordLimit;
}

- (NSSet *)applicationIdentifiers {
	return applicationIdentifiers;
}

- (NSSet *)languages {
	return languages;
}

+ (NSSet *)setFromSingleStringOrArrayOfStrings:(id)obj {
	if (obj == nil) return nil;
	if ([obj isKindOfClass:[NSString class]]) return [NSSet setWithObject:obj];
	if ([obj isKindOfClass:[NSArray class]]) {
		NSArray *arr = (NSArray *)obj;
		NSMutableSet *set = [NSMutableSet set];
		for (id arrObj in arr) {
			if ([arrObj isKindOfClass:[NSString class]]) {
				[set addObject:arrObj];
			}
		}
		return set;
	}
	return nil;
}

+ (TSServiceInputRules *)singleInputRulesFromInfoPlistRequiredContext:(NSDictionary *)requiredContextEntryDictionary {
	NSSet *writingSystems = [self setFromSingleStringOrArrayOfStrings:[requiredContextEntryDictionary objectForKey:@"NSTextScript"]];
	NSSet *languages = [self setFromSingleStringOrArrayOfStrings:[requiredContextEntryDictionary objectForKey:@"NSTextLanguage"]];
	NSSet *contentTypes = [self setFromSingleStringOrArrayOfStrings:[requiredContextEntryDictionary objectForKey:@"NSTextContent"]];
	NSSet *applicationIdentifiers = [self setFromSingleStringOrArrayOfStrings:[requiredContextEntryDictionary objectForKey:@"NSApplicationIdentifier"]];
	id wordLimitObj = [requiredContextEntryDictionary objectForKey:@"NSWordLimit"];
	NSNumber *wordLimit = (wordLimitObj == nil ? nil : ([wordLimitObj isKindOfClass:[NSNumber class]] ? (NSNumber *)wordLimitObj : nil));
	
	return [[[TSServiceInputRules alloc] initWithWritingSystems:writingSystems
												  contentTypes:contentTypes
													 wordLimit:wordLimit 
										applicationIdentifiers:applicationIdentifiers 
													 languages:languages] autorelease];
}

+ (NSArray *)allInputRulesFromInfoPlistRequiredContext:(id)requiredContextEntry {
	if ([requiredContextEntry isKindOfClass:[NSDictionary class]]) {
		TSServiceInputRules *rule = [self singleInputRulesFromInfoPlistRequiredContext:(NSDictionary *)requiredContextEntry];
		if (rule == nil) return nil;
		return [NSArray arrayWithObject:rule];
	} else if ([requiredContextEntry isKindOfClass:[NSArray class]]) {
		NSMutableArray *array = [NSMutableArray arrayWithCapacity:[(NSArray *)requiredContextEntry count]];
		for (NSDictionary *dict in array) {
			TSServiceInputRules *rule = [self singleInputRulesFromInfoPlistRequiredContext:dict];			
			if (rule == nil) continue;
			[array addObject:rule];
		}
		return array;
	} else return nil;
}

- (id)singleStringOrArrayOfStringsFromSet:(NSSet *)set {
	if ([set count] == 0) return nil;
	if ([set count] == 1) return [set anyObject];
	return [set allObjects];
}

- (void)inDictionary:(NSMutableDictionary *)dict setObjectIfNotNil:(id)obj forKey:(NSString *)string {
	if (obj)
		[dict setObject:obj forKey:string];
}

- (NSDictionary *)infoPlistRequiredContextDictionary {
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[self inDictionary:dictionary setObjectIfNotNil:[self singleStringOrArrayOfStringsFromSet:writingSystems] forKey:@"NSTextScript"];
	[self inDictionary:dictionary setObjectIfNotNil:[self singleStringOrArrayOfStringsFromSet:languages] forKey:@"NSTextLanguage"];
	[self inDictionary:dictionary setObjectIfNotNil:[self singleStringOrArrayOfStringsFromSet:contentTypes] forKey:@"NSTextContent"];
	[self inDictionary:dictionary setObjectIfNotNil:[self singleStringOrArrayOfStringsFromSet:applicationIdentifiers] forKey:@"NSApplicationIdentifier"];
	[self inDictionary:dictionary setObjectIfNotNil:wordLimit forKey:@"NSWordLimit"];
	return dictionary;
}

- (BOOL)isEmpty {
	return (writingSystems == nil && contentTypes == nil && wordLimit == nil && applicationIdentifiers == nil && languages == nil);
}

- (void)dealloc {
	[writingSystems release];
	[contentTypes release];
	[wordLimit release];
	[applicationIdentifiers release];
	[languages release];
	
	[super dealloc];
}


@end
