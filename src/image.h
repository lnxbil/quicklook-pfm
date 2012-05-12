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
// code fixed to use modified routines from libpbm 201205
//#define PGM_BIGGRAYS


//#ifdef PGM_BIGGRAYS
typedef unsigned short gray;
#define PGM_MAXMAXVAL 65535
//#else /*PGM_BIGGRAYS*/
//typedef unsigned char gray;
//#define PGM_MAXMAXVAL 255
//#endif /*PGM_BIGGRAYS*/


#define PBM_WHITE 0
#define PBM_BLACK 1



/* Magic constants. */

#define PGM_MAGIC1 'P'      // file is PPM, PGM or PBM
#define PBM_MAGIC2 '1'      // file is 1 bit per pixel ascii encoded
#define RPBM_MAGIC2 '4'     // file is 1 bit per pixel binary(?) encoded
#define PGM_MAGIC2 '2'      // file is 8 bits per pixel ascii encoded
#define RPGM_MAGIC2 '5'     // file is 8 bits per pixel binary encoded
#define PPM_MAGIC2 '3'      // file is 8 bits per pixel ascii encoded 3 channels
#define RPPM_MAGIC2 '6'     // file is 8 bits per pixel binary encoded 3 channels

#define PFM_MAGIC2 'f'      // file is 8 bits per pixel ascii encoded 3 channels
#define RPFM_MAGIC2 'F'     // file is 8 bits per pixel binary encoded 3 channels



#define PBM_FORMAT (PGM_MAGIC1 * 256 + PBM_MAGIC2)
#define RPBM_FORMAT (PGM_MAGIC1 * 256 + RPBM_MAGIC2)
#define PGM_FORMAT (PGM_MAGIC1 * 256 + PGM_MAGIC2)
#define RPGM_FORMAT (PGM_MAGIC1 * 256 + RPGM_MAGIC2)
#define PPM_FORMAT (PGM_MAGIC1 * 256 + PPM_MAGIC2)
#define RPPM_FORMAT (PGM_MAGIC1 * 256 + RPPM_MAGIC2)

#define PBM_TYPE PBM_FORMAT
#define PGM_TYPE PGM_FORMAT
#define PPM_TYPE PPM_FORMAT

/* Macros for turning a format number into a type number. */

#define PBM_FORMAT_TYPE(f) ((f) == PBM_FORMAT || (f) == RPBM_FORMAT ? PBM_TYPE : -1)
#define PGM_FORMAT_TYPE(f) ((f) == PGM_FORMAT || (f) == RPGM_FORMAT ? PGM_TYPE : PBM_FORMAT_TYPE(f))
#define PPM_FORMAT_TYPE(f) ((f) == PPM_FORMAT || (f) == RPPM_FORMAT ? PPM_TYPE : PGM_FORMAT_TYPE(f))


@interface PMReader : NSObject {

    float *red, *green, *blue;
    uint nx, ny;        // width and height
    uint8 spp;          // samples per pixel
    uint8 bps;          // bit per sample
    uint8 channels;     // channels
    uint  cp;           // color depth (#colors)

    int magicNumber;    // magic number from libpbm
    gray maxval;        // maximum value of color depth
    
}

- (CGImageRef)loadPFM:(const char*)filename;
- (CGImageRef)loadPPM:(const char*)filename;

- (char)pbm_getc:(FILE *)file;
- (int)pbm_getint:(FILE *)file;
- (int)pbm_readpbminit:(FILE *)file;


// general case
- (CGImageRef)load:(CFStringRef)filename;



@end
