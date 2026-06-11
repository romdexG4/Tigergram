//
//  ChatlistController.m
//  Tigergram

// Version 1.0 by romdex (@romdex on Telegram)
// Manages the chat list window and auto-refresh

#import "ChatListController.h"
#import "MessageViewController.h"
#import "SetupController.h"

@implementation ChatListController

- (id)init {
    self = [super init];
    if (self) {
        chats = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)awakeFromNib {
    [statusLabel setStringValue:@"Please connect to Gateway..."];
}

// Called by SetupController after successful connection
- (void)loadChats {
    [statusLabel setStringValue:@"Loading chats..."];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/chats",
        [SetupController gatewayURL]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:5.0];
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    if (error || !data) {
        [statusLabel setStringValue:@"Error: Could not load chats!"];
        return;
    }
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [chats removeAllObjects];
    [parser parse];
    [parser release];
    [chatTableView reloadData];
    [statusLabel setStringValue:[NSString stringWithFormat:@"%d chats loaded", [chats count]]];

    // Start auto-refresh timer - updates unread counts every 30 seconds
    if (!refreshTimer) {
        refreshTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                        target:self
                                                      selector:@selector(autoRefreshChats:)
                                                      userInfo:nil
                                                       repeats:YES];
    }
}

// Auto-refresh - silently reloads chat list every 30 seconds
- (void)autoRefreshChats:(NSTimer *)timer {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/chats",
        [SetupController gatewayURL]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:5.0];
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    if (error || !data) return;
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [chats removeAllObjects];
    [parser parse];
    [parser release];
    [chatTableView reloadData];
}

// XML parser - reads chat attributes from gateway response
- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"chat"]) {
        NSMutableDictionary *chat = [NSMutableDictionary dictionary];
        [chat setObject:[attributeDict objectForKey:@"id"] forKey:@"id"];
        [chat setObject:[attributeDict objectForKey:@"name"] forKey:@"name"];
        [chat setObject:[attributeDict objectForKey:@"unread"] forKey:@"unread"];
        [chat setObject:[attributeDict objectForKey:@"type"] ?
            [attributeDict objectForKey:@"type"] : @"user" forKey:@"type"];
        [chat setObject:[attributeDict objectForKey:@"members"] ?
            [attributeDict objectForKey:@"members"] : @"" forKey:@"members"];
        [chats addObject:chat];
    }
}

// TableView data source - returns number of chats
- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    return [chats count];
}

// TableView data source - returns value for each cell
- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(int)row {
    NSDictionary *chat = [chats objectAtIndex:row];
    if ([[tableColumn identifier] isEqualToString:@"name"]) {
        return [chat objectForKey:@"name"];
    }
    if ([[tableColumn identifier] isEqualToString:@"unread"]) {
        return [chat objectForKey:@"unread"];
    }
    if ([[tableColumn identifier] isEqualToString:@"type"]) {
        NSString *type = [chat objectForKey:@"type"];
        if ([type isEqualToString:@"channel"]) return @"Channel";
        if ([type isEqualToString:@"group"]) return @"Group";
        return @"Direct";
    }
    return @"";
}

// Opens message window when user clicks a chat
- (IBAction)chatSelected:(id)sender {
    int row = [chatTableView selectedRow];
    if (row >= 0) {
        NSDictionary *chat = [chats objectAtIndex:row];
        long long chatId = (long long)[[chat objectForKey:@"id"] doubleValue];
        NSString *name = [chat objectForKey:@"name"];
        [messageViewController loadMessagesForChat:chatId name:name];
    }
}

// Terminates the entire app when chat list window is closed
- (BOOL)windowShouldClose:(id)sender {
    [NSApp terminate:nil];
    return YES;
}

- (void)dealloc {
    [chats release];
    [refreshTimer invalidate];
    [super dealloc];
}

@end