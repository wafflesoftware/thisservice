#import "OpaqueView.h"

@implementation OpaqueView

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil) {
		// Add initialization code here
	}
	return self;
}

- (void)drawRect:(NSRect)rect
{
	[[[self window] backgroundColor] setFill];
	[NSBezierPath fillRect:rect];
}

- (BOOL)isOpaque {
	return NO;
}

@end
