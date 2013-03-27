#import "EJBindingBase.h"
#import "clientsocket.h"

@interface EJBindingSocket : EJBindingBase {
	NSString* 		mAddr;
    int 			mPort;
    ClientSocket* 	mConn;
    JSObjectRef 	mOnDataCallback;
    bool 			mListening;
}

@end
