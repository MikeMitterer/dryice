// Copyright (c) 2017, the project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed
// by a Apache license that can be found in the LICENSE file.

part of cmdline;

@inject
class BillingServiceImpl implements BillingService {

  @inject
  CreditProcessor processor;

  Receipt chargeOrder(Order order, CreditCard creditCard) {
    if(!(processor.validate(creditCard))) {
      throw new ArgumentError("payment method not accepted");
    }
    // :
    print("charge order for ${order.item}");
    // :
    return new Receipt(order);
  }
}

@inject
class CreditProcessorImpl implements CreditProcessor {
  bool validate(CreditCard card) => card.type.toUpperCase() == "VISA";
}

@inject
abstract class BillingService {
  Receipt chargeOrder(Order order, CreditCard creditCard);
}

@inject
abstract class CreditProcessor {
  bool validate(CreditCard creditCard);
}

class CreditCard {
  CreditCard(this.type);
  final String type;
}

class Order {
  Order(this.item);
  final String item;
}

class Receipt {
  final Order order;

  Receipt(this.order);
}
