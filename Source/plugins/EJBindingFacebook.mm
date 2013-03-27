#import "EJBindingFacebook.h"
#import "FacebookSDK/FBSessionTokenCachingStrategy.h"

@implementation EJBindingFacebook

- (id)initWithContext:(JSContextRef)ctx 
    object:(JSObjectRef)obj 
    argc:(size_t)argc 
    argv:(const JSValueRef [])argv  {
    self = [super initWithContext:ctx object:obj argc:argc argv:argv];
    return self;
}

EJ_BIND_FUNCTION (init, ctx, argc, argv) {
    [self initialiseSession];
    
    [FBSession openActiveSessionWithReadPermissions: nil allowLoginUI: NO completionHandler:^(FBSession* session, FBSessionState state, NSError* error) {
        [self sessionStateChanged:session state:state error:error];
    }];
    
    return 0;
}

EJ_BIND_FUNCTION (api, ctx, argc, argv) {
    if (argc > 1) {
        NSString* request = JSValueToNSString(ctx, argv[0]);
        JSObjectRef options = JSValueToObject(ctx, argv[1], NULL);
        JSObjectRef callback = JSValueToObject(ctx, argv[2], NULL);
        JSStringRef fieldStr = JSStringCreateWithUTF8CString("fields");

        JSValueRef fields = JSObjectGetProperty(ctx, options, fieldStr, NULL);
        NSString* fieldOpt = JSValueToNSString(ctx, fields);

        if (callback) {
            JSValueProtect(ctx, callback);
            [self prepareRequest: mSession request: request options: fieldOpt callback: callback];
        }
    }
    
    return 0;
}

EJ_BIND_FUNCTION (close, ctx, argc, argv) {
    [mSession close];

    JSContextRef gCtx = [EJApp instance].jsGlobalContext;
    JSValueUnprotect(gCtx, mAuthResponseSubscribeCallback);
    
    return 0;
}

EJ_BIND_FUNCTION (subscribe, ctx, argc, argv) {
    if (argc == 2) {
        NSString* event = JSValueToNSString(ctx, argv[0]);
        JSObjectRef callback = JSValueToObject(ctx, argv[1], NULL);
        
        if (callback) {
            if ([event isEqualToString: @"auth.authResponseChange"]) {
                mAuthResponseSubscribeCallback = callback;
                JSValueProtect(ctx, mAuthResponseSubscribeCallback);
            } else {
                NSLog(@"Subscription to event %@ unhandled.", event);
            }
        }
    }
    
    return 0;
}

EJ_BIND_FUNCTION (login, ctx, argc, argv) {
    if (!mSessionInitialised) { 
        [self initialiseSession];
    }
 
    [mSession openWithCompletionHandler:^(FBSession* session, FBSessionState state, NSError* error) {
        [self sessionStateChanged:session state:state error:error];
    }];
        
    if (argc == 1) {
        JSObjectRef callback = JSValueToObject(ctx, argv[0], NULL);

        if (callback) {
            JSContextRef gCtx = [EJApp instance].jsGlobalContext;
    
            [[EJApp instance] invokeCallback: callback thisObject: NULL argc: 0 argv: nil];
        }
    }
    return 0;
}

EJ_BIND_FUNCTION (logout, ctx, argc, argv) {
    [mSession close];
    //[mSession closeAndClearTokenInformation];
    mSessionInitialised = false;
        
    if (argc == 1) {
        JSObjectRef callback = JSValueToObject(ctx, argv[0], NULL);

        if (callback) {
            JSContextRef gCtx = [EJApp instance].jsGlobalContext;
    
            [[EJApp instance] invokeCallback: callback thisObject: NULL argc: 0 argv: nil];
        }
    }
    
    return 0;
}

EJ_BIND_FUNCTION (getLoginStatus, ctx, argc, argv) {
    if (argc == 1) {
        JSObjectRef callback = JSValueToObject(ctx, argv[0], NULL);
        
        if (callback) {
            JSContextRef gCtx = [EJApp instance].jsGlobalContext;
        
            NSString* strState;
            FBSessionState state = mSession.state;
            
            [self logState: state];

            switch (state) {
            case FBSessionStateOpen:
            case FBSessionStateOpenTokenExtended:
            case FBSessionStateCreatedTokenLoaded:
                strState = @"{\"status\": \"connected\"}";
                break;
            default:
                strState = @"{\"status\": \"unknown\"}";
                break;
            }
            
            //JSValueRef params[] = { JSValueMakeFromJSONString(gCtx, strState) };
            JSValueRef params[] = { NSStringToJSValue(gCtx, strState) };
            [[EJApp instance] invokeCallback: callback thisObject: NULL argc: 1 argv: params];
        } else {
            NSLog(@"No callback or wrong number of args.");
        }
    } else {
        NSLog(@"No callback or wrong number of args. %ld", argc);
    }
    
    return 0;
}

- (void) logState:(FBSessionState) state {
    switch (state) {
    case FBSessionStateOpen:
        NSLog(@"FB Session state open");
        break;
    case FBSessionStateOpenTokenExtended:
        NSLog(@"FB Session state open token extended");
        break;
    case FBSessionStateCreated:
        NSLog(@"FB Session state created");
        break;
    case FBSessionStateCreatedOpening:
        NSLog(@"FB Session state created opening");
        break;
    case FBSessionStateClosed:
        NSLog(@"FB Session state closed");
        break;
    case FBSessionStateClosedLoginFailed:
        NSLog(@"vSession state login failed");
        break;
    case FBSessionStateCreatedTokenLoaded:
        NSLog(@"FB Session state created token loaded");
        break;
    default:
        NSLog(@"Session state unknown");
        break;
    }  
}

- (void) sessionStateChanged:(FBSession*)session state:(FBSessionState) state error:(NSError*) error {
    [self logState: state];

    if (mAuthResponseSubscribeCallback) {
        NSString* strState;

        switch (state) {
        case FBSessionStateOpen:
        case FBSessionStateOpenTokenExtended:
        case FBSessionStateCreatedTokenLoaded:
            strState = @"{\"status\": \"connected\"}";
            break;
        default:
            strState = @"{\"status\": \"unknown\"}";
            break;
        }

        JSContextRef gCtx = [EJApp instance].jsGlobalContext;
        JSValueRef params[] = { NSStringToJSValue(gCtx, strState) };
        [[EJApp instance] invokeCallback: mAuthResponseSubscribeCallback thisObject: NULL argc: 1 argv: params];
    }
}

- (void) prepareRequest:(FBSession*)session request:(NSString*) request options:(NSString*) options callback:(JSObjectRef) callback {
    FBRequest* fbRequest = [FBRequest alloc];

    if (options && ![options isEqualToString:@"undefined"]) {
        [fbRequest initWithSession: session graphPath: request parameters: @{@"fields": options} HTTPMethod: nil];
    } else {
        [fbRequest initWithSession: session graphPath: request];
    }

    [fbRequest startWithCompletionHandler:^(FBRequestConnection* connection, id result, NSError* error) {
        [fbRequest release];
        [self incomingData:request connection:connection result:result error:error callback:callback];
    }];
}

- (void) incomingData:(NSString*) request connection:(FBRequestConnection*) connection result:(id) result error:(NSError*) error callback:(JSObjectRef) callback {
    JSContextRef gCtx = [EJApp instance].jsGlobalContext;
    
    NSError *jsonError; 
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result 
            options:0
            error:&error];
    NSString *jsonString;

    if (!jsonData) {
        NSLog(@"Error parsing FB results: %@", jsonError);

        [[EJApp instance] invokeCallback: mAuthResponseSubscribeCallback thisObject: NULL argc: 0 argv: nil];
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        JSValueRef params[] = { NSStringToJSValue(gCtx, jsonString) };
        [[EJApp instance] invokeCallback: callback thisObject: NULL argc: 1 argv: params];
    }

    JSValueUnprotect(gCtx, callback);
}

- (void) initialiseSession {
    FBSessionTokenCachingStrategy* pToken = [[[FBSessionTokenCachingStrategy alloc]
            initWithUserDefaultTokenInformationKeyName: @"STokenInfoX"] autorelease];
    mSession = [[FBSession alloc]
            initWithAppID: @"130785027044144"
            permissions:[NSArray arrayWithObject: @""]
            urlSchemeSuffix: @"" tokenCacheStrategy: pToken];
    [FBSession setActiveSession: mSession];
    mSessionInitialised = true;
}

@end
