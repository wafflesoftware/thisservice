// This class is written by Jesper <wootest+machtimer@gmail.com> and is placed in the public domain.

#import <Foundation/Foundation.h>

@interface WFMachTime : NSObject {
	uint64_t	startedTime;
}
+ (WFMachTime *)currentTime;
@property(readonly) NSTimeInterval intervalSinceStart;
@end