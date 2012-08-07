//
//  ServiceSkeletonMagic.h
//  ThisService
//
//  Created by Jesper on 2006-10-28.
//  Copyright 2006-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Cocoa/Cocoa.h>
#import "TSServiceTesting.h"

#define SLog(...)    do { if (logging) { NSLog(__VA_ARGS__); } } while (0)

@interface ServiceSkeletonMagic : NSObject <TSServiceTestingSkeleton> {
    NSString *_connectionName;
    id<TSServiceTestingProducer> _producer;
    
    NSConnection *_connection;
    
	NSArray *scriptCandidates;
    
    BOOL isRunning;
	
	BOOL waitingForChoice;
	NSURL *selectedScript;
	
	NSMutableDictionary *outputsForFileHandles;
}
@property (readonly, retain) NSString *connectionName;
@property (retain) NSConnection *connection;
@property (readonly, retain) id<TSServiceTestingProducer> producer;
- (void)registerProducer:(id<TSServiceTestingProducer>)p;

+ (void)setLogging:(BOOL)nl;

+ (BOOL)shouldKeepRunning;
- (void)bumpBailingTimer;

- (BOOL)vendSkeleton;

- (NSData *)callThroughToScript:(NSString *)filename withData:(NSData *)data expectingOutput:(BOOL)expOut error:(NSError **)error;
- (NSURL *)askUserToPickScriptOne:(NSURL *)one orTwo:(NSURL *)two;

- (NSURL *)urlToScript;
@end
