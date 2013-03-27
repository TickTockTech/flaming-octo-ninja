//
//  clientsocket.h
//  Tamagotchi
//
//  Created by Allan Robertson on 28/02/2013.
//
//

#ifndef Tamagotchi_clientsocket_h
#define Tamagotchi_clientsocket_h

#include <sys/types.h>
#include "../core/types.h"

#define MAX_HOST 256

#define CS_STATE_UNINITIALISED      0
#define CS_STATE_HOSTCHECKED        1

class ClientSocket {
public:
    ClientSocket(const char* addr, int port);
    ~ClientSocket();

    bool checkServerConnection();
    
    bool openConnection();
    S32 sendData(const char* data);
    S32 receiveData(void* buff, S32 buffLen);
    void closeConnection();

private:
    int                 mSocket;
	char                mHostName[MAX_HOST];
    U32                 mState;
    const char*         mAddr;
    char                mPort[6];
    struct addrinfo*    mServerInfo;
};

#endif
