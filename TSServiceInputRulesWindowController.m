//
//  TSServiceInputRulesWindowController.m
//  ThisService
//
//  Created by Jesper on 2011-07-17.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import "TSServiceInputRulesWindowController.h"
#import "TSServiceInputRules.h"

@implementation TSServiceInputRulesWindowController

- (void)setInitialInputRules:(TSServiceInputRules *)anInitialInputRules {
	initialInputRules = [anInitialInputRules retain];
}

- (void)setEditor:(id<TSServiceInputRulesWindowControllerDelegate>)newEditor {
	editor = newEditor;
}

/*
static NSInteger CompareLanguageRows(id arg1, id arg2, void *arg3) {
	return [[arg1 objectForKey:@"label"] compare:[arg2 objectForKey:@"label"]];
}*/

+ (NSArray *)languagesRowData {
	static NSArray *languagesRowData = nil;
	if (languagesRowData == nil) {
		NSArray *preferredLanguages = [NSLocale preferredLanguages];
		NSUInteger preferredCount = [preferredLanguages count];
		NSArray *localeLanguages = [preferredLanguages arrayByAddingObjectsFromArray:[NSLocale ISOLanguageCodes]];
		NSMutableArray *rowData = [NSMutableArray arrayWithCapacity:[localeLanguages count]];
		NSMutableSet *passedLanguages = [NSMutableSet set];
		NSLocale *localLocale = [NSLocale currentLocale];
		NSSet *phonyLanguages = [NSSet setWithObjects:@"und", nil];
		
		NSUInteger i = 0;
		for (NSString *localeLanguage in localeLanguages) {
			NSLocale *locale = [[[NSLocale alloc] initWithLocaleIdentifier:localeLanguage] autorelease];
			NSString *localeLang = [locale objectForKey:NSLocaleLanguageCode];
			
			BOOL pref = (preferredCount > i);
			
			i++;
			if ([phonyLanguages containsObject:localeLanguage]) continue;
			if ([phonyLanguages containsObject:localeLang]) continue;
			if ([passedLanguages containsObject:localeLang]) continue;
			[passedLanguages addObject:localeLang];
			
			NSString *nameInLocalLocale = [localLocale displayNameForKey:NSLocaleLanguageCode value:localeLanguage];
            if (nameInLocalLocale == nil) {
                // in 10.8, this is limited to the mainland Chinese languages [ gan, hak, hsn, nan, wuu ]
                // http://en.wikipedia.org/wiki/ISO_639_macrolanguage#zho
                continue;
            }
			NSString *nameInOwnLocale = [locale displayNameForKey:NSLocaleLanguageCode value:localeLanguage];

			NSString *localLocaleLang = [localLocale objectForKey:NSLocaleLanguageCode];
			
			BOOL sameLanguageLocales = [localeLang isEqualToString:localLocaleLang];
			
			BOOL sameNames = [nameInLocalLocale isEqualToString:nameInOwnLocale];
			NSString *unspecified = (sameNames && !sameLanguageLocales ? @"Y" : @"N");
			NSString *preferred = (pref ? @"Y" : @"N");
            
            NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                  nameInLocalLocale, @"label",
                                  localeLanguage, @"value",
                                  nameInOwnLocale, @"ex",
                                  unspecified, @"unspecified",
                                  preferred, @"preferred",
                                  nil];
			
			[rowData addObject:data];
		}
		
		NSArray *sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"preferred" ascending:NO], 
									[NSSortDescriptor sortDescriptorWithKey:@"unspecified" ascending:YES], 
									[NSSortDescriptor sortDescriptorWithKey:@"label" ascending:YES],
									nil];
		[rowData sortUsingDescriptors:sortDescriptors];
        
        //NSLog(@"language data: %@", rowData);
		
		languagesRowData = [rowData copy];
	}
	
	return languagesRowData;
}





- (void)awakeFromNib {
	if ([initialInputRules wordLimit] == nil) {
		[self setWordLimit:1];
	} else {
		[self setConstrainsByWordLimit:YES];
		[self setWordLimit:[[initialInputRules wordLimit] integerValue]];
	}
	
	NSArray *writingSystemRowData = [NSArray arrayWithObjects:
									 [NSDictionary dictionaryWithObjectsAndKeys:@"Arabic", @"label", @"Arab", @"value", @"العربية", @"scriptcharacters", nil],
									 [NSDictionary dictionaryWithObjectsAndKeys:@"Armenian", @"label", @"Armn", @"value", @"այբուբեն", @"scriptcharacters", nil],
									 [NSDictionary dictionaryWithObjectsAndKeys:@"Cyrillic", @"label", @"Cyrl", @"value", @"а, б, в, г, д", @"scriptcharacters", nil],
									 [NSDictionary dictionaryWithObjectsAndKeys:@"Devanagari", @"label", @"Deva", @"value", @"देवनागरी", @"scriptcharacters", nil],
									 [NSDictionary dictionaryWithObjectsAndKeys:@"Greek", @"label", @"Grek", @"value", @"Ελληνικά", @"scriptcharacters", nil],
									 [NSDictionary dictionaryWithObjectsAndKeys:@"Han", @"label", @"Hani", @"value", @"漢語", @"scriptcharacters", nil],
									 [NSDictionary dictionaryWithObjectsAndKeys:@"Hangul", @"label", @"Hang", @"value", @"한글", @"scriptcharacters", nil],
									 [NSDictionary dictionaryWithObjectsAndKeys:@"Hebrew", @"label", @"Hebr", @"value", @"עִבְרִית", @"scriptcharacters", nil],
									 [NSDictionary dictionaryWithObjectsAndKeys:@"Hiragana", @"label", @"Hira", @"value", @"ひらがな", @"scriptcharacters", nil],
									 [NSDictionary dictionaryWithObjectsAndKeys:@"Katakana", @"label", @"Kana", @"value", @"カタカナ", @"scriptcharacters", nil],
									 [NSDictionary dictionaryWithObjectsAndKeys:@"Latin", @"label", @"Latn", @"value", @"a, b, c", @"scriptcharacters", nil],
									 [NSDictionary dictionaryWithObjectsAndKeys:@"Thai", @"label", @"Thai", @"value", @"อักษรไทย", @"scriptcharacters", nil],
									 nil
									 ];
	
	NSIndexSet *writingSystemSelected = [TSCheckedListDataSource indexSetOfSelectedIndexesForRowData:writingSystemRowData
																					   selectedValues:[initialInputRules writingSystems]];
	
	writingSystemCheckedListDataSource = 
	[[TSCheckedListDataSource alloc] 
	 initWithRowData:writingSystemRowData
	 selectedChoices:writingSystemSelected
	 labelKey:@"label"
	 delegate:self];
	[writingSystemTableView setDelegate:writingSystemCheckedListDataSource];
	[writingSystemTableView setDataSource:writingSystemCheckedListDataSource];
	[writingSystemTableView reloadData];
	
	if ([writingSystemSelected count] > 0) {
		[self setConstrainsByWritingSystem:YES];
	}
	
	/*URL
	 Date
	 Address
	 Email
	 FilePath*/
	
	NSArray *contentTypeRowData = [NSArray arrayWithObjects:
								   [NSDictionary dictionaryWithObjectsAndKeys:@"URL", @"label", @"URL", @"value", @"apple.com", @"example", nil],
								   [NSDictionary dictionaryWithObjectsAndKeys:@"Date", @"label", @"Date", @"value", @"2012-12-21", @"example", nil],
								   [NSDictionary dictionaryWithObjectsAndKeys:@"Address", @"label", @"Address", @"value", @"1 Infinite Loop, California", @"example", nil],
								   [NSDictionary dictionaryWithObjectsAndKeys:@"Email", @"label", @"Email", @"value", @"x@example.org", @"example", nil],
								   [NSDictionary dictionaryWithObjectsAndKeys:@"File path", @"label", @"FilePath", @"value", @"/Users/test/test.txt", @"example", nil],
								   nil
								   ];
	
	NSIndexSet *contentTypeSelected = [TSCheckedListDataSource indexSetOfSelectedIndexesForRowData:contentTypeRowData
																				    selectedValues:[initialInputRules contentTypes]];
	
	contentTypeCheckedListDataSource = 
	[[TSCheckedListDataSource alloc] 
	 initWithRowData:contentTypeRowData
	 selectedChoices:contentTypeSelected
	 labelKey:@"label"
	 delegate:self];
	[contentTypeTableView setDelegate:contentTypeCheckedListDataSource];
	[contentTypeTableView setDataSource:contentTypeCheckedListDataSource];
	[contentTypeTableView reloadData];
	
	if ([contentTypeSelected count] > 0) {
		[self setConstrainsByContentType:YES];
	}
	
	NSArray *languagesRowData = [[self class] languagesRowData];
	
	NSIndexSet *languageSelected = [TSCheckedListDataSource indexSetOfSelectedIndexesForRowData:languagesRowData
																				    selectedValues:[initialInputRules languages]];
	
	languageCheckedListDataSource = 
	[[TSCheckedListDataSource alloc] 
	 initWithRowData:languagesRowData
	 selectedChoices:languageSelected
	 labelKey:@"label"
	 delegate:self];
	[languageTableView setDelegate:languageCheckedListDataSource];
	[languageTableView setDataSource:languageCheckedListDataSource];
	[languageTableView reloadData];
	
	if ([languageSelected count] > 0) {
		[self setConstrainsByLanguage:YES];
	}
}

- (BOOL)constraintsForContentTypeIsNonEmpty {
	return [contentTypeCheckedListDataSource anyChoicesSelected];
}

- (BOOL)constraintsForWritingSystemIsNonEmpty {
	return [writingSystemCheckedListDataSource anyChoicesSelected];
}

- (BOOL)constraintsForLanguageIsNonEmpty {
	return [languageCheckedListDataSource anyChoicesSelected];
}

- (BOOL)mayOkay {
	return ((constrainsByContentType ? [self constraintsForContentTypeIsNonEmpty] : YES) &&
			(constrainsByWritingSystem ? [self constraintsForWritingSystemIsNonEmpty] : YES) &&
			(constrainsByLanguage ? [self constraintsForLanguageIsNonEmpty] : YES));
}

+ (NSSet *)keyPathsForValuesAffectingMayOkay {
    return [NSSet setWithObjects:@"constraintsForContentTypeIsNonEmpty", @"constraintsForWritingSystemIsNonEmpty", @"constraintsForLanguageIsNonEmpty", @"constrainsByContentType", @"constrainsByWritingSystem", @"constrainsByLanguage", nil];
}

+ (NSSet *)keyPathsForValuesAffectingConstraintsForContentTypeIsNonEmpty {
	return [NSSet setWithObject:@"constrainsByContentType"];
}

+ (NSSet *)keyPathsForValuesAffectingConstraintsForWritingSystemIsNonEmpty {
	return [NSSet setWithObject:@"constrainsByWritingSystem"];
}

+ (NSSet *)keyPathsForValuesAffectingConstraintsForLanguageIsNonEmpty {
	return [NSSet setWithObject:@"constrainsByLanguage"];
}

- (void)dataSource:(TSCheckedListDataSource *)dataSource checkedChoicesChanged:(NSArray *)selectedChoices {
	if (dataSource == contentTypeCheckedListDataSource) {
		[self willChangeValueForKey:@"constraintsForContentTypeIsNonEmpty"];
		[self didChangeValueForKey:@"constraintsForContentTypeIsNonEmpty"];
	} else if (dataSource == writingSystemCheckedListDataSource) {
		[self willChangeValueForKey:@"constraintsForWritingSystemIsNonEmpty"];
		[self didChangeValueForKey:@"constraintsForWritingSystemIsNonEmpty"];
	} else if (dataSource == languageCheckedListDataSource) {
		[self willChangeValueForKey:@"constraintsForLanguageIsNonEmpty"];
		[self didChangeValueForKey:@"constraintsForLanguageIsNonEmpty"];
	}
}

- (void)setConstrainsByWordLimit:(BOOL)c {
	[self willChangeValueForKey:@"constrainsByWordLimit"];
	constrainsByWordLimit = c;
	[self didChangeValueForKey:@"constrainsByWordLimit"];
}
- (BOOL)constrainsByWordLimit {
	return constrainsByWordLimit;
}

- (void)setConstrainsByWritingSystem:(BOOL)c {
	[self willChangeValueForKey:@"constrainsByWritingSystem"];
	constrainsByWritingSystem = c;
	[self didChangeValueForKey:@"constrainsByWritingSystem"];
}
- (BOOL)constrainsByWritingSystem {
	return constrainsByWritingSystem;
}

- (void)setConstrainsByContentType:(BOOL)c {
	[self willChangeValueForKey:@"constrainsByContentType"];
	constrainsByContentType = c;
	[self didChangeValueForKey:@"constrainsByContentType"];
}
- (BOOL)constrainsByContentType {
	return constrainsByContentType;
}

- (void)setConstrainsByLanguage:(BOOL)c {
	[self willChangeValueForKey:@"constrainsByLanguage"];
	constrainsByLanguage = c;
	[self didChangeValueForKey:@"constrainsByLanguage"];
}
- (BOOL)constrainsByLanguage {
	return constrainsByLanguage;
}

- (void)setWordLimit:(NSInteger)wordLimit_ {
	[self willChangeValueForKey:@"wordLimit"];
	wordLimit = wordLimit_;
	[self didChangeValueForKey:@"wordLimit"];
}
- (NSInteger)wordLimit {
	return wordLimit;
}


- (IBAction)okayInputRulesSheet:(id)sender {
	[editor serviceInputRulesWindowController:self
								 savedChanges:[[[TSServiceInputRules alloc] 
											   initWithWritingSystems:(constrainsByWritingSystem ? [NSSet setWithArray:[writingSystemCheckedListDataSource selectedChoiceValues]] : nil)
														 contentTypes:(constrainsByContentType ? [NSSet setWithArray:[contentTypeCheckedListDataSource selectedChoiceValues]] : nil)
													        wordLimit:(constrainsByWordLimit ? [NSNumber numberWithInteger:wordLimit] : nil)
											   applicationIdentifiers:nil
												languages:(constrainsByLanguage ? [NSSet setWithArray:[languageCheckedListDataSource selectedChoiceValues]] : nil)] autorelease]];
}

- (IBAction)cancelInputRulesSheet:(id)sender {
	[editor serviceInputRulesWindowControllerCancelled:self];
}





- (void) dealloc {
    [writingSystemCheckedListDataSource release];
    [contentTypeCheckedListDataSource release];
    [languageCheckedListDataSource release];
	[initialInputRules release];
	
	[super dealloc];
}

@end
