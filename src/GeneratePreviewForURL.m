/*
 *  CreatePreviewForURL.m
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

