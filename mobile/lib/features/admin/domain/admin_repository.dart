import 'dart:io';

import '../../booking/domain/booking.dart';
import '../../membership/domain/membership_plan.dart';
import '../../payments/domain/payment.dart';
import '../../profile/domain/member.dart';
import 'recurring_template.dart';

abstract class AdminRepository {
  String newId();
  Stream<List<MembershipPlan>> plans();
  Stream<List<RecurringTemplate>> templates();
  Stream<List<Payment>> orders();
  Stream<List<Booking>> bookings();
  Future<Member?> buyer(String userId);
  Future<void> savePlan(String id, Map<String, dynamic> values);
  Future<void> deletePlan(String id);
  Future<void> saveTemplate(String id, Map<String, dynamic> values);
  Future<void> deleteTemplate(String id);
  Future<void> savePromoVideoUrl(String url);
  Future<void> saveGymInfo(String address, String phone);
  Future<void> uploadPromoVideo(File file);
  Future<void> setOrderDelivery(String paymentId, DateTime date, String note);
  Future<void> deletePayment(String paymentId);
  Future<void> markAttendance(String bookingId, String status);
  Future<void> cancelBookingAsAdmin(String bookingId, String reason);
}
