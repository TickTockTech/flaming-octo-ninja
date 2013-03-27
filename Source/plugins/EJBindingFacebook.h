#import "EJBindingBase.h"
#import "FBSession.h"
#import "FBRequest.h"

@interface EJBindingFacebook : EJBindingBase {
	FBSession* 		mSession;
    JSObjectRef 	mAuthResponseSubscribeCallback;
    BOOL			mSessionInitialised;
}

@end
