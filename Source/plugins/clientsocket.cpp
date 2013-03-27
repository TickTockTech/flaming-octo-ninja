//
//  clientsocket.cpp
//  Tamagotchi
//
//  Created by Allan Robertson on 28/02/2013.
//
//

#include "stdio.h"
#include "clientsocket.h"
#include "../core/koyoki.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <errno.h>
#include <string>

#ifndef DEBUG_OUT
#error "Debug not defined!"
#endif

ClientSocket::ClientSocket(const char* addr, int port) {
    DEBUG_MSG("ClientSocket()");
    
    mState = CS_STATE_UNINITIALISED;

    mAddr = addr;
    memset(mPort, 0, 6);
    sprintf(mPort, "%d", port);
}

bool ClientSocket::checkServerConnection() {
    S32 status;
    struct addrinfo hints;
    
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;     // don't care IPv4 or IPv6
    hints.ai_socktype = SOCK_STREAM; // TCP stream sockets
    hints.ai_flags = AI_PASSIVE;     // fill in my IP for me
    
    status = getaddrinfo(mAddr, mPort, &hints, &mServerInfo);
    
    if (status != 0) {
        DEBUG_LVL(DEBUG_WARNING, "Error requesting network information: %s.", gai_strerror(status));
    }
    
    status = getnameinfo(mServerInfo->ai_addr, mServerInfo->ai_addrlen, mHostName, MAX_HOST, NULL, 0, 0);
    
    if (status != 0) {
        DEBUG_LVL(DEBUG_WARNING, "Error resolving host name: %s.", strerror(errno));
    }
    
    if (mState == CS_STATE_UNINITIALISED) {
        mState = CS_STATE_HOSTCHECKED;
    }

    return true;
}

bool ClientSocket::openConnection() {
    if (mState == CS_STATE_UNINITIALISED && !checkServerConnection()) {
        return false;
    }
    
    mSocket = socket(mServerInfo->ai_family, mServerInfo->ai_socktype, mServerInfo->ai_protocol);
    
    if (mSocket == -1) {
        DEBUG_LVL(DEBUG_WARNING, "Failed to create socket: %s.", strerror(errno));
        return false;
    }

    // Don't block when recv called.
    u_long val = 1;
    ioctl(mSocket, FIONBIO, &val);

    S32 status;

    status = connect(mSocket, mServerInfo->ai_addr, mServerInfo->ai_addrlen);
    
    if (status == -1) {
        DEBUG_LVL(DEBUG_WARNING, "Failed to connect socket: %s.", strerror(errno));
        return false;
    }

    DEBUG_OUT("Connected to: %s:", mHostName);

    return true;
}

S32 ClientSocket::sendData(const char* data) {
    S32 len = strlen(data);
    S32 bytesSent = 0;

    // TODO: Check socket state first maybe
    bytesSent = send(mSocket, data, len, 0);

    DEBUG_OUT("NET ~~> %d bytes.", bytesSent);

    if (bytesSent == -1) {
        DEBUG_LVL(DEBUG_WARNING, "Error sending data: %s.", strerror(errno));
    }

    return bytesSent;
}

S32 ClientSocket::receiveData(void* buff, S32 buffLen) {
    S32 bytesReceived;

    bytesReceived = recv(mSocket, buff, buffLen, 0);

    if (bytesReceived > 0) {
        DEBUG_OUT("NET <~~ %d bytes.", bytesReceived);
    }

    return bytesReceived;
}

void ClientSocket::closeConnection() {
    DEBUG_OUT("Closed connection to: %s", mHostName);

	close(mSocket);
}

ClientSocket::~ClientSocket() {
    DEBUG_MSG("~ClientSocket()");

    if (mState != CS_STATE_UNINITIALISED) {
        freeaddrinfo(mServerInfo);
    }
}
