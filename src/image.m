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

#import "image.h"
#include <stdio.h>


@implementation PMReader

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
    char   row[80];         // buffer    
    
    // resetting dimensions and counters
    nx = 0; ny = 0; channels = 1;
    
    // open image, which exists and has the correct
    // format (previously checked in 'load')
    inimage = fopen( filename,"r");
    
    // First entry is the filetype
    fgets (row, 80, inimage);
    
    
    // check if we have monochrome or not
    if ( row[1] == '6' )
        channels = 3;
    
    size_t clines = 20;
    size_t counter = 0;
    size_t pos = 0;
    char comments[80*clines];
    memset((void*) comments, 0, sizeof(char)*80*clines);
    
    
    // Second Entry could be the size of the image an it could be a comment
    fgets (row, 80, inimage);
    while (row[0]=='#')
    {
        if (counter < clines)
        {
            printf("Reading comment %d to pointer %d\n  %s", (int) counter, (int) counter*80, row );
            strncpy(&comments[pos], row, strlen(row));
            pos += strlen(row);
            counter +=1;
        }
    
        fgets(row,80,inimage);

    }
    
    printf("-----------------------\n%s\n-----------------------\n",comments);
    
    NSString* str = [[NSString alloc] initWithCString:comments encoding:CFStringGetSystemEncoding()];
    
    NSLog(@"We have: \"%@\"",str);
    
    
	NSString* tmp = [NSString stringWithUTF8String: row];
    NSArray *values = [tmp componentsSeparatedByString: @" "];
	
	cp = 0;
    
	// if only dimensions are in this line
    if ([values count] == 2) {
		  // Saving image dimensions
		NSLog(@"We found %u parameters\n", (unsigned int) [values count]);
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
    
    
		// colors
		sscanf (row, "%d", &cp);
    
    
		NSLog(@"Image has been read and has size %dx%dx%d\n",nx, ny, channels);
	} else {
		NSLog(@"We found %u parameters\n", (unsigned int)[values count]);
		// Saving image dimensions
		sscanf (row, "%d %d %d", &nx, &ny, &cp);
		printf("Reading Image with %dx%d %d\n",nx, ny, cp);
		if (ny == 0)
		{
			printf("Trying second line for dimensions in PFM file\n");
			fgets (row, 80, inimage);
			sscanf (row, "%d", &ny);
			printf("Reading Image with %dx%d\n",nx, ny);
		}
		
		NSLog(@"Image has been read and has size %dx%dx%d\n",nx, ny, channels);
	}
    
    spp = channels;
    bps = 8;
    
    if (cp > 255)
        bps = 16;
    
    NSLog(@"bps=%d",bps);
    
    if (cp > 65535)
    {
        NSLog(@"Colorvalues of %d exceeds 65535", cp);
        return NULL;
    }
    
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
    
    printf("Try to read the data\n");

    // reading image
    size_t check = fread( (void*) [image2 bitmapData], bps / 8, nx*ny*channels, inimage);
    
    if (check != nx*ny*channels)
    {
        NSLog(@"Unfortunately, we read %ld instead of %d (%dx%dx%d) items", check, nx*ny*channels, nx, ny, channels);
        return NULL;
    }
    
    // close image
    fclose(inimage);
    

    NSLog(@"Image constructed and image pointer is %p\n", image2);
    
    return [image2 CGImage];
}


- (CGImageRef)load:(CFStringRef)filenameCF
{
    FILE   *inimage;        // input file
    char   row[80];         // buffer
    
    const char *filename = CFStringGetCStringPtr(filenameCF, CFStringGetSystemEncoding());
    
    NSLog(@"This is our new fancy ImageClass");
    
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
    
    switch (row[1]) {
        case 'f':
        case 'F':
            return [self loadPFM:filename];
            break;
            
        case '6':
        case '5':
            return [self loadPPM:filename];
            break;
            
            
        default:
            NSLog(@"Cannot read type P%c\n",row[1]);
            break;
    }
    
    
    return NULL;
}

@end
