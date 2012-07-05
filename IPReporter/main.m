//
//  main.m
//  IPReporter
//
//  Created by Douglas Edmonson on 07/05/2012.
//  Copyright (c) 2012 Clemson University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "AFNetworking.h"

static void PrintReachabilityFlags(
                                   const char *                hostname, 
                                   SCNetworkConnectionFlags    flags, 
                                   const char *                comment
                                   )
// Prints a line that records a reachability transition. 
// This includes the current time, the new state of the 
// reachability flags (from the flags parameter), and the 
// name of the host (from the hostname parameter).
{
    time_t      now;
    struct tm   nowLocal;
    char        nowLocalStr[30];
    
    assert(hostname != NULL);
    
    if (comment == NULL) {
        comment = "";
    }
    
    (void) time(&now);
    (void) localtime_r(&now, &nowLocal);
    (void) strftime(nowLocalStr, sizeof(nowLocalStr), "%X", &nowLocal);
    
    fprintf(stdout, "%s %c%c%c%c%c%c%c %s%s\n",
            nowLocalStr,
            (flags & kSCNetworkFlagsTransientConnection)  ? 't' : '-',
            (flags & kSCNetworkFlagsReachable)            ? 'r' : '-',
            (flags & kSCNetworkFlagsConnectionRequired)   ? 'c' : '-',
            (flags & kSCNetworkFlagsConnectionAutomatic)  ? 'C' : '-',
            (flags & kSCNetworkFlagsInterventionRequired) ? 'i' : '-',
            (flags & kSCNetworkFlagsIsLocalAddress)       ? 'l' : '-',
            (flags & kSCNetworkFlagsIsDirect)             ? 'd' : '-',
            hostname,
            comment
            );
}

int main(int argc, const char * argv[])
{

    @autoreleasepool {
//        __block BOOL isDone = NO;
        
        // insert code here...
        const char *host = "apis.dedmonson.com";
        SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithName(NULL, host);
        SCNetworkReachabilityFlags flags;
        SCNetworkReachabilityGetFlags(ref, &flags);
        PrintReachabilityFlags(host, flags, NULL);

        if (flags & kSCNetworkFlagsReachable) {
//            NSLog(@"Server Reachable");
            AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://apis.dedmonson.com"]];
            [client setDefaultHeader:@"json" value:@"Accept-Encoding"];
            [client getPath:@"/ip/mine"
                 parameters:nil
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"res: %@",responseObject);
                        });
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"Err: %@",error);
                        });
                    }];
            AFHTTPRequestOperation *op = [client.operationQueue.operations lastObject];
            while (!op.isFinished) {
                NSLog(@"Sleeping ... ");
                sleep(1);
            }
            NSLog(@"%ld",op.response.statusCode);
            NSLog(@"%@",op.responseString);
            NSDictionary *d = [NSJSONSerialization JSONObjectWithData:op.responseData options:NSJSONReadingAllowFragments error:nil];
            NSLog(@"%@",d);
            
            [client postPath:@"/ip/report"
                  parameters:[NSDictionary dictionaryWithObject:[d objectForKey:@"CLIENT_IP"] forKey:@"ip"]
                     success:nil
                     failure:nil];
            
            op = [client.operationQueue.operations lastObject];
            while (!op.isFinished) {
                NSLog(@"Sleeping ... ");
                sleep(1);
            }
            NSLog(@"%ld",op.response.statusCode);
            NSLog(@"%@",op.responseString);
            d = [NSJSONSerialization JSONObjectWithData:op.responseData options:NSJSONReadingAllowFragments error:nil];
            NSLog(@"%@",d);
        }
    }
    return 0;
}