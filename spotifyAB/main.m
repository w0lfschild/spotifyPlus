//
//  main.m
//  spotifyAB
//
//  Created by Wolfgang Baird on 2/5/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import "main.h"

struct TrackMetadata;

main *plugin;
NSImage *myImage;
NSUserDefaults *sharedPrefs;
bool banners = false;
bool showArt = true;
bool muteAds = true;
bool muteVid = false;
int iconArt = 0;
int sleepTime = 1000000;

@implementation main

+ (main*) sharedInstance
{
    static main* plugin = nil;
    
    if (plugin == nil)
        plugin = [[main alloc] init];
    
    return plugin;
}

+ (void)load
{
    plugin = [main sharedInstance];
    
    if (!sharedPrefs)
        sharedPrefs = [NSUserDefaults standardUserDefaults];
    
    if ([sharedPrefs objectForKey:@"muteAds"] == nil)
        [sharedPrefs setBool:true forKey:@"muteAds"];
    
    if ([sharedPrefs objectForKey:@"muteVid"] == nil)
        [sharedPrefs setBool:false forKey:@"muteVid"];
    
    if ([sharedPrefs objectForKey:@"banners"] == nil)
        [sharedPrefs setBool:false forKey:@"banners"];
    
    if ([sharedPrefs objectForKey:@"showArt"] == nil)
        [sharedPrefs setBool:true forKey:@"showArt"];
    
    if ([sharedPrefs objectForKey:@"iconArt"] == nil)
        [sharedPrefs setInteger:0 forKey:@"iconArt"];
    
    
    muteAds = [[sharedPrefs objectForKey:@"muteAds"] boolValue];
    muteVid = [[sharedPrefs objectForKey:@"muteVid"] boolValue];
    banners = [[sharedPrefs objectForKey:@"banners"] boolValue];
    showArt = [[sharedPrefs objectForKey:@"showArt"] boolValue];
    iconArt = (int)[sharedPrefs integerForKey:@"iconArt"];
    
    [plugin setMenu];
    [plugin pollThread];
    
    NSLog(@"spotiHack loaded...");
}

- (BOOL) runProcessAsAdministrator:(NSString*)scriptPath
                     withArguments:(NSArray *)arguments
                            output:(NSString **)output
                  errorDescription:(NSString **)errorDescription {
    
    NSString * allArgs = [arguments componentsJoinedByString:@" "];
    NSString * fullScript = [NSString stringWithFormat:@"'%@' %@", scriptPath, allArgs];
    
    NSDictionary *errorInfo = [NSDictionary new];
    NSString *script =  [NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges", fullScript];
    
    NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
    NSAppleEventDescriptor * eventResult = [appleScript executeAndReturnError:&errorInfo];
    
    // Check errorInfo
    if (! eventResult)
    {
        // Describe common errors
        *errorDescription = nil;
        if ([errorInfo valueForKey:NSAppleScriptErrorNumber])
        {
            NSNumber * errorNumber = (NSNumber *)[errorInfo valueForKey:NSAppleScriptErrorNumber];
            if ([errorNumber intValue] == -128)
                *errorDescription = @"The administrator password is required to do this.";
        }
        
        // Set error message from provided message
        if (*errorDescription == nil)
        {
            if ([errorInfo valueForKey:NSAppleScriptErrorMessage])
                *errorDescription =  (NSString *)[errorInfo valueForKey:NSAppleScriptErrorMessage];
        }
        
        return NO;
    }
    else
    {
        // Set output to the AppleScript's output
        *output = [eventResult stringValue];
        
        return YES;
    }
}

- (void)setMenu
{
    NSMenu *appMenu = [NSApp mainMenu];
    NSMenuItem *playBackItem = [appMenu itemAtIndex:4];
    NSMenu *playBack = [playBackItem submenu];

    // Ads submenu
    NSMenuItem *adsMenu = [[NSMenuItem alloc] init];
    [adsMenu setTitle:@"Ad muting"];
    NSMenu *submenuAds = [[NSMenu alloc] init];
    [submenuAds setAutoenablesItems:NO];
    [[submenuAds addItemWithTitle:@"Mute Audio Ads" action:@selector(setAdsMuting:) keyEquivalent:@""] setTarget:plugin];
    [[submenuAds addItemWithTitle:@"Mute Video Ads" action:@selector(setVidMuting:) keyEquivalent:@""] setTarget:plugin];
    NSArray *adsMenuArray = [submenuAds itemArray];
    [[adsMenuArray objectAtIndex:0] setState:muteAds];
    [[adsMenuArray objectAtIndex:1] setState:muteVid];
    [[adsMenuArray objectAtIndex:1] setEnabled:false];
    [adsMenu setSubmenu:submenuAds];
    
    // Icon art submenu
    NSMenuItem *artMenu = [[NSMenuItem alloc] init];
    [artMenu setTitle:@"Icon Art"];
    NSMenu *submenuArt = [[NSMenu alloc] init];
    [[submenuArt addItemWithTitle:@"Stock icon art" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuArt addItemWithTitle:@"Tilted icon art" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuArt addItemWithTitle:@"Circular icon art" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    if ((2 - iconArt) >= 0) [[[submenuArt itemArray] objectAtIndex:(2 - iconArt)] setState:NSOnState];
    [artMenu setSubmenu:submenuArt];
    
    // spotifyAB submenu
    NSMenu *submenuRoot = [[NSMenu alloc] init];
    [[submenuRoot addItemWithTitle:@"Show icon art" action:@selector(setShowArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuRoot addItemWithTitle:@"Block All Ads" action:@selector(editHostFile:) keyEquivalent:@""] setTarget:plugin];
    [submenuRoot addItem:adsMenu];
    [submenuRoot addItem:artMenu];
    [[[submenuRoot itemArray] objectAtIndex:0] setState:showArt];
    [[[submenuRoot itemArray] objectAtIndex:1] setState:banners];
    
    // spotifyAB meun item
    NSMenuItem *mainItem = [[NSMenuItem alloc] init];
    [mainItem setTitle:@"spotifyAB"];
    [mainItem setSubmenu:submenuRoot];
    
    // Add spotifyAB menu to playback menu
    [playBack addItem:[NSMenuItem separatorItem]];
    [playBack addItem:mainItem];
    
    NSMenuItem *spotifyItem = [appMenu itemAtIndex:0];
    NSMenu *spotify = [spotifyItem submenu];
//    [spotify addItem:[NSMenuItem separatorItem]];
    [[spotify addItemWithTitle:@"Restart" action:@selector(restartMe) keyEquivalent:@""] setTarget:plugin];
    
//    NSMenu *dock = [[NSApp delegate] applicationDockMenu:spotify];
//    NSLog(@"%@", dock);
}

- (IBAction)editHostFile:(id)sender
{
    NSString * output = nil;
    NSString * processErrorDescription = nil;
    BOOL success = false;
    if (!banners)
    {
        NSArray *args = [[NSArray alloc] initWithObjects:@"\\\"0.0.0.0 pubads.g.doubleclick.net\n0.0.0.0 securepubads.g.doubleclick.net\\\"", @">>", @"/private/etc/hosts",  nil];
        success = [plugin runProcessAsAdministrator:@"/bin/echo" withArguments:args output:&output errorDescription:&processErrorDescription];
    } else {
        NSArray *args = [[NSArray alloc] initWithObjects:@"-i", @"''", @"'/g.doubleclick.net/d'", @"/private/etc/hosts", nil];
        success = [plugin runProcessAsAdministrator:@"/usr/bin/sed" withArguments:args output:&output errorDescription:&processErrorDescription];
    }
    if (!success) // Process failed to run
    {
        NSLog(@"%@", processErrorDescription);
    }
    else
    {
        NSLog(@"Hosts file edited");
        
        banners = !banners;
        [sender setState:banners];
        [sharedPrefs setBool:banners forKey:@"banners"];
        [plugin restartMe];
    }

}

- (void)restartMe
{
    float seconds = 3.0;
    NSTask *task = [[NSTask alloc] init];
    NSMutableArray *args = [NSMutableArray array];
    [args addObject:@"-c"];
    [args addObject:[NSString stringWithFormat:@"sleep %f; open \"%@\"", seconds, [[NSBundle mainBundle] bundlePath]]];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:args];
    [task launch];
    [NSApp terminate:nil];
}

- (IBAction)setAdsMuting:(id)sender
{
    muteAds = !muteAds;
    [sender setState:muteAds];
    [sharedPrefs setBool:muteAds forKey:@"muteAds"];
}

- (IBAction)setVidMuting:(id)sender
{
    muteVid = !muteVid;
    [sender setState:muteVid];
    [sharedPrefs setBool:muteVid forKey:@"muteVid"];
}

- (IBAction)setShowArt:(id)sender
{
    showArt = !showArt;
    [sender setState:showArt];
    [sharedPrefs setBool:showArt forKey:@"showArt"];
    
    if (showArt)
    {
        NSImage *modifiedIcon = [plugin createIconImage:myImage :iconArt];
        [NSApp setApplicationIconImage:modifiedIcon];
    } else {
        [NSApp setApplicationIconImage:nil];
    }
}

- (IBAction)setIconArt:(id)sender
{
    NSMenu *menu = [sender menu];
    NSArray *menuArray = [menu itemArray];
    int objectIndex = (int)[menuArray indexOfObject:sender];
    iconArt = 2 - objectIndex;
    for (NSMenuItem *item in menuArray) {
        if ([item isEqualTo:sender])
            [item setState:NSOnState];
        else
            [item setState:NSOffState];
    }
    NSImage *modifiedIcon = [plugin createIconImage:myImage :iconArt];
    [NSApp setApplicationIconImage:modifiedIcon];
    [sharedPrefs setInteger:iconArt forKey:@"iconArt"];
}

- (NSImage*)imageRotatedByDegrees:(CGFloat)degrees :(NSImage*)img
{
    NSSize    size = [img size];
    NSSize    newSize = NSMakeSize( size.width + 40,
                                   size.height + 40 );
    
//    NSSize rotatedSize = NSMakeSize(img.size.height, img.size.width) ;
    NSImage* rotatedImage = [[NSImage alloc] initWithSize:newSize] ;
    
    NSAffineTransform* transform = [NSAffineTransform transform] ;
    
    // In order to avoid clipping the image, translate
    // the coordinate system to its center
//    [transform translateXBy:+img.size.width/2
//                        yBy:+img.size.height/2] ;
    
    [transform translateXBy:img.size.width / 2
                        yBy:img.size.height / 2];
    
    // then rotate
    [transform rotateByDegrees:degrees] ;
    
    // Then translate the origin system back to
    // the bottom left
    [transform translateXBy:-size.width/2
                        yBy:-size.height/2] ;
    
//
    
    [rotatedImage lockFocus] ;
    [transform concat] ;
    [img drawAtPoint:NSMakePoint(15,10)
             fromRect:NSZeroRect
            operation:NSCompositeCopy
             fraction:1.0] ;
    [rotatedImage unlockFocus] ;
    
    return rotatedImage;
}

- (CGImageRef)createCGImageFromFile:(NSString*)path
{
    // Get the URL for the pathname passed to the function.
    NSURL *url = [NSURL fileURLWithPath:path];
    CGImageRef        myImage = NULL;
    CGImageSourceRef  myImageSource;
    CFDictionaryRef   myOptions = NULL;
    CFStringRef       myKeys[2];
    CFTypeRef         myValues[2];
    
    // Set up options if you want them. The options here are for
    // caching the image in a decoded form and for using floating-point
    // values if the image format supports them.
    myKeys[0] = kCGImageSourceShouldCache;
    myValues[0] = (CFTypeRef)kCFBooleanTrue;
    myKeys[1] = kCGImageSourceShouldAllowFloat;
    myValues[1] = (CFTypeRef)kCFBooleanTrue;
    // Create the dictionary
    myOptions = CFDictionaryCreate(NULL, (const void **) myKeys,
                                   (const void **) myValues, 2,
                                   &kCFTypeDictionaryKeyCallBacks,
                                   & kCFTypeDictionaryValueCallBacks);
    // Create an image source from the URL.
    myImageSource = CGImageSourceCreateWithURL((CFURLRef)url, myOptions);
    CFRelease(myOptions);
    // Make sure the image source exists before continuing
    if (myImageSource == NULL){
        fprintf(stderr, "Image source is NULL.");
        return  NULL;
    }
    // Create an image from the first item in the image source.
    myImage = CGImageSourceCreateImageAtIndex(myImageSource,
                                              0,
                                              NULL);
    
    CFRelease(myImageSource);
    // Make sure the image exists before continuing
    if (myImage == NULL){
        fprintf(stderr, "Image not created from image source.");
        return NULL;
    }
    
    return myImage;
}

- (NSImage*)createIconImage:(NSImage*)stockCover :(int)resultType
{
    // 0 = rounded
    // 1 = tilded
    // 2 = square
//    NSString *myLittleCLIToolPath = NSProcessInfo.processInfo.arguments[0];
    NSString *maskPath = @"/Library/Application Support/SIMBL/Plugins/spotifyAB.bundle/Contents/Resources/ModernMask.tif";
    NSString *overlayPath = @"/Library/Application Support/SIMBL/Plugins/spotifyAB.bundle/Contents/Resources/ModernOverlay.png";
    NSImage *resultIMG = [[NSImage alloc] init];
    
    if (resultType == 0)
    {
        [[stockCover TIFFRepresentation] writeToFile:@"/tmp/spotifyCover.tif" atomically:YES];
        CGImageRef imgRef = [plugin createCGImageFromFile:@"/tmp/spotifyCover.tif"];
        CGImageRef maskRef = [plugin createCGImageFromFile:maskPath];
        CGImageRef actualMask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                                  CGImageGetHeight(maskRef),
                                                  CGImageGetBitsPerComponent(maskRef),
                                                  CGImageGetBitsPerPixel(maskRef),
                                                  CGImageGetBytesPerRow(maskRef),
                                                  CGImageGetDataProvider(maskRef), NULL, false);
        CGImageRef masked = CGImageCreateWithMask(imgRef, actualMask);
        NSImage *rounded = [[NSImage alloc] initWithCGImage:masked size:NSZeroSize];
        NSImage *background = rounded;
        NSImage *overlay = [[NSImage alloc] initByReferencingFile:overlayPath];
        NSImage *newImage = [[NSImage alloc] initWithSize:[background size]];
        [newImage lockFocus];
        CGRect newImageRect = CGRectZero;
        newImageRect.size = [newImage size];
        [background drawInRect:newImageRect];
        [overlay drawInRect:newImageRect];
        [newImage unlockFocus];
        resultIMG = newImage;
    }
    else if (resultType == 1)
    {
        NSSize dims = [[NSApp dockTile] size];
        dims.width *= 0.9;
        dims.height *= 0.9;
        NSImage *smallImage = [[NSImage alloc] initWithSize: dims];
        [smallImage lockFocus];
        [stockCover setSize: dims];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [stockCover drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, dims.width, dims.height) operation:NSCompositeCopy fraction:1.0];
        [smallImage unlockFocus];
        smallImage = [plugin imageRotatedByDegrees:15.00 :smallImage];
        resultIMG = smallImage;
    }
    else
    {
        resultIMG = stockCover;
    }
    return resultIMG;
}

- (void)pollThread
{
    //osascript -e "output muted of (get volume settings)"
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        ClientApplication *thisApp = [NSApplication sharedApplication];
        SPAppleScriptTrack *track = [thisApp currentTrack];
        NSNumber *playState = [thisApp playerState];
        NSString *currentTrack = @"";
        NSString *trackURL = @"";
        NSImage  *trackImage = [[NSImage alloc] init];
        NSNumber *appVolume = [thisApp soundVolume];
        bool imageFetched = false;
        bool isAD = false;
        bool isMuted = false;
        bool isSysmuted = false;
        bool isPaused = false;
        
        while (true) {
            playState = [thisApp playerState];
            NSLog(@"%@", playState);
            
            if ([playState isEqualToNumber:[NSNumber numberWithInt:2]]) {
                
                // Audio Player paused
                
                [NSApp setApplicationIconImage:nil];
                isPaused = true;
                if (isMuted)
                {
                    isMuted = false;
                    [thisApp setSoundVolume:appVolume];
                }
                
                [[NSApp dockTile] setBadgeLabel:@"Paused"];
                
                // Video AD (Not sure how to detect right now)
//                if (muteVid)
//                {
//                    if (!isSysmuted)
//                    {
//                        isSysmuted = true;
//                        system("osascript -e \"set volume with output muted\"");
//                    }
//                }
//                else
//                {
//                    if (isSysmuted)
//                    {
//                        isSysmuted = false;
//                        system("osascript -e \"set volume without output muted\"");
//                    }
//                }
                
            } else if ([playState isEqualToNumber:[NSNumber numberWithInt:1]]) {
                
                // Audio Player active
                
                track = [thisApp currentTrack];
                trackURL = [track spotifyURL];
                NSRange range = [trackURL rangeOfString:@"spotify:ad"];
                if(range.location != NSNotFound)
                {
                    isAD = true;
                } else {
                    isAD = false;
                }
                
                if (isAD)
                {
                    
                    // Playing Audio AD
                    
                    if (muteAds)
                    {
                        if (!isMuted)
                        {
                            isMuted = true;
                            appVolume = [thisApp soundVolume];
                            [sharedPrefs setInteger:[appVolume integerValue] forKey:@"trackVol"];
                            [thisApp setSoundVolume:[NSNumber numberWithInt:0]];
                        }
                    }
                    else
                    {
                        if (isMuted)
                        {
                            isMuted = false;
                            [thisApp setSoundVolume:appVolume];
                        }
                    }
                    [NSApp setApplicationIconImage:nil];
                    
                } else {
                    
                    // Playing music
                    
                    if (isSysmuted)
                    {
                        isSysmuted = false;
                        system("osascript -e \"set volume without output muted\"");
                    }
                    
                    if (isMuted)
                    {
                        isMuted = false;
                        [thisApp setSoundVolume:appVolume];
                    }
                    
                    if (showArt)
                    {
                        NSString *trackURL = track.spotifyURL;
                        if (![currentTrack isEqualToString:trackURL])
                        {
                            currentTrack = [NSString stringWithFormat:@"%@", trackURL];
                            NSString *combinedURL = [NSString stringWithFormat:@"https://embed.spotify.com/oembed/?url=%@", trackURL];
                            NSURL *targetURL = [NSURL URLWithString:combinedURL];
                            NSURLRequest *request = [NSURLRequest requestWithURL:targetURL];
                            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                            NSString *fixedString = [dataString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
                            fixedString = [fixedString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                            NSArray *urlComponents = [fixedString componentsSeparatedByString:@","];
                            NSString *iconURL = @"";
                            if ([urlComponents count] >= 7)
                                iconURL = [urlComponents objectAtIndex:7];
                            NSArray *iconComponents = [iconURL componentsSeparatedByString:@":"];
                            NSString *iconURLFixed = [NSString stringWithFormat:@"https:%@", [iconComponents lastObject]];
                            myImage = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:iconURLFixed]]];
                            NSLog(@"%@", iconURLFixed);
                            
                            if ( myImage )
                            {
                                NSImage *modifiedIcon = [plugin createIconImage:myImage :iconArt];
                                [NSApp setApplicationIconImage:modifiedIcon];
                                trackImage = modifiedIcon;
                                imageFetched = true;
                            } else {
                                imageFetched = false;
                            }
                        } else {
                            if (imageFetched)
                                if (isPaused) {
                                    [NSApp setApplicationIconImage:trackImage];
                                }
                        }
                    } else {
                        [NSApp setApplicationIconImage:nil];
                    }
                    
                    isPaused = false;
                }
                
                if ((NSNumber *)[thisApp soundVolume] < [NSNumber numberWithFloat:1.0])
                {
                    [[NSApp dockTile] setBadgeLabel:@"Muted"];
                } else {
                    [[NSApp dockTile] setBadgeLabel:nil];
                }
            }
            usleep(sleepTime);
        }
    });
}

@end