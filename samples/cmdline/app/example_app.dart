library dice_cmdline_example;

import "package:dryice/dryice.dart" as di;

part "lib/_billing.dart";
part "lib/_events.dart";

enum Mode { Production, Development }

main() {
    final injector = new di.Injector(new ExampleModule(Mode.Production));

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
