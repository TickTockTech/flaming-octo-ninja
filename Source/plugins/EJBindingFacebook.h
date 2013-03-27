#import "EJBindingBase.h"
#import "FacebookSDK/FBSession.h"
#import "FacebookSDK/FBRequest.h"

@interface EJBindingFacebook : EJBindingBase {
	FBSession* 		mSession;
    JSObjectRef 	mAuthResponseSubscribeCallback;
    BOOL			mSessionInitialised;
}

@end
