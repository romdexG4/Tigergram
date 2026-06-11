//
//  MessageViewController.m
//  Tigergram
//
// Version 1.0 by romdex (@romdex on Telegram)
//

#import "MessageViewController.h"
#import "SetupController.h"

@implementation MessageViewController

- (id)init {
    self = [super init];
    if (self) {
        messages = [[NSMutableArray alloc] init];
        currentChatId = 0;
        replyToId = 0;
    }
    return self;
}

- (void)awakeFromNib {
    [replyLabel setStringValue:@""];
    [replyLabel setHidden:YES];
    [clearReplyButton setHidden:YES];
    [self startAutoRefresh];
}

- (void)startAutoRefresh {
    [NSThread detachNewThreadSelector:@selector(pollThread)
                             toTarget:self
                           withObject:nil];
}

- (void)pollThread {
    while (YES) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        if (currentChatId != 0) {
            NSString *urlString = [NSString stringWithFormat:@"%@/poll?chat_id=%lld",
                [SetupController gatewayURL], currentChatId];
            NSURL *url = [NSURL URLWithString:urlString];
            NSURLRequest *request = [NSURLRequest requestWithURL:url
                                                     cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                 timeoutInterval:35.0];
            NSURLResponse *response = nil;
            NSError *error = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&error];
            if (data) {
                NSString *result = [[NSString alloc] initWithData:data
                                                         encoding:NSUTF8StringEncoding];
                if ([result rangeOfString:@"has_new=\"true\""].location != NSNotFound) {
                    [self performSelectorOnMainThread:@selector(refreshMessages)
                                          withObject:nil
                                       waitUntilDone:NO];
                }
                [result release];
            }
        } else {
            [NSThread sleepForTimeInterval:2.0];
        }
        [pool release];
    }
}

- (void)refreshMessages {
    if (currentChatId != 0) {
        [self loadMessagesForChat:currentChatId name:currentChatName];
    }
}

- (void)loadBio {
    NSString *urlString = [NSString stringWithFormat:@"%@/bio?chat_id=%lld",
        [SetupController gatewayURL], currentChatId];
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (data) {
        NSString *xml = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSRange start = [xml rangeOfString:@"text=\""];
        if (start.location != NSNotFound) {
            NSString *rest = [xml substringFromIndex:start.location + 6];
            NSRange end = [rest rangeOfString:@"\""];
            if (end.location != NSNotFound) {
                NSString *bio = [rest substringToIndex:end.location];
                [bioLabel setStringValue:bio];
            }
        }
        [xml release];
    }
}

- (void)loadAvatar {
    NSString *urlString = [NSString stringWithFormat:@"%@/avatar?chat_id=%lld",
        [SetupController gatewayURL], currentChatId];
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (data) {
        NSImage *image = [[NSImage alloc] initWithData:data];
        if (image) {
            [avatarView setImage:image];
            [image release];
        }
    }
}

- (void)loadMessagesForChat:(long long)chatId name:(NSString *)name {
    currentChatId = chatId;
    if (currentChatName != name) {
        [currentChatName release];
        currentChatName = [name retain];
    }

    [self loadAvatar];
    [self loadBio];

    NSString *urlString = [NSString stringWithFormat:@"%@/messages?chat_id=%lld",
        [SetupController gatewayURL], chatId];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:5.0];
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    if (error || !data) {
        [statusLabel setStringValue:@"Error loading messages!"];
        return;
    }

    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [messages removeAllObjects];
    [parser parse];
    [parser release];

    [messageTableView reloadData];
    [statusLabel setStringValue:[NSString stringWithFormat:@"%@ - %d messages",
        currentChatName, [messages count]]];

    int lastRow = [messages count] - 1;
    if (lastRow >= 0) {
        [messageTableView scrollRowToVisible:lastRow];
    }

    [messageWindow setTitle:currentChatName];
    [messageWindow makeKeyAndOrderFront:nil];
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {

    if ([elementName isEqualToString:@"message"]) {
        NSMutableDictionary *msg = [NSMutableDictionary dictionary];
        [msg setObject:[attributeDict objectForKey:@"id"] forKey:@"id"];
        [msg setObject:[attributeDict objectForKey:@"date"] forKey:@"date"];
        [msg setObject:[attributeDict objectForKey:@"sender"] ?
            [attributeDict objectForKey:@"sender"] : @"" forKey:@"sender"];
        [msg setObject:[attributeDict objectForKey:@"media_type"] ?
            [attributeDict objectForKey:@"media_type"] : @"" forKey:@"media_type"];
        [msg setObject:[attributeDict objectForKey:@"media_file"] ?
            [attributeDict objectForKey:@"media_file"] : @"" forKey:@"media_file"];
        [msg setObject:[attributeDict objectForKey:@"reply_to_text"] ?
            [attributeDict objectForKey:@"reply_to_text"] : @"" forKey:@"reply_to_text"];
        [msg setObject:[attributeDict objectForKey:@"reply_to_sender"] ?
            [attributeDict objectForKey:@"reply_to_sender"] : @"" forKey:@"reply_to_sender"];
        NSString *replyId = [attributeDict objectForKey:@"reply_to_id"];
        [msg setObject:replyId ? replyId : @"0" forKey:@"reply_to_id"];
        [msg setObject:@"" forKey:@"text"];
        [messages addObject:msg];
    }
}

- (void)parser:(NSXMLParser *)parser
foundCharacters:(NSString *)string {
    NSMutableDictionary *lastMsg = [messages lastObject];
    if (lastMsg) {
        NSString *current = [lastMsg objectForKey:@"text"];
        [lastMsg setObject:[current stringByAppendingString:string] forKey:@"text"];
    }
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    return [messages count];
}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(int)row {
    NSDictionary *msg = [messages objectAtIndex:row];

    if ([[tableColumn identifier] isEqualToString:@"text"]) {
        NSString *mediaType = [msg objectForKey:@"media_type"];
        NSString *mediaFile = [msg objectForKey:@"media_file"];
        NSString *text = [msg objectForKey:@"text"];
        NSString *replyText = [msg objectForKey:@"reply_to_text"];
        NSString *replySender = [msg objectForKey:@"reply_to_sender"];

        NSMutableString *display = [NSMutableString string];

        if (mediaType && [mediaType length] > 0) {
            if ([mediaType isEqualToString:@"photo"]) {
                [display appendFormat:@"[Photo] %@", mediaFile];
            } else if ([mediaType isEqualToString:@"sticker"]) {
                [display appendFormat:@"[Sticker] %@", mediaFile];
            } else if ([mediaType isEqualToString:@"video"]) {
                [display appendString:@"[Video]"];
            } else if ([mediaType isEqualToString:@"voice"]) {
                [display appendString:@"[Voice message]"];
            } else if ([mediaType isEqualToString:@"gif"]) {
                [display appendString:@"[GIF]"];
            } else {
                [display appendString:@"[File]"];
            }
            if (text && [text length] > 0) {
                [display appendFormat:@" %@", text];
            }
        } else {
            [display appendString:text ? text : @""];
        }

        if (replyText && [replyText length] > 0) {
            [display appendFormat:@" >> %@: %@", replySender, replyText];
        }

        return display;
    }

    if ([[tableColumn identifier] isEqualToString:@"sender"]) {
        return [msg objectForKey:@"sender"];
    }

    if ([[tableColumn identifier] isEqualToString:@"date"]) {
        NSTimeInterval ts = [[msg objectForKey:@"date"] doubleValue];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:ts];
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setFormatterBehavior:NSDateFormatterBehavior10_4];
        [fmt setDateFormat:@"MM-dd HH:mm"];
        NSString *dateStr = [fmt stringFromDate:date];
        [fmt release];
        return dateStr;
    }
    return @"";
}

- (IBAction)replyToSelected:(id)sender {
    int row = [messageTableView selectedRow];
    if (row < 0) {
        NSRunAlertPanel(@"No message selected",
            @"Please click a message first, then press Reply.",
            @"OK", nil, nil);
        return;
    }

    NSDictionary *msg = [messages objectAtIndex:row];
    replyToId = (long long)[[msg objectForKey:@"id"] doubleValue];
    [replyToText release];
    replyToText = [[msg objectForKey:@"text"] retain];
    [replyToSender release];
    replyToSender = [[msg objectForKey:@"sender"] retain];

    NSString *displayText = (replyToText && [replyToText length] > 0) ?
        replyToText : @"[media]";
    NSString *replyDisplay = [NSString stringWithFormat:@">> %@: %@",
        replyToSender, displayText];
    [replyLabel setStringValue:replyDisplay];
    [replyLabel setHidden:NO];
    [clearReplyButton setHidden:NO];
}

- (IBAction)clearReply:(id)sender {
    replyToId = 0;
    [replyToText release];
    replyToText = nil;
    [replyToSender release];
    replyToSender = nil;
    [replyLabel setStringValue:@""];
    [replyLabel setHidden:YES];
    [clearReplyButton setHidden:YES];
}

- (IBAction)downloadSelectedMedia:(id)sender {
    int row = [messageTableView selectedRow];
    if (row < 0) {
        NSRunAlertPanel(@"No message selected",
            @"Please click a message first, then press Download.",
            @"OK", nil, nil);
        return;
    }

    NSDictionary *msg = [messages objectAtIndex:row];
    NSString *mediaType = [msg objectForKey:@"media_type"];
    NSString *mediaFile = [msg objectForKey:@"media_file"];

    if (!mediaType || [mediaType length] == 0 ||
        (![mediaType isEqualToString:@"photo"] &&
         ![mediaType isEqualToString:@"sticker"])) {
        NSRunAlertPanel(@"No media",
            @"This message has no downloadable image or sticker.",
            @"OK", nil, nil);
        return;
    }

    long long msgId = (long long)[[msg objectForKey:@"id"] doubleValue];
    NSString *urlString = [NSString stringWithFormat:@"%@/media?chat_id=%lld&message_id=%lld",
        [SetupController gatewayURL], currentChatId, msgId];
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *imageData = [NSData dataWithContentsOfURL:url];

    if (!imageData) {
        NSRunAlertPanel(@"Download failed",
            @"Could not download media from gateway.",
            @"OK", nil, nil);
        return;
    }

    // Auf Desktop speichern
    NSString *desktop = [NSString stringWithFormat:@"%@/Desktop/%@",
        NSHomeDirectory(), mediaFile];
    [imageData writeToFile:desktop atomically:YES];

    // In Preview öffnen
    [[NSWorkspace sharedWorkspace] openFile:desktop];
}

- (IBAction)sendMessage:(id)sender {
    NSString *text = [inputField stringValue];
    if ([text length] == 0) return;

    NSString *urlString;
    if (replyToId > 0) {
        urlString = [NSString stringWithFormat:@"%@/send?chat_id=%lld&text=%@&reply_to_id=%lld",
            [SetupController gatewayURL], currentChatId,
            [text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
            replyToId];
    } else {
        urlString = [NSString stringWithFormat:@"%@/send?chat_id=%lld&text=%@",
            [SetupController gatewayURL], currentChatId,
            [text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }

    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:5.0];
    NSURLResponse *response = nil;
    NSError *error = nil;
    [NSURLConnection sendSynchronousRequest:request
                          returningResponse:&response
                                      error:&error];

    [inputField setStringValue:@""];
    [self clearReply:nil];
    [self loadMessagesForChat:currentChatId name:currentChatName];
}

- (IBAction)inputFieldAction:(id)sender {
    [self sendMessage:sender];
}

- (void)dealloc {
    [messages release];
    [currentChatName release];
    [replyToText release];
    [replyToSender release];
    [super dealloc];
}

@end