import 'payment.dart';

abstract class PaymentsRepository {
  Stream<List<Payment>> watch();
}
