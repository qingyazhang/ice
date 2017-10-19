%{
**********************************************************************

Copyright (c) 2003-2017 ZeroC, Inc. All rights reserved.

This copy of Ice is licensed to you under the terms described in the
ICE_LICENSE file included in this distribution.

**********************************************************************
%}

function client(args)
    addpath('generated');
    addpath('../../lib');
    if ~libisloaded('ice')
        loadlibrary('ice', @iceproto)
    end

    initData = TestApp.createInitData('client', args);
    initData.properties_.setProperty('Ice.Warn.Connections', '0');
    initData.properties_.setProperty('Ice.MessageSizeMax', '10'); % 10KB max
    communicator = Ice.initialize(initData);
    cleanup = onCleanup(@() communicator.destroy());

    app = TestApp(communicator);
    thrower = AllTests.allTests(app);
    thrower.shutdown();

    clear('classes'); % Avoids conflicts with tests that define the same symbols.
end