// Copyright (c) 2013, the project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed
// by a Apache license that can be found in the LICENSE file.

library dice_cmdline_example;

import 'package:dryice/dryice.dart' as di;
import 'package:dryice_sample_cmdline/cmdline.dart';

import 'main.reflectable.dart';

enum Mode { Production, Development }

main() {
    initializeReflectable();
    
    final injector = new di.Injector(new ExampleModule(Mode.Development));

    final billingService = injector.getInstance(BillingService);
    
    final creditCard = new CreditCard("VISA");
    final order = new Order("Dart: Up and Running");
    
    billingService.chargeOrder(order, creditCard);

    final EventScheduler scheduler = injector.get(EventScheduler);
    scheduler.send();
}

class ExampleModule extends di.Module {
    final Mode _mode;

    ExampleModule(this._mode);

    @override
    configure() {

        // bind CreditCardProcessor to a singleton
        bind(CreditProcessor).to(CreditProcessorImpl).asSingleton();
        
        // bind BillingService to a type
        bind(BillingService).to(BillingServiceImpl);

        bind(EventScheduler);

        if(_mode == Mode.Development) {
            // Configure it you want your mail to be sent to GMX
            bind(Emailer).to(EmailerToGMX);

        } else {
            // or to Google
            bind(Emailer).to(EmailerToGoogle);
        }
    }
}
