//
//  Created by Leptos on 7/1/19.
//  Copyright © 2019 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>

__IDSTRING(whatMsg, "@(#)Upload data to hastebin from a file or stdin");

int main(int argc, const char *argv[]) {
    NSFileHandle *fileHandle = nil;
    if (isatty(STDIN_FILENO)) {
        const char *argOne = argv[1];
        if (!argOne || (argc != 2)) {
            fprintf(stderr, "%s must be invoked with exactly one file name or stdin open\n", argv[0]);
            return 1;
        } else {
            fileHandle = [NSFileHandle fileHandleForReadingAtPath:@(argOne)];
        }
    } else {
        fileHandle = NSFileHandle.fileHandleWithStandardInput;
    }
    
    NSData *data = [fileHandle readDataToEndOfFile];
    
    // per https://github.com/seejohnrun/haste-client#changing-the-location-of-your-haste-server
    NSURL *hasteServer = [NSURL URLWithString:@(getenv("HASTE_SERVER") ?: "https://hastebin.com")];
    
    NSURL *endpoint = [hasteServer URLByAppendingPathComponent:@"documents"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:endpoint];
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;
    
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    NSData  *__block resDat = nil;
    NSError *__block err = nil;
    void(^handler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *dat, NSURLResponse *res, NSError *error) {
        resDat = dat;
        err = error;
        CFRunLoopStop(runloop);
    };
    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:handler] resume];
    CFRunLoopRun();
    
    if (err) {
        fprintf(stderr, "%s\n", err.localizedDescription.UTF8String);
        return 1;
    }
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:resDat options:NSJSONReadingAllowFragments error:&err];
    if (err) {
        fprintf(stderr, "%s\n", err.localizedDescription.UTF8String);
        NSString *content = [[NSString alloc] initWithData:resDat encoding:NSUTF8StringEncoding];
        if (content) {
            fprintf(stderr, "%s\n", content.UTF8String);
        }
        return 1;
    }
    
    NSString *key = dict[@"key"];
    if (key) {
        NSURL *location = [hasteServer URLByAppendingPathComponent:key];
        puts(location.absoluteString.UTF8String);
    } else {
        fprintf(stderr, "%s\n", dict.description.UTF8String);
        return 1;
    }
}
