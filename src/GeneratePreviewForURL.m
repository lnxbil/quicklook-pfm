#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import <AppKit/NSImage.h>

#import "image.h"

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */


OSStatus GeneratePreviewForURL( void *thisInterface, 
                               QLPreviewRequestRef preview, 
                               CFURLRef url, 
                               CFStringRef contentTypeUTI, 
                               CFDictionaryRef options)
{
    NSDate *startDate = [NSDate date];

    if (QLPreviewRequestIsCancelled(preview))
        return noErr;
    
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    CFStringRef file = CFURLCopyFileSystemPath(url,kCFURLPOSIXPathStyle);
    
    NSLog(@"file is now '%@'\n",file);
    
    if (QLPreviewRequestIsCancelled(preview))
        return noErr;
    
    
    PMReader* reader = [[PMReader alloc] init];
    CGImageRef image = [reader load:file];
    
    if (image == NULL)
    {
        NSLog(@"Image cannot be read :-(");
        return noErr;
    }
    
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    NSSize size = {width,height};

    
    
    if (QLPreviewRequestIsCancelled(preview))
        return noErr;

    // Preview will be drawn in a vectorized context
    CGContextRef cgContext = QLPreviewRequestCreateContext(preview, *(CGSize *)&size, true, NULL);
    
    CGRect rect = CGRectMake(0,0, width, height);
    
    CGContextDrawImage(cgContext, rect, image);
    
    NSLog(@"We have size %ldx%ld\n",width,height);
    

    QLPreviewRequestFlushContext(preview, cgContext);
    CFRelease(cgContext);
    
    
    NSLog(@"Finished preview in %.3f sec", -[startDate timeIntervalSinceNow] );

    
    [pool release];
    return noErr;
}


void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}

