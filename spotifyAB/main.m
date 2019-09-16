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
NSMenu *spotifyPlus;
NSImage *myImage;
NSArray *pollTime;
NSUserDefaults *sharedPrefs;
bool banners = false;
bool showArt = true;
bool muteAds = true;
bool muteVid = false;
bool showBadge = true;
int iconArt = 0;
int sleepTime = 1000000;
NSString *overlayPath;
NSString *classicPath;
ClientMenuHandler *cmh;

NSUInteger titlePos = 0;

@implementation main

+ (main*) sharedInstance {
    static main* plugin = nil;
    
    if (plugin == nil)
        plugin = [[main alloc] init];
    
    return plugin;
}

+ (void)load {
    plugin = [main sharedInstance];
    
    if (!sharedPrefs)
        sharedPrefs = [NSUserDefaults standardUserDefaults];
    
    if ([sharedPrefs objectForKey:@"showBadge"] == nil)
        [sharedPrefs setBool:true forKey:@"showBadge"];
    
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
    
    if ([sharedPrefs objectForKey:@"pollRate"] == nil)
        [sharedPrefs setInteger:1000000 forKey:@"pollRate"];
    
    
    showBadge = [[sharedPrefs objectForKey:@"showBadge"] boolValue];
    muteAds = [[sharedPrefs objectForKey:@"muteAds"] boolValue];
    muteVid = [[sharedPrefs objectForKey:@"muteVid"] boolValue];
    banners = [[sharedPrefs objectForKey:@"banners"] boolValue];
    showArt = [[sharedPrefs objectForKey:@"showArt"] boolValue];
    iconArt = (int)[sharedPrefs integerForKey:@"iconArt"];
    sleepTime = (int)[sharedPrefs integerForKey:@"pollRate"];
    pollTime = [[NSArray alloc] initWithObjects:@"500000", @"1000000", @"2000000", @"3000000", @"5000000", nil];
    
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

- (void)setMenu {
    NSMenu* mainMenu = [NSApp mainMenu];
    spotifyPlus = [plugin spotPlusMenu];
    NSMenuItem* newItem = [[NSMenuItem alloc] initWithTitle:@"Spotify+" action:nil keyEquivalent:@""];
    [newItem setSubmenu:spotifyPlus];
    [mainMenu insertItem:newItem atIndex:5];
}

- (void)restartMe {
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

- (IBAction)editHostFile:(id)sender {
    NSString * output = nil;
    NSString * processErrorDescription = nil;
    BOOL success = false;
    if (!banners) {
        NSArray *args = [[NSArray alloc] initWithObjects:@"\\\"\
                         0.0.0.0 pubads.g.doubleclick.net\n\
                         0.0.0.0 securepubads.g.doubleclick.net\n\
                         0.0.0.0 spclient.wg.spotify.com\\\"", @">>", @"/private/etc/hosts",  nil];
        success = [plugin runProcessAsAdministrator:@"/bin/echo" withArguments:args output:&output errorDescription:&processErrorDescription];
    } else {
        NSArray *args = [[NSArray alloc] initWithObjects:@"-i", @"''", @"'/g.doubleclick.net/d'", @"/private/etc/hosts", nil];
        success = [plugin runProcessAsAdministrator:@"/usr/bin/sed" withArguments:args output:&output errorDescription:&processErrorDescription];
        
        args = [[NSArray alloc] initWithObjects:@"-i", @"''", @"'/wg.spotify.com/d'", @"/private/etc/hosts", nil];
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
        [sharedPrefs setBool:banners forKey:@"banners"];
        [plugin updateMenu:spotifyPlus];
        [plugin restartMe];
    }
    
}

- (IBAction)toggleBadges:(id)sender {
    showBadge = !showBadge;
    [sharedPrefs setBool:showBadge forKey:@"showBadge"];
    if (!showBadge)
        [[NSApp dockTile] setBadgeLabel:nil];
    [plugin updateMenu:spotifyPlus];
}

- (IBAction)setAdsMuting:(id)sender {
    muteAds = !muteAds;
    [sharedPrefs setBool:muteAds forKey:@"muteAds"];
    [plugin updateMenu:spotifyPlus];
}

- (IBAction)setVidMuting:(id)sender {
    muteVid = !muteVid;
    [sharedPrefs setBool:muteVid forKey:@"muteVid"];
    [plugin updateMenu:spotifyPlus];
}

- (IBAction)setShowArt:(id)sender {
    showArt = !showArt;
    [sharedPrefs setBool:showArt forKey:@"showArt"];
    if (showArt) {
        NSImage *modifiedIcon = [plugin createIconImage:myImage :iconArt];
        [NSApp setApplicationIconImage:modifiedIcon];
    } else {
        [NSApp setApplicationIconImage:nil];
    }
    [plugin updateMenu:spotifyPlus];
}

- (IBAction)setIconArt:(id)sender {
    NSMenu *menu = [sender menu];
    NSArray *menuArray = [menu itemArray];
    iconArt = (int)[menuArray indexOfObject:sender];
    NSLog(@"Icon art: %d", iconArt);
    NSImage *modifiedIcon = [plugin createIconImage:myImage :iconArt];
    [NSApp setApplicationIconImage:modifiedIcon];
    [sharedPrefs setInteger:iconArt forKey:@"iconArt"];
    [plugin updateMenu:spotifyPlus];
}

- (IBAction)setPolling:(id)sender {
    NSMenu *menu = [sender menu];
    NSArray *menuArray = [menu itemArray];
    int objectIndex = (int)[menuArray indexOfObject:sender];
    sleepTime = [(NSString*)[pollTime objectAtIndex:objectIndex] intValue];
    [sharedPrefs setInteger:sleepTime forKey:@"pollRate"];
    [plugin updateMenu:spotifyPlus];
}

- (IBAction)checkUpdate:(id)sender {
    [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"org.w0lf.mySIMBL" options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:nil];
}

- (NSImage*)imageRotatedByDegrees:(CGFloat)degrees :(NSImage*)img {
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

- (NSImage*)roundCorners:(NSImage *)image :(float)shrink {
    NSImage *existingImage = image;
    NSSize newSize = [existingImage size];
    NSImage *composedImage = [[NSImage alloc] initWithSize:newSize];
    
    float imgW = newSize.width;
    float imgH = newSize.height;
    float xShift = (imgW - (imgW * shrink)) / 2;
    float yShift = (imgH - (imgH * shrink)) / 2;
    
    [composedImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    NSRect imageFrame = NSRectFromCGRect(CGRectMake(xShift, yShift, (imgW * shrink), (imgH * shrink)));
    NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundedRect:imageFrame xRadius:imgW yRadius:imgH];
    [clipPath setWindingRule:NSEvenOddWindingRule];
    [clipPath addClip];
    [image drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0, 0, imgW, imgH) operation:NSCompositeSourceOver fraction:1];
    [composedImage unlockFocus];
    
    return composedImage;
}

- (NSImage*)createIconImage:(NSImage*)stockCover :(int)resultType {
    // 0 = rounded
    // 1 = tilded
    // 2 = square
    //    NSString *myLittleCLIToolPath = NSProcessInfo.processInfo.arguments[0];
    NSImage *resultIMG = [[NSImage alloc] init];
    if (resultType == 0)
    {
        resultIMG = stockCover;
    }
    
    if (resultType == 1)
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
    
    if (resultType == 2)
    {
        if (![classicPath length])
        {
            classicPath = @"/tmp";
            NSBundle* bundle = [NSBundle bundleWithIdentifier:@"org.w0lf.spotiHack"];
            NSString* bundlePath = [bundle bundlePath];
            if ([bundlePath length])
                classicPath = [bundlePath stringByAppendingString:@"/Contents/Resources/ClassicOverlay.png"];
        }
        NSImage *rounded = [self roundCorners:stockCover :0.9];
        NSImage *background = rounded;
        NSImage *overlay = [[NSImage alloc] initByReferencingFile:classicPath];
        NSImage *newImage = [[NSImage alloc] initWithSize:[background size]];
        [newImage lockFocus];
        CGRect newImageRect = CGRectZero;
        newImageRect.size = [newImage size];
        [background drawInRect:newImageRect];
        [overlay drawInRect:newImageRect];
        [newImage unlockFocus];
        resultIMG = newImage;
    }
    
    if (resultType == 3)
    {
        if (![overlayPath length])
        {
            overlayPath = @"/tmp";
            NSBundle* bundle = [NSBundle bundleWithIdentifier:@"org.w0lf.spotiHack"];
            NSString* bundlePath = [bundle bundlePath];
            if ([bundlePath length])
                overlayPath = [bundlePath stringByAppendingString:@"/Contents/Resources/ModernOverlay.png"];
        }
        NSImage *rounded = [self roundCorners:stockCover :0.85];
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
    
    if (resultIMG == nil) {
        resultIMG = stockCover;
    }
    
    return resultIMG;
}

- (void)pollThread {
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
            //            NSLog(@"%@", playState);
            
            if ([playState isEqualToNumber:[NSNumber numberWithInt:2]]) {
                
                // Audio Player paused
                
                [NSApp setApplicationIconImage:nil];
                isPaused = true;
                if (isMuted)
                {
                    isMuted = false;
                    [thisApp setSoundVolume:appVolume];
                }
                
                if (showBadge)
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
                if(range.location != NSNotFound) {
                    isAD = true;
                } else {
                    isAD = false;
                }
                
                if (isAD)
                {
                    (SPNextTrackScriptCommand*)[NSScriptCommand performSelector:NSSelectorFromString(@"performDefaultImplementation")];
                    
                    NSNumber *num = [track duration];
                    num = @([num floatValue] / 1000);
//                    NSLog(@"%@ : %@", (NSNumber*)[NSApp playbackPosition], num);
                    [NSApp setPlaybackPosition:num];
                    
                    // Playing Audio AD
                    
//                    if (muteAds)
//                    {
//                        if (!isMuted)
//                        {
//                            isMuted = true;
//                            appVolume = [thisApp soundVolume];
//                            [sharedPrefs setInteger:[appVolume integerValue] forKey:@"trackVol"];
//                            [thisApp setSoundVolume:[NSNumber numberWithInt:0]];
//                        }
//                    }
//                    else
//                    {
//                        if (isMuted)
//                        {
//                            isMuted = false;
//                            [thisApp setSoundVolume:appVolume];
//                        }
//                    }
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
                            if ([urlComponents count] >= 8)
                                iconURL = [urlComponents objectAtIndex:8];
                            NSArray *iconComponents = [iconURL componentsSeparatedByString:@":"];
                            NSString *iconURLFixed = [NSString stringWithFormat:@"https:%@", [iconComponents lastObject]];
                            myImage = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:iconURLFixed]]];
//                            myImage = [[NSImage alloc] initWithData:track.cover];
//                            NSLog(@"log: %@", urlComponents);
                            
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
                
                if ([(NSNumber *)[thisApp soundVolume] doubleValue] < 1.000000) {
                    if (showBadge)
                        [[NSApp dockTile] setBadgeLabel:@"Muted"];
                } else {
                    [[NSApp dockTile] setBadgeLabel:nil];
//                    if (showBadge) {
//                        NSString *fullText = [NSString stringWithFormat:@"%@ - %@ -", track.title, track.artist];
//                        NSUInteger length = fullText.length - 1;
//                        NSUInteger final = titlePos + 8;
//                        NSString *partText = @"";
//                        if (8 > length) {
//                            partText = fullText;
//                        } else {
//                            if (final > length) {
//                                NSUInteger overlap = final - length;
//                                NSUInteger toEnd = length - titlePos;
//                                NSString *part1 = [fullText substringWithRange:NSMakeRange(titlePos, toEnd)];
//                                NSString *part2 = [fullText substringWithRange:NSMakeRange(0, overlap)];
//                                partText = [NSString stringWithFormat:@"%@%@", part1, part2];
//                            } else {
//                                partText = [fullText substringWithRange:NSMakeRange(titlePos, 8)];
//                            }
//                            titlePos++;
//                            if (titlePos == length)
//                                titlePos = 0;
//                        }
//                        NSLog(@"spot+ : %lu : %lu : %@ : %@", (unsigned long)titlePos, (unsigned long)final, partText, fullText);
//                        [[NSApp dockTile] setBadgeLabel:partText];
//                    } else {
//                        [[NSApp dockTile] setBadgeLabel:nil];
//                    }
                }
            }
            usleep(sleepTime);
        }
    });
}

- (NSMenu*)dockaddspotPlus:(NSMenu*)original {
    // Spotify+ meun item
    NSMenuItem *mainItem = [[NSMenuItem alloc] init];
    [mainItem setTitle:@"Spotify+"];
    
    NSMenu* dockspotplusMenu = [plugin spotPlusMenu];
    [mainItem setSubmenu:dockspotplusMenu];
    
    // Fix for moreMenu
    if ([original.itemArray.firstObject.title isEqualToString:@""]) {
        [original removeAllItems];
        if (cmh != nil) {
            [[original addItemWithTitle:@"-" action:@selector(togglePlayPause:) keyEquivalent:@""] setTarget:cmh];
            [original addItem:[NSMenuItem separatorItem]];
            [[original addItemWithTitle:@"Next" action:@selector(skipNext:) keyEquivalent:@""] setTarget:cmh];
            [[original addItemWithTitle:@"Previous" action:@selector(skipPrevious:) keyEquivalent:@""] setTarget:cmh];
            [[original addItemWithTitle:@"Seek Forward" action:@selector(seekForward:) keyEquivalent:@""] setTarget:cmh];
            [[original addItemWithTitle:@"Seek BackWard" action:@selector(seekBackward:) keyEquivalent:@""] setTarget:cmh];
            [original addItem:[NSMenuItem separatorItem]];
            [[original addItemWithTitle:@"Shuffle" action:@selector(toggleShuffle:) keyEquivalent:@""] setTarget:cmh];
            [[original addItemWithTitle:@"Repeat" action:@selector(toggleRepeat:) keyEquivalent:@""] setTarget:cmh];
            [original addItem:[NSMenuItem separatorItem]];
            [[original addItemWithTitle:@"Volume Up" action:@selector(volumeUp:) keyEquivalent:@""] setTarget:cmh];
            [[original addItemWithTitle:@"Volume Down" action:@selector(volumeDown:) keyEquivalent:@""] setTarget:cmh];
        }
    }
    
    [original addItem:[NSMenuItem separatorItem]];
    [original addItem:mainItem];
    
    return original;
}

- (NSMenu*)spotPlusMenu {
    // Ads submenu
    NSMenuItem *adsMenu = [[NSMenuItem alloc] init];
    [adsMenu setTag:100];
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
    [artMenu setTag:101];
    [artMenu setTitle:@"Icon art style"];
    NSMenu *submenuArt = [[NSMenu alloc] init];
    [[submenuArt addItemWithTitle:@"Square" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuArt addItemWithTitle:@"Tilted" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuArt addItemWithTitle:@"Classic Circular" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuArt addItemWithTitle:@"Modern Circular" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    for (NSMenuItem* item in [submenuArt itemArray]) [item setState:NSOffState];
    if (iconArt < submenuArt.itemArray.count) [[[submenuArt itemArray] objectAtIndex:iconArt] setState:NSOnState];
    [artMenu setSubmenu:submenuArt];
    
    // Polling submenu
    NSMenuItem *pollMenu = [[NSMenuItem alloc] init];
    [pollMenu setTag:102];
    [pollMenu setTitle:@"Polling"];
    NSMenu *submenuPoll = [[NSMenu alloc] init];
    [[submenuPoll addItemWithTitle:@"0.5s" action:@selector(setPolling:) keyEquivalent:@""] setTarget:plugin];
    [[submenuPoll addItemWithTitle:@"1.0s" action:@selector(setPolling:) keyEquivalent:@""] setTarget:plugin];
    [[submenuPoll addItemWithTitle:@"2.0s" action:@selector(setPolling:) keyEquivalent:@""] setTarget:plugin];
    [[submenuPoll addItemWithTitle:@"3.0s" action:@selector(setPolling:) keyEquivalent:@""] setTarget:plugin];
    [[submenuPoll addItemWithTitle:@"5.0s" action:@selector(setPolling:) keyEquivalent:@""] setTarget:plugin];
    for (NSMenuItem* item in [submenuPoll itemArray]) [item setState:NSOffState];
    long index = [pollTime indexOfObject:[[NSNumber numberWithInt:sleepTime] stringValue]];
    [[[submenuPoll itemArray] objectAtIndex:index] setState:NSOnState];
    [pollMenu setSubmenu:submenuPoll];
    
    // spotify+ submenu
    NSMenu *submenuRoot = [[NSMenu alloc] init];
    [submenuRoot setTitle:@"Spotify+"];
    [[submenuRoot addItemWithTitle:@"Block all ads" action:@selector(editHostFile:) keyEquivalent:@""] setTarget:plugin];
    [submenuRoot addItem:adsMenu];
    [submenuRoot addItem:[NSMenuItem separatorItem]];
    [[submenuRoot addItemWithTitle:@"Show icon art" action:@selector(setShowArt:) keyEquivalent:@""] setTarget:plugin];
    [submenuRoot addItem:artMenu];
    [submenuRoot addItem:[NSMenuItem separatorItem]];
    [[submenuRoot addItemWithTitle:@"Show muted badge" action:@selector(toggleBadges:) keyEquivalent:@""] setTarget:plugin];
    [submenuRoot addItem:pollMenu];
    [submenuRoot addItem:[NSMenuItem separatorItem]];
    [[submenuRoot addItemWithTitle:@"Check for updates" action:@selector(checkUpdate:) keyEquivalent:@""] setTarget:plugin];
    [submenuRoot addItem:[NSMenuItem separatorItem]];
    [[submenuRoot addItemWithTitle:@"Restart Spotify" action:@selector(restartMe) keyEquivalent:@""] setTarget:plugin];
    [[[submenuRoot itemArray] objectAtIndex:0] setState:banners];
    [[[submenuRoot itemArray] objectAtIndex:0] setTag:99];
    [[[submenuRoot itemArray] objectAtIndex:3] setState:showArt];
    [[[submenuRoot itemArray] objectAtIndex:3] setTag:98];
    [[[submenuRoot itemArray] objectAtIndex:6] setState:showBadge];
    [[[submenuRoot itemArray] objectAtIndex:6] setTag:97];
    
    return submenuRoot;
}

- (void)updateMenu:(NSMenu*)original {
    if (original) {
        NSMenu* updatedMenu = original;
        
        [[updatedMenu itemWithTag:97] setState:showBadge];
        [[updatedMenu itemWithTag:98] setState:showArt];
        [[updatedMenu itemWithTag:99] setState:banners];
        
        NSMenuItem* adsMenu = [updatedMenu itemWithTag:100];
        NSArray* adsSub = [[adsMenu submenu] itemArray];
        [[adsSub objectAtIndex:0] setState:muteAds];
        [[adsSub objectAtIndex:1] setState:muteVid];
        
        NSMenuItem* artMenu = [updatedMenu itemWithTag:101];
        NSArray* artSub = [[artMenu submenu] itemArray];
        for (NSMenuItem* obj in artSub) [obj setState:NSOffState];
        [[artSub objectAtIndex:iconArt] setState:NSOnState];
        
        NSMenuItem* polMenu = [updatedMenu itemWithTag:102];
        NSArray* polSub = [[polMenu submenu] itemArray];
        for (NSMenuItem* obj in polSub) [obj setState:NSOffState];
        long index = [pollTime indexOfObject:[[NSNumber numberWithInt:sleepTime] stringValue]];
        [[polSub objectAtIndex:index] setState:NSOnState];
    }
}

@end

ZKSwizzleInterface(_spotifyPlusNSAD, SPTClientMenuHandler, NSObject <NSMenuDelegate>)
@implementation _spotifyPlusNSAD

- (NSMenu *)applicationDockMenu:(NSApplication *)arg1 {
    cmh = (ClientMenuHandler*)self;
    NSMenu* result = ZKOrig(NSMenu*, arg1);
    result = [plugin dockaddspotPlus:result];
    return result;
}

@end

