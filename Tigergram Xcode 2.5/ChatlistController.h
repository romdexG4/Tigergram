//
//  ChatlistController.h
//  Tigergram
//
// Version 1.0 by romdex (@romdex on Telegram)
//

#import <Cocoa/Cocoa.h>

@class MessageViewController;

@interface ChatListController : NSObject {
    IBOutlet NSTableView *chatTableView;
    IBOutlet NSTextField *statusLabel;
    IBOutlet MessageViewController *messageViewController;
    NSMutableArray *chats;
    NSTimer *refreshTimer;
}

- (void)loadChats;
- (IBAction)chatSelected:(id)sender;

@end
