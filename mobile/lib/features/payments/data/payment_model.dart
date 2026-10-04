import '../../../core/utils/date_utils.dart';
import '../domain/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.userId,
    required super.productId,
    required super.membershipPlanId,
    required super.credits,
    required super.amount,
    required super.status,
    required super.paymentMethod,
    required super.createdAt,
    required super.productName,
    required super.size,
    required super.estimatedDeliveryDate,
    required super.deliveryNote,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) => PaymentModel(
    id: map['id'] as String? ?? '',
    userId: map['userId'] as String? ?? '',
    productId: map['productId'] as String?,
    membershipPlanId: map['membershipPlanId'] as String?,
    credits: (map['credits'] as num?)?.toInt(),
    amount: map['amount'] as num? ?? 0,
    status: map['status'] as String? ?? '',
    paymentMethod: map['paymentMethod'] as String?,
    createdAt: readDate(map['createdAt']),
    productName: map['productName'] as String?,
    size: map['size'] as String?,
    estimatedDeliveryDate: map['estimatedDeliveryDate'] == null
        ? null
        : readDate(map['estimatedDeliveryDate']),
    deliveryNote: map['deliveryNote'] as String?,
  );
}
