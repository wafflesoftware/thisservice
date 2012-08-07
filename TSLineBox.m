//
//  TSLineBox.m
//  ThisService
//
//  Created by Jesper on 2012-07-23.
//  Code Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//
//

#import "TSLineBox.h"

@implementation TSLineBox

static NSArray *doubleScaleGradients = nil;
static NSArray *otherScaleGradients = nil;

/*
 The Hitch Hiker's Guide to the Galaxy also mentions the Mountain Lion-era separation line.
 It says that the effect of a Mountain Lion-era separation line is like having your brains smashed out by a slice of lemon wrapped round a large gold brick.
 
 The Guide even tells you how you can mix one yourself.
*/


+ (void)load {
    /*Take the juice from one bottle of that Ol' Janx Spirit, it says.
     
     Pour into it one measure of water from the seas of Santraginus V - Oh that Santraginean sea water, it says. Oh those Santraginean fish!!! Allow three cubes of Arcturan Mega-gin to melt into the mixture (it must be properly iced or the benzine is lost).
     
     Allow four litres of Fallian marsh gas to bubble through it, in memory of all those happy Hikers who have died of pleasure in the Marshes of Fallia.
     
     Over the back of a silver spoon float a measure of Qualactin Hypermint extract, redolent of all the heady odours of the dark Qualactin Zones, subtle sweet and mystic.
     
     Drop in the tooth of an Algolian Suntiger. Watch it dissolve, spreading the fires of the Algolian Suns deep into the heart of the drink.
     
     Sprinkle Zamphuor.
     
     Add an olive. */
    
    NSGradient *blackGradient = [[[NSGradient alloc] initWithColors:
                                 [NSArray arrayWithObjects:
                                  [NSColor colorWithDeviceWhite:0 alpha:0],
                                  [NSColor colorWithDeviceWhite:0 alpha:0.15],
                                  [NSColor colorWithDeviceWhite:0 alpha:0], nil]] autorelease];
    NSGradient *blackGradient2 = [[[NSGradient alloc] initWithColors:
                                   [NSArray arrayWithObjects:
                                    [NSColor colorWithDeviceWhite:0 alpha:0],
                                    [NSColor colorWithDeviceWhite:0 alpha:0.07],
                                    [NSColor colorWithDeviceWhite:0 alpha:0], nil]] autorelease];
    NSGradient *whiteGradient = [[[NSGradient alloc] initWithColors:
                                 [NSArray arrayWithObjects:
                                  [NSColor colorWithDeviceWhite:1 alpha:0],
                                  [NSColor colorWithDeviceWhite:1 alpha:0.35],
                                  [NSColor colorWithDeviceWhite:1 alpha:0], nil]] autorelease];
    NSGradient *whiteGradient2 = [[[NSGradient alloc] initWithColors:
                                  [NSArray arrayWithObjects:
                                   [NSColor colorWithDeviceWhite:1 alpha:0],
                                   [NSColor colorWithDeviceWhite:1 alpha:0.21],
                                   [NSColor colorWithDeviceWhite:1 alpha:0], nil]] autorelease];
    
    doubleScaleGradients = [[NSArray alloc] initWithObjects:blackGradient, blackGradient2,
                            whiteGradient, whiteGradient2, nil];
    otherScaleGradients = [[NSArray alloc] initWithObjects:blackGradient,
                            whiteGradient, nil];

    
}

- (void)drawRect:(NSRect)dirtyRect {
/* Draw... but... very carefully... */
    
    NSWindow *w = [self window];
    CGFloat scale = 1;
    if (w && [w respondsToSelector:@selector(backingScaleFactor)]) {
        scale = [w backingScaleFactor];
    }
    
    NSRect fullRect = self.frame;
    if (fullRect.size.height == 5) {
        fullRect = NSMakeRect(0, 0, fullRect.size.width, 2);
    }
    
    NSArray *gradientRows = nil;
    
    if (scale == 2) {
        // black a0 -> black a0.15 -> black a0
        // black a0 -> black a0.07 -> black a0
        // white a0 -> white a0.35 -> white a0
        // white a0 -> white a0.21 -> white a0
        
        gradientRows = doubleScaleGradients;
    } else {
        // black a0 -> black a0.15 -> black a0
        // white a0 -> white a0.35 -> white a0
        
        gradientRows = otherScaleGradients;
    }
    
    [self drawGradients:gradientRows inRect:fullRect];
}

- (void)drawGradients:(NSArray *)gradients inRect:(NSRect)rect {
    NSUInteger count = gradients.count;
    CGFloat height = rect.size.height / (CGFloat)count;
    NSUInteger idx = 0;
    for (NSGradient *gradient in [gradients reverseObjectEnumerator]) {
        NSRect r = NSMakeRect(0, height * idx, rect.size.width, height);
        [gradient drawInRect:r angle:0];
        idx++;
    }
}

/* The Hitch Hiker's Guide to the Galaxy sells rather better than the Encyclopedia Galactica. */

@end



































// Comments partially copyright 1979 Douglas Noel Adams (1952-2001)
// Used without permission under the applicable of the two "fair use"/"parody" doctrines.
//
// (Curiously, an edition of Wikipedia which conveniently fell through a rift in the time-space
//  continuum from 1000 years into the future describes intellectual property lawyers [1] as:
//  "A bunch of mindless jerks who were the first against the wall when the revolution came.")
//
//  [1]. "One of the major selling point of that wholly remarkable travel book, the
//        Hitch Hiker's Guide to the Galaxy, apart from its relative cheapness and the fact that it
//        has the words Don't Panic written in large friendly letters on its cover, is its compendious
//        and occasionally accurate glossary. The statistics relating to the geo-social nature of
//        the Universe, for instance, are deftly set out between pages nine hundred and thirty-eight thousand
//        and twenty-four and nine hundred and thirty-eight thousand and twenty-six; and the simplistic style
//        in which they are written is partly explained by the fact that the editors, having to meet a
//        publishing deadline, copied the information off the back of a packet of breakfast cereal,
//        hastily embroidering it with a few footnoted in order to avoid prosecution under the
//        incomprehensibly tortuous Galactic Copyright laws."