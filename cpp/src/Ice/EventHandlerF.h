// **********************************************************************
//
// Copyright (c) 2003-2017 ZeroC, Inc. All rights reserved.
//
// This copy of Ice is licensed to you under the terms described in the
// ICE_LICENSE file included in this distribution.
//
// **********************************************************************

#ifndef ICE_EVENT_HANDLER_F_H
#define ICE_EVENT_HANDLER_F_H

#include <IceUtil/Shared.h>

#include <Ice/Handle.h>

namespace IceInternal
{

class EventHandler;
#ifdef ICE_CPP11_MAPPING
using EventHandlerPtr = ::std::shared_ptr<EventHandler>;
#else
ICE_API IceUtil::Shared* upCast(EventHandler*);
typedef Handle<EventHandler> EventHandlerPtr;
#endif
}

#endif
