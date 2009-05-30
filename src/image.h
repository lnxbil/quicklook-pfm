//
//  image.h
//  Quicklook-PFM
//
//  Created by Andreas Steinel on 17.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>



// This class implements the Picture Map Reader (PMReader)
// the known formats are
// http://local.wasp.uwa.edu.au/~pbourke/dataformats/ppm/
// 
@interface PMReader : NSObject {

    float *red, *green, *blue;
    uint nx, ny;        // width and height
    uint8 spp;          // samples per pixel
    uint8 bps;          // bit per sample
    uint8 channels;     // channels
    uint  cp;           // color depth (#colors)
}

- (CGImageRef)loadPFM:(const char*)filename;
- (CGImageRef)loadPPM:(const char*)filename;

// general case
- (CGImageRef)load:(CFStringRef)filename;

@end
