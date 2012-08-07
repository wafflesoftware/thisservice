#import "WFMachTime.h"

#include <mach/mach.h>
#include <mach/mach_time.h>
#include <unistd.h>


@interface WFMachTime ()
@property uint64_t startedTime;
@end

@implementation WFMachTime
@synthesize startedTime;

+ (uint64_t)currentPrimitiveTime {
	return mach_absolute_time();
}

+ (WFMachTime *)currentTime {
	WFMachTime *time = [[self alloc] init];
	time.startedTime = [self currentPrimitiveTime];
	return [time autorelease];
}

NSTimeInterval WFMachTimeIntervalBetweenStartTimeEndTime(uint64_t startTime, uint64_t endTime) {
    uint64_t        elapsed;
    uint64_t        elapsedNano;
    static mach_timebase_info_data_t    sTimebaseInfo;
	
    elapsed = endTime - startTime;
	
    if ( sTimebaseInfo.denom == 0 ) {
        (void) mach_timebase_info(&sTimebaseInfo);
    }
	
    elapsedNano = elapsed * sTimebaseInfo.numer / sTimebaseInfo.denom;
	
	NSTimeInterval duration = (NSTimeInterval)(elapsedNano / 1000000000.0);
	
	return duration;
}

- (NSTimeInterval)intervalSinceTime:(WFMachTime *)time {
    uint64_t startTime = time.startedTime;
	uint64_t endTime = self.startedTime;
    
	return WFMachTimeIntervalBetweenStartTimeEndTime(startTime, endTime);
}

- (NSTimeInterval)intervalSinceStart {
	uint64_t startTime = self.startedTime;
	uint64_t endTime = [[self class] currentPrimitiveTime];
    
	return WFMachTimeIntervalBetweenStartTimeEndTime(startTime, endTime);
}
@end