#import "EJBindingSocket.h"

@implementation EJBindingSocket

- (id)initWithContext:(JSContextRef)ctx 
    object:(JSObjectRef)obj 
    argc:(size_t)argc 
    argv:(const JSValueRef [])argv  {
    if (self = [super initWithContext:ctx object:obj argc:argc argv:argv]) {
        if (argc == 2) {
            mAddr = [[NSString alloc] initWithString: JSValueToNSString(ctx, argv[0])];
            mPort = JSValueToNumberFast(ctx, argv[1]);

            NSLog(@"EJBindingSocket created.");
        } else {
            NSLog(@"Called EJBindingSocket with incorrect number of arguments. Expected address and port.");
        }
    }
    return self;
}

EJ_BIND_FUNCTION (getPort, ctx, argc, argv) {
    return JSValueMakeNumber(ctx, mPort);
}

EJ_BIND_FUNCTION (getAddr, ctx, argc, argv) {
    return NSStringToJSValue(ctx, mAddr);
}

EJ_BIND_FUNCTION (open, ctx, argc, argv) {
    bool status = false;

    mConn = new ClientSocket([mAddr cString], mPort);
 
    status = mConn->openConnection();
    
    mListening = true;

    return JSValueMakeNumber(ctx, status);
}

EJ_BIND_FUNCTION (send, ctx, argc, argv) {
    S32 bytesSent = 0;

    if (argc == 1) {
        NSString* message;
        message = [[NSString alloc] initWithString: JSValueToNSString(ctx, argv[0])];

        bytesSent = mConn->sendData([message cString]);
    } else {
        NSLog(@"Send called with incorrect number of arguments. Expected - send(data)");
    }

    return JSValueMakeNumber(ctx, bytesSent);
}

EJ_BIND_FUNCTION (ondata, ctx, argc, argv) {
    if (argc == 1) {
        mOnDataCallback = JSValueToObject(ctx, argv[0], NULL);
        JSValueProtect(ctx, mOnDataCallback);

        [self performSelectorInBackground:@selector(checkForMessages) withObject:nil];
    } else {
        NSLog(@"ondata called with incorrect number of arguments. Expected - ondata(function)");
    }

    return NULL;
}

- (void) checkForMessages {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    S32 bytesReceived;
    char buffer[512];
    memset(buffer, 0, 512);

    while (mListening) {
        bytesReceived = mConn->receiveData(buffer, 512);

        if (bytesReceived > 0) {
            if (mOnDataCallback) {
                NSString* bufferStr = [[NSString alloc] initWithCString: buffer];
                JSContextRef gCtx = [EJApp instance].jsGlobalContext;
                JSValueRef params[] = { NSStringToJSValue(gCtx, bufferStr) };
                [[EJApp instance] invokeCallback: mOnDataCallback thisObject: NULL argc: 1 argv: params];
                [bufferStr release];
                memset(buffer, 0, 512);
            }
        }
        usleep(25 * 1000); // Check every 1/40th of a second.
    }

    [pool release];
}

EJ_BIND_FUNCTION (close, ctx, argc, argv) {
    JSContextRef gCtx = [EJApp instance].jsGlobalContext;
    JSValueUnprotect(gCtx, mOnDataCallback);

    mListening = false;

    mConn->closeConnection();

    delete mConn;

    return NULL;
}

EJ_BIND_FUNCTION (release, cts, argc, argv) {
    [mAddr release];
    
    return NULL;
}


@end
