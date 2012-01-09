/*
 *  image.h
 *  Quicklook-PFM
 * 
 * Copyright (C) 2008-2012 Andreas Steinel
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * 
 */

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
