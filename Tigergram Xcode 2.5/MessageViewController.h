//
//  MessageViewController.h
//  Tigergram
//
// Version 1.0 by romdex (@romdex on Telegram)
//

#import <Cocoa/Cocoa.h>

@interface MessageViewController : NSObject {
    IBOutlet NSTableView *messageTableView;
    IBOutlet NSTextField *statusLabel;
    IBOutlet NSTextField *inputField;
    IBOutlet NSButton *sendButton;
    IBOutlet NSWindow *messageWindow;
    IBOutlet NSImageView *avatarView;
    IBOutlet NSTextField *bioLabel;
    IBOutlet NSTextField *replyLabel;
    IBOutlet NSButton *clearReplyButton;
    NSMutableArray *messages;
    long long currentChatId;
    NSString *currentChatName;
    long long replyToId;
    NSString *replyToText;
    NSString *replyToSender;
}

- (void)loadMessagesForChat:(long long)chatId name:(NSString *)name;
- (IBAction)sendMessage:(id)sender;
- (IBAction)inputFieldAction:(id)sender;
- (IBAction)replyToSelected:(id)sender;
- (IBAction)clearReply:(id)sender;
- (IBAction)downloadSelectedMedia:(id)sender;

@end