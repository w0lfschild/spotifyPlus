//
//  main.h
//  spotifyAB
//
//  Created by Wolfgang Baird on 2/5/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import "ZKSwizzle.h"

@interface main : NSObject

@end

@interface NSMenuDelegate <NSObject>
- (void)menu:(NSMenu *)arg1 willHighlightItem:(NSMenuItem *)arg2;
- (void)menuDidClose:(NSMenu *)arg1;
- (void)menuWillOpen:(NSMenu *)arg1;
- (BOOL)menuHasKeyEquivalent:(NSMenu *)arg1 forEvent:(NSEvent *)arg2 target:(id *)arg3 action:(SEL *)arg4;
- (BOOL)menu:(NSMenu *)arg1 updateItem:(NSMenuItem *)arg2 atIndex:(long long)arg3 shouldCancel:(BOOL)arg4;
- (long long)numberOfItemsInMenu:(NSMenu *)arg1;
- (void)menuNeedsUpdate:(NSMenu *)arg1;
@end

@interface SPNextTrackScriptCommand : NSScriptCommand
{
}
- (id)performDefaultImplementation;
@end

@interface NSWindow (DisableUserInteraction)
+ (void)load;
@property BOOL isUserInteractionEnabled;
- (void)sendEvent_swizzle:(id)arg1;
- (void)updateMenu:(id)arg1 setEnabled:(BOOL)arg2;
- (void)setWindowButtonsEnabled:(BOOL)arg1;
- (BOOL)isUserInteractionEvent:(id)arg1;
@end

@interface ClientApplication : NSApplication
{
}
- (void)setShuffle:(BOOL)arg1;
- (BOOL)shuffle;
- (BOOL)shuffleEnabled;
- (void)setRepeat:(BOOL)arg1;
- (BOOL)repeat;
- (BOOL)repeatEnabled;
- (void)setPlaybackPosition:(id)arg1;
- (id)playbackPosition;
- (id)playerState;
- (void)setSoundVolume:(id)arg1;
- (id)soundVolume;
- (id)currentTrack;
@end

@interface SPAppleScriptItem : NSObject
{
    id parentItem;
    NSString *key;
}
- (void)dealloc;
- (id)objectSpecifier;
- (id)description;
- (id)title;
- (id)applescriptID;
- (id)initWithKey:(id)arg1 inParent:(id)arg2;
@end

@interface SPAppleScriptTrack : SPAppleScriptItem
{
}
- (void)dealloc;
- (id)cover;
- (id)spotifyURL;
- (id)popularity;
- (id)trackNumber;
- (id)playCount;
- (id)duration;
- (id)discNumber;
- (id)applescriptID;
- (id)title;
- (id)albumArtist;
- (id)album;
- (id)artist;
@end

@interface ClientMenuHandler : NSObject <NSMenuDelegate>
{
    BOOL isLoggedIn_;
    NSMenuItem *devMenuItem_;
    NSWindow *applicationMainWindow_;
}
- (void)importPlaylists:(id)arg1;
- (void)handleDevCommand:(int)arg1;
- (void)toggleGrid:(id)arg1;
- (void)showApplications:(id)arg1;
- (void)showUtils:(id)arg1;
- (void)showDevTools:(id)arg1;
- (void)reload:(id)arg1;
- (void)redo:(id)arg1;
- (void)undo:(id)arg1;
- (void)terminate:(id)arg1;
- (void)unhideAllApplications:(id)arg1;
- (void)hideOtherApplications:(id)arg1;
- (void)reopen:(id)arg1;
- (void)hide:(id)arg1;
- (void)showFriendFeed:(id)arg1;
- (void)toggleFullScreen:(id)arg1;
- (void)performZoom:(id)arg1;
- (void)performMiniaturize:(id)arg1;
- (void)performClose:(id)arg1;
- (void)arrangeInFront:(id)arg1;
- (void)volumeDown:(id)arg1;
- (void)volumeUp:(id)arg1;
- (void)seekBackward:(id)arg1;
- (void)seekForward:(id)arg1;
- (void)skipPrevious:(id)arg1;
- (void)skipNext:(id)arg1;
- (void)toggleRepeat:(id)arg1;
- (void)toggleShuffle:(id)arg1;
- (void)togglePlayPause:(id)arg1;
- (void)toggleOfflineMode:(id)arg1;
- (void)togglePrivateSession:(id)arg1;
- (void)resetZoom:(id)arg1;
- (void)zoomOut:(id)arg1;
- (void)zoomIn:(id)arg1;
- (void)filter:(id)arg1;
- (void)search:(id)arg1;
- (void)selectAll:(id)arg1;
- (void)delete:(id)arg1;
- (void)paste:(id)arg1;
- (void)copy:(id)arg1;
- (void)cut:(id)arg1;
- (void)createFolder:(id)arg1;
- (void)createPlaylist:(id)arg1;
- (void)logOut:(id)arg1;
- (void)showHelp:(id)arg1;
- (void)showYourAccount:(id)arg1;
- (void)showLicenses:(id)arg1;
- (void)showCommunityPage:(id)arg1;
- (void)showAboutBox:(id)arg1;
- (void)showSettingsPage:(id)arg1;
- (void)goBack:(id)arg1;
- (void)goForward:(id)arg1;
- (BOOL)menu:(id)arg1 updateItem:(id)arg2 atIndex:(long long)arg3 shouldCancel:(BOOL)arg4;
- (long long)numberOfItemsInMenu:(id)arg1;
- (BOOL)validateUserInterfaceItem:(id)arg1;
- (BOOL)popupWindowHasKeyFocus;
- (BOOL)isFocusOnEditableField;
- (void)performMenuAction:(SEL)arg1 withSender:(id)arg2 orControlMessage:(id)arg3;
- (void)performOnFirstResponder:(SEL)arg1 withSender:(id)arg2;
- (void)addSeparator:(id)arg1;
- (id)addItem:(int)arg1 action:(SEL)arg2 toMenu:(id)arg3;
- (id)addItem:(int)arg1 action:(SEL)arg2 keyEquivalentChar:(unsigned short)arg3 toMenu:(id)arg4;
- (id)addItem:(int)arg1 action:(SEL)arg2 keyEquivalent:(id)arg3 toMenu:(id)arg4;
- (void)setupImportPlaylistsMenu:(id)arg1;
- (void)setupDevelopMenu:(id)arg1;
- (void)setupHelpMenu:(id)arg1;
- (void)setupWindowMenu:(id)arg1;
- (void)setupPlaybackMenu:(id)arg1;
- (void)setupViewMenu:(id)arg1;
- (void)setupEditMenu:(id)arg1;
- (void)setupFileMenu:(id)arg1;
- (void)setupSpotifyMenu:(id)arg1;
- (id)applicationDockMenu:(id)arg1;
- (void)setupMenu;
- (void)setApplicationMainWindow:(id)arg1;
- (void)updateMenu;
- (void)setLoggedIn:(BOOL)arg1;
- (void)dealloc;
@end
