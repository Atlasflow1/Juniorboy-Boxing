import 'dart:io';

import '../../booking/data/booking_model.dart';
import '../../booking/domain/booking.dart';
import '../../membership/data/membership_plan_model.dart';
import '../../payments/data/payment_model.dart';
import '../../membership/domain/membership_plan.dart';
import '../../payments/domain/payment.dart';
import '../../profile/domain/member.dart';
import '../domain/admin_repository.dart';
import '../domain/recurring_template.dart';
import 'admin_remote_data_source.dart';
import 'recurring_template_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this.source);
  final AdminRemoteDataSource source;

  @override
  String newId() => source.newId();
  @override
  Stream<List<MembershipPlan>> plans() => source.plans().map(
    (rows) => rows.map<MembershipPlan>(MembershipPlanModel.fromMap).toList(),
  );
  @override
  Stream<List<RecurringTemplate>> templates() => source.templates().map(
    (rows) =>
        rows.map<RecurringTemplate>(RecurringTemplateModel.fromMap).toList(),
  );
  @override
  Stream<List<Payment>> orders() => source.orders().map(
    (rows) => rows.map<Payment>(PaymentModel.fromMap).toList(),
  );
  @override
  Stream<List<Booking>> bookings() => source.bookings().map(
    (rows) => rows.map<Booking>(BookingModel.fromMap).toList(),
  );
  @override
  Future<Member?> buyer(String userId) => source.buyer(userId);
  @override
  Future<void> savePlan(String id, Map<String, dynamic> values) =>
      source.savePlan(id, values);
  @override
  Future<void> deletePlan(String id) => source.deletePlan(id);
  @override
  Future<void> saveTemplate(String id, Map<String, dynamic> values) =>
      source.saveTemplate(id, values);
  @override
  Future<void> deleteTemplate(String id) => source.deleteTemplate(id);
  @override
  Future<void> savePromoVideoUrl(String url) => source.savePromoVideoUrl(url);
  @override
  Future<void> saveGymInfo(String address, String phone) =>
      source.saveGymInfo(address, phone);
  @override
  Future<void> uploadPromoVideo(File file) => source.uploadPromoVideo(file);
  @override
  Future<void> setOrderDelivery(String id, DateTime date, String note) =>
      source.setOrderDelivery(id, date, note);
  @override
  Future<void> deletePayment(String id) => source.deletePayment(id);
  @override
  Future<void> markAttendance(String id, String status) =>
      source.markAttendance(id, status);
  @override
  Future<void> cancelBookingAsAdmin(String id, String reason) =>
      source.cancelBookingAsAdmin(id, reason);
}
