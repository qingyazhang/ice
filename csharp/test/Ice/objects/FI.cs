// **********************************************************************
//
// Copyright (c) 2003-2017 ZeroC, Inc. All rights reserved.
//
// This copy of Ice is licensed to you under the terms described in the
// ICE_LICENSE file included in this distribution.
//
// **********************************************************************

using Test;

public sealed class FI : F
{
    public FI()
    {
    }

    public FI(E e) : base(e, e)
    {
    }

    public bool checkValues()
    {
        return e1 != null && e1 == e2;
    }
}
