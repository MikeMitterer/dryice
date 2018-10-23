// Copyright (c) 2017, the project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed
// by a Apache license that can be found in the LICENSE file.

part of cmdline;

@inject
abstract class Emailer {
    void sendMail();
}

@inject
class EmailerToGoogle implements Emailer {
    @override
    void sendMail() {
        print("Send mail to Google");
    }
}

@inject
class EmailerToGMX implements Emailer {
    @override
    void sendMail() {
        print("Send mail to GMX");
    }
}

@inject
class EventScheduler {

    final Emailer _emailer;

    @inject
    EventScheduler(this._emailer);

    void send() => _emailer.sendMail();
}