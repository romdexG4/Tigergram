//
//  SetupController.m
//  Tigergram
//
// Version 1.0 by romdex (@romdex on Telegram)
// Handles gateway connection setup and IP configuration

#import "SetupController.h"
#import "ChatListController.h"

@implementation SetupController

// Returns the gateway URL from saved preferences
// Falls back to default IP if nothing saved yet
+ (NSString *)gatewayURL {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *ip = [defaults stringForKey:@"gateway_ip"];
    NSString *port = [defaults stringForKey:@"gateway_port"];
    if (!ip || [ip length] == 0) ip = @"192.168.178.45";
    if (!port || [port length] == 0) port = @"8080";
    return [NSString stringWithFormat:@"http://%@:%@", ip, port];
}

// Pre-fills IP and port fields with saved values on startup
- (void)awakeFromNib {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *ip = [defaults stringForKey:@"gateway_ip"];
    NSString *port = [defaults stringForKey:@"gateway_port"];
    if (!ip || [ip length] == 0) ip = @"192.168.178.45";
    if (!port || [port length] == 0) port = @"8080";
    [ipField setStringValue:ip];
    [portField setStringValue:port];
    [errorLabel setStringValue:@""];
    [setupWindow makeKeyAndOrderFront:nil];
}

// Connect button - tests gateway connection before proceeding
- (IBAction)connect:(id)sender {
    NSString *ip = [ipField stringValue];
    NSString *port = [portField stringValue];

    if ([ip length] == 0) {
        [errorLabel setStringValue:@"Please enter an IP address!"];
        return;
    }
    if ([port length] == 0) port = @"8080";

    // Test connection to gateway /test endpoint
    [errorLabel setStringValue:@"Connecting..."];
    [connectButton setEnabled:NO];

    NSString *testURL = [NSString stringWithFormat:@"http://%@:%@/test", ip, port];
    NSURL *url = [NSURL URLWithString:testURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:5.0];
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    [connectButton setEnabled:YES];

    if (error || !data) {
        [errorLabel setStringValue:@"Error: Gateway not reachable!"];
        return;
    }

    // Save IP and port to preferences for next launch
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:ip forKey:@"gateway_ip"];
    [defaults setObject:port forKey:@"gateway_port"];
    [defaults synchronize];

    // Hide setup window and show chat list
    [errorLabel setStringValue:@""];
    [setupWindow orderOut:nil];
    [chatListController loadChats];
    [chatWindow makeKeyAndOrderFront:nil];
}

// Terminates the entire app when setup window is closed
- (BOOL)windowShouldClose:(id)sender {
    [NSApp terminate:nil];
    return YES;
}

@end