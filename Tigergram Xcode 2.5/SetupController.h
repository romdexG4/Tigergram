//
//  SetupController.h
//  Tigergram
//
//  Version 1.0 by romdex (@romdex on Telegram)
//  

#import <Cocoa/Cocoa.h>

@class ChatListController;

@interface SetupController : NSObject {
    IBOutlet NSWindow *setupWindow;
    IBOutlet NSWindow *chatWindow;
    IBOutlet NSTextField *ipField;
    IBOutlet NSTextField *portField;
    IBOutlet NSButton *connectButton;
    IBOutlet NSTextField *errorLabel;
    IBOutlet ChatListController *chatListController;
}

- (IBAction)connect:(id)sender;
+ (NSString *)gatewayURL;

@end
