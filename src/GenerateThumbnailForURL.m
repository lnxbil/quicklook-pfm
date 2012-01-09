#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import <AppKit/NSImage.h>

#import "image.h"

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

CGContextRef CreateARGBBitmapContext (CGSize size)
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    size_t pixelsWide = (size_t) size.width; //CGImageGetWidth(inImage);
    size_t pixelsHigh = (size_t) size.height; //CGImageGetHeight(inImage);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (pixelsWide * 4);
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
    
    // Use the generic RGB color space.
    // FIXME: Das verstehe ich net. Die Doku sagt nicht, dass es Deprecated ist und
    //        gibt auch keine Auswahlmöglichkeit an :-(
    colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    if (colorSpace == NULL)
    {
        NSLog(@"Error allocating color space\n");
        return NULL;
    }
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL) 
    {
        NSLog(@"Memory not allocated!");
        CGColorSpaceRelease( colorSpace );
        return NULL;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits 
    // per component. Regardless of what the source image format is 
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaPremultipliedFirst);
    if (context == NULL)
    {
        free (bitmapData);
        NSLog(@"Context not created!");
    }
    
    // Make sure and release colorspace before returning
    CGColorSpaceRelease( colorSpace );
    
    return context;
}




OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    NSDate *startDate = [NSDate date];
    
    
    if (QLThumbnailRequestIsCancelled(thumbnail))
        return noErr;
    
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    CFStringRef file = CFURLCopyFileSystemPath(url,kCFURLPOSIXPathStyle);
    
    NSLog(@"file is now '%@'\n",file);
    
    if (QLThumbnailRequestIsCancelled(thumbnail))
        return noErr;
    
    NSDate *readDate = [NSDate date];
    PMReader* reader = [[PMReader alloc] init];
    CGImageRef image = [reader load:file];
    
    NSLog(@"Read time %.3f sec", -[readDate timeIntervalSinceNow] );
    
    if (image == NULL)
    {
        NSLog(@"Image cannot be read :-(");
        return noErr;
    }

    
    if (QLThumbnailRequestIsCancelled(thumbnail))
        return noErr;
    
    // SIZE STUFF
    size_t w = CGImageGetWidth(image);
    size_t h = CGImageGetHeight(image);
    
    float max = 512;
    
    NSLog(@"Got %ldx%ld for resizing with aspect %f",w,h, (float) w / (float) h);
    size_t resw = w;
    size_t resh = h;
    
    // if image is already smaller or equal to the screen, do nothing
    if ((h > max) || (w > max))
    {
        
        float f;
        
        // portrait mode
        if (w <= h)
        {
            f = max / h;
            if ( w * f > max)
                f = max / w;
            // landscape mode
        } else {
            f = max / w;
            
            if ( h * f > max)
                f = max / h;
        }
        
        resw = (size_t) floor(w*f);
        resh = (size_t) floor(h*f);
        
        if (resw == 0)
            resw = 1;

        if (resh == 0)
            resh = 1;
        
        NSLog(@"Finally, we have %ldx%ld for resizing with aspect %f",resw, resh, resw / (float) resh);
        
        
    }
    
    CGSize size = CGSizeMake(resw, resh);
    CGRect rect = {{0,0},{size.width,size.height}}; 
    
    
    CGContextRef cgctx = CreateARGBBitmapContext(size);
    CGContextDrawImage(cgctx, rect, image); 
    CGImageRef newCGImage = CGBitmapContextCreateImage(cgctx);
    CGContextRelease(cgctx);
    

    
    
    QLThumbnailRequestSetImage(thumbnail, newCGImage, NULL);
    
    // Releasing image
    CGImageRelease(newCGImage);
    
    NSLog(@"Finished preview in %.3f sec", -[startDate timeIntervalSinceNow] );
    
    [reader release];
    [pool release];
    return noErr;
    
}


void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}

