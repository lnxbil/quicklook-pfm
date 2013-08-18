/*
 *  image.m
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

// May 2012  Bugfixes by JulieSPorter (sheepdoll on github)
// August 2013 Add support for P1 and P2 (ASCII) files (titouanc)

// changed load: method to use a safe multi langage string encoding method.  This allows
// for spaces in the path name to be correctly handled.
// rewrote PBM/PGM/PPM parser after pbmplus ppmlibrary routinees
// this adds methods pbm_getc and pbm_getint
// fixed pbm_getint to work with backwards (/) instead of (\) escape characters on the
// newlines.
// added pbm_readpbminit after ppmplus library, this code corretly handles the magic number
// that starts the file.
// loadPPM: method changed to use pbm_readpbminit and magic numbers
//
// To Be done:  
// change loadPFM to respond to magic numbers
// implement natural (ascii) encoding

#import "image.h"
#include <stdio.h>

static void readP2(FILE *input, NSBitmapImageRep *img, uint width, uint height, uint maxval)
{
    uint x=0, y=0, val;
    NSColor *color;
    while (! feof(input) && y<height){
        if (fscanf(input, "%u", &val) != 1)
            break;
        color = [NSColor colorWithCalibratedWhite: ((double)val/maxval) alpha:1];
        [img setColor:color atX:x y:y];
        x++;
        if (x == width){
            y++;
            x = 0;
        }
    }
}

static void readP1(FILE *input, NSBitmapImageRep *img, uint width, uint height)
{
    uint x=0, y=0, val;
    NSColor *black = [NSColor colorWithCalibratedWhite:0 alpha:1];
    NSColor *white = [NSColor colorWithCalibratedWhite:1 alpha:1];
    while (! feof(input) && y<height){
        if (fscanf(input, "%u", &val) != 1)
            break;
        [img setColor:((val) ? black : white) atX:x y:y];
        x++;
        if (x == width){
            y++;
            x = 0;
        }
    }
}

@implementation PMReader

- (char)pbm_getc:(FILE *)file
{
    register int ich;
    register char ch;
    
    ich = getc( file );
    if ( ich == EOF )
        NSLog(@"EOF / read error" );
    ch = (char) ich;
    
    if ( ch == '#' )
	{
        // capture comments here.  The origional coder seemed to think comments
        // to be useful.  No files caught in the wild have comments, so this is
        // disabled (not implemented) as the back channel is pretty cluttered as it is.
        // the best way to implement this would be to create or find methods
        // that appends a NSString from chars.  This gets complicated as international
        // and unicode variations should be handled for completness.
        do
	    {
            ich = getc( file );
            if ( ich == EOF )
                NSLog(@"EOF / read error" );
            ch = (char) ich;
	    }
        while ( ch != '\n' && ch != '\r' );
	}
    
    return ch;
}

- (int)pbm_getint:(FILE *)file
{
    register char ch;
    register int i;
    
    // properly handle whitespace chars that may be insterted to make the
    // data more readable. This is probably more useful with natural or ascii
    // encoding varients that convert from cstv table formats where separators are
    // commas, spaces and tabs. 
    do
	{
        ch = [ self pbm_getc: file ];
	}
    while ( ch == ' ' || ch == ',' || ch == '\t' || ch == '\n' || ch == '\r' );
    
    if ( ch < '0' || ch > '9' )
    {
        
        if (ch == '/') {
            // some files have the wrong newline escape sequence, since these files were
            // burned onto the CD we ignore such values 
            ch = [ self pbm_getc: file ];
        }
 
        NSLog(@"Warning: junk in file where an integer should be %c ",ch );
        
        do
        {
            ch = [ self pbm_getc: file ];
        }
        while ( ch < '0' || ch > '9' );
    }
     
    i = 0;
    do
	{
        i = i * 10 + ch - '0';
        ch = [ self pbm_getc: file ];
    }
    while ( ch >= '0' && ch <= '9' );
    
    return i;
}
- (int)pbm_readpbminit:(FILE *)file
{ 
    
    int formatP;
    //gray maxvalP = 0;
   
 
    // pbm_readmagicnumber( file )
    int ich1, ich2;
        
    ich1 = getc( file );
    if ( ich1 == EOF )
        NSLog(@"EOF / read error reading magic number" );
    ich2 = getc( file );
    if ( ich2 == EOF )
        NSLog(@"EOF / read error reading magic number" );
    
    formatP = ich1 * 256 + ich2;
    
    nx = [self pbm_getint: file ]; 
    ny = [ self pbm_getint: file ];

    channels = 1;
    switch ( PPM_FORMAT_TYPE(formatP) )
    {
        case PPM_TYPE:
            channels = 3;
        case PGM_TYPE:
            /* Read maxval. */
            maxval = (gray)[self pbm_getint: file ];
             break;

        case PBM_TYPE:
            maxval = 0;
            break;
           
        default:
            NSLog(@"bad magic number - not a pbm file" );
            return 0;

    }
    
    bps = 8;
    if (maxval > 255)
        bps = 16;
    
    NSLog(@"bps=%d",bps);
    
    if (maxval > PGM_MAXMAXVAL)
    {
        NSLog(@"Colorvalues of %d exceeds %d", cp,PGM_MAXMAXVAL);
        return -1;
    }

    
    return formatP;
    
}

- (CGImageRef)loadPFM:(const char*)filename
{
    FILE   *inimage;        // input file
    char   row[80];         // buffer    

    // resetting dimensions and counters
    nx = 0; ny = 0; channels = 1;
    
    // open image, which exists and has the correct
    // format (previously checked in 'load')
    inimage = fopen( filename,"r");
    
    // First entry is the filetype
    fgets (row, 80, inimage);
    
    
    // check if we have monochrome or not
    if ( row[1] == 'F' )
        channels = 3;

    
    // Second Entry could be the size of the image an it could be a comment
    fgets (row, 80, inimage);
    while (row[0]=='#') fgets(row, 80, inimage);
    
    // Saving image dimensions
    sscanf (row, "%d %d", &nx, &ny);
    printf("Reading Image with %dx%d\n",nx, ny);
    if (ny == 0)
    {
        printf("Trying second line for dimensions in PFM file\n");
        fgets (row, 80, inimage);
        sscanf (row, "%d", &ny);
        printf("Reading Image with %dx%d\n",nx, ny);
    }
    
    // get color depth
    fgets (row, 80, inimage);
    
    
    // We have to handle this on little-endian/big-endian stuff
    cp = 0;
    sscanf (row, "%d", &cp);
    
    
    NSLog(@"Image has been read and has size %dx%dx%d\n",nx, ny, channels);

   
    spp = channels;
    bps = 16;
    
    NSString* csp = NSDeviceRGBColorSpace;
    
    if (channels == 1)
        csp = NSDeviceWhiteColorSpace;
    
    
    NSBitmapImageRep *image2 = NULL;
    image2 = [[NSBitmapImageRep alloc]
              initWithBitmapDataPlanes:NULL
              pixelsWide:nx pixelsHigh:ny bitsPerSample:bps
              samplesPerPixel:spp hasAlpha:NO isPlanar:NO
              colorSpaceName:csp
              bytesPerRow:nx*spp*2 bitsPerPixel:spp*bps ];
    
    if (image2 == NULL)
    {
        NSLog(@"Image cannot be constructed by NSBitmapImageRep!");
        return NULL;
    }
    
    printf("Try to read the data\n");
    float* tmp = (float*) malloc(sizeof(float)*channels*nx*ny);
    uint16 *data = (uint16*) image2.bitmapData;
    
    // reading image
    size_t check = fread( (void*) tmp, sizeof(float), nx*ny*channels, inimage);

    if (check != nx*ny*channels)
    {
        NSLog(@"Unfortunately, we read %ld instead of %ud (%udx%udx%ud) items", check, nx*ny*channels, nx, ny, channels);
        return NULL;
    }
    
    // close image
    fclose(inimage);
    

    #define GAMMA
    
    // convert into float and apply gamma of 2.2 to boost float representation    
    #ifdef GAMMA
    uint16 maxG = -1;
    float sav;

    #endif
    
    // computing maximum value
    float max = 0, tmpf = 0;
    for (unsigned int j=0; j < nx*ny*channels; j += nx*channels)
        for (unsigned int i=0; i < nx*channels; i += channels)
            for(unsigned int k=0; k < channels; k++)
                if ( (tmpf = tmp[j+i+k]) > max)
                    max = tmpf;

    
    float factor = 65535 / max;
    NSLog(@"Maximum is %f and factor computed as %f",max, factor);
    
    for (unsigned int j=0; j < nx*ny*channels; j += nx*channels)
        for (unsigned int i=0; i < nx*channels; i += channels)
        {
            for(unsigned int k=0; k < channels; k++)
            {
#ifdef GAMMA
                sav = pow(tmp[j+i+k],0.45454545) * factor;
                if (sav > maxG)
                    data[j+i+k] = maxG;
                else
                    data[j+i+k] = (uint16) sav;
#else
                data[j+i+k] = (uint16) (tmp[j+i+k] * factor);
#endif
            }
        }
    
    
    NSLog(@"Image constructed and image pointer is %p\n", image2);
    
    free(tmp);
    return [image2 CGImage];
}

- (CGImageRef)loadPPM:(const char*)filename
{
    FILE   *inimage;        // input file
    
    // resetting dimensions and counters
    nx = 0; ny = 0; channels = 1;
 	cp = 0;
   
    // open image, which exists and has the correct
    // format (previously checked in 'load')
    inimage = fopen( filename,"r");
    
    magicNumber = [self pbm_readpbminit: inimage];
    
    if (PPM_FORMAT_TYPE(magicNumber) == -1) {
        return NULL;
    }
    
    NSLog(@"Reading 0x%X Image with %dx%d %d\n", (unsigned int)magicNumber, nx, ny, cp);
	
    spp = channels;
    
    NSString* csp = NSDeviceRGBColorSpace;
    
    if (channels == 1)
        csp = NSDeviceWhiteColorSpace;
    
    
    NSBitmapImageRep *image2 = NULL;
    image2 = [[NSBitmapImageRep alloc]
              initWithBitmapDataPlanes:NULL
              pixelsWide:nx pixelsHigh:ny bitsPerSample:bps
              samplesPerPixel:spp hasAlpha:NO isPlanar:NO
              colorSpaceName:csp
              bytesPerRow:nx*spp*(bps/8) bitsPerPixel:spp*bps ];
    
    if (image2 == NULL)
    {
        NSLog(@"Image cannot be constructed by NSBitmapImageRep!");
        return NULL;
    }
    
    size_t check;
    
    switch (magicNumber){
    case PGM_FORMAT: 
            readP2(inimage, image2, nx, ny, maxval); 
            break;
    case PBM_FORMAT: 
            readP1(inimage, image2, nx, ny); 
            break;
    default:
        // reading image
        check = fread( (void*) [image2 bitmapData], bps / 8, nx*ny*channels, inimage);

        if (check != nx*ny*channels)
        {
            NSLog(@"Unfortunately, we read %ld instead of %d (%dx%dx%d) items", check, nx*ny*channels, nx, ny, channels);
            return NULL;
        }

        NSLog(@"Image has been read and has size %dx%dx%d\n",nx, ny, channels);
    }
    
    fclose(inimage);
    return [image2 CGImage];
}


- (CGImageRef)load:(CFStringRef)filenameCF
{
    FILE   *inimage;        // input file
    char   row[80];         // buffer
    
    // const char *filename = CFStringGetCStringPtr(filenameCF, CFStringGetSystemEncoding());
    char *fullPath;
    char filename[512];;
    
    Boolean conversionResult;
    CFStringEncoding encodingMethod;

    
    NSLog(@"This is our new fancy Picture Map Reader (PMReader) ImageClass");

    // This is for ensuring safer operation. When CFStringGetCStringPtr() fails,
    // it tries CFStringGetCString().
     
    encodingMethod = CFStringGetFastestEncoding(filenameCF);
     
    // 1st try for English system
    fullPath = (char*)CFStringGetCStringPtr(filenameCF, encodingMethod);

    // for safer operation.
    if( fullPath == NULL )
    {
        CFIndex length = CFStringGetMaximumSizeOfFileSystemRepresentation(filenameCF);
        fullPath = (char *)malloc( length + 1 );
        conversionResult = CFStringGetFileSystemRepresentation(filenameCF, fullPath, length);
        //conversionResult = CFStringGetCString(filenameCF, fullPath, length, kCFStringEncodingASCII );
        
        strcpy( filename, fullPath );
        
        free( fullPath );
    }
    else
        strcpy( filename, fullPath );
    
    
    // open image read-only
    inimage = fopen( filename,"r");
    
    // file cannot be opened
    if ( inimage == NULL )
    {
        NSLog(@"ERROR: The file '%@' cannot be opened!\n", filenameCF);
        return NULL;
    }
    
    // First entry is the filetype
    fgets (row, 80, inimage);
    
    // close image
    fclose(inimage);
    
    // first char has to be a 'P'
    if ( row[0] != 'P' )
    {
        NSLog(@"File '%@' is not a valid bitmap fileformat!", filenameCF);
        return NULL;
    }
    
    NSLog(@"Row is %s", row);
    switch (row[1]) {
        case 'f':
        case 'F':
            return [self loadPFM:filename];
            break;
            
        case '6':
        case '5':
        case '2':
        case '1':
            return [self loadPPM:filename];
            break;
            
            
        default:
            NSLog(@"Cannot read type P%c\n",row[1]);
            break;
    }
    
    
    return NULL;
}

@end
