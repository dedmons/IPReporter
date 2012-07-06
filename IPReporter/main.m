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

    assert(hostname != NULL);
    
    if (comment == NULL) {
        comment = "";
    }
    
    NSLog(@"%c%c%c%c%c%c%c %s%s\n",
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

static NSString* getIP(AFHTTPClient *client){
    [client getPath:@"/v1/ip/mine"
         parameters:nil
            success:nil
            failure:nil];
    
    AFHTTPRequestOperation *op = [client.operationQueue.operations lastObject];
    while (!op.isFinished) {
//        NSLog(@"Sleeping ... ");
//        sleep(1);
    }
    NSLog(@"%ld",op.response.statusCode);

    NSDictionary *d = [NSJSONSerialization JSONObjectWithData:op.responseData options:NSJSONReadingAllowFragments error:nil];
    NSLog(@"%@",d);
    
    return [d objectForKey:@"CLIENT_IP"];
}

static void registerIP(AFHTTPClient *client, NSDictionary *data){
    [client postPath:@"/v1/ip/report"
          parameters:data
             success:nil
             failure:nil];
    
    AFHTTPRequestOperation *op = [client.operationQueue.operations lastObject];
    while (!op.isFinished) {
//        NSLog(@"Sleeping ... ");
//        sleep(1);
    }
    NSLog(@"Status Code: %ld",op.response.statusCode);

    NSDictionary *d = [NSJSONSerialization JSONObjectWithData:op.responseData options:NSJSONReadingAllowFragments error:nil];
    NSLog(@"%@",d);
}

static void deleteRecords(AFHTTPClient *client){
    [client deletePath:@"ip/records"
          parameters:[NSDictionary dictionaryWithObject:@"YES" forKey:@"check"]
             success:nil
             failure:nil];
    
    AFHTTPRequestOperation *op = [client.operationQueue.operations lastObject];
    
    while (!op.isFinished);
    
    NSLog(@"Status Code: %ld",op.response.statusCode);
    
    if (op.responseData) {
        NSDictionary *d = [NSJSONSerialization JSONObjectWithData:op.responseData options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"%@",d);
    }
}

int main(int argc, const char * argv[])
{

    @autoreleasepool {
                
        // insert code here...
        const char *host = "apis.dedmonson.com";
        SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithName(NULL, host);
        SCNetworkReachabilityFlags flags;
        SCNetworkReachabilityGetFlags(ref, &flags);
        PrintReachabilityFlags(host, flags, NULL);

        if (flags & kSCNetworkFlagsReachable) {
            AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://apis.dedmonson.com/v1/"]];
            [client setDefaultHeader:@"json" value:@"Accept-Encoding"];
            client.deleteEncodedInURL = NO;
            
            NSString *hostname = [[NSHost currentHost] name];
            hostname = [[hostname componentsSeparatedByString:@"."] objectAtIndex:0];

            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            [data setObject:hostname forKey:@"host"];
            [data setObject:NSUserName() forKey:@"user"];
            
            //getIP(client);
            registerIP(client, data);
            //deleteRecords(client);
        }
    }
    return 0;
}