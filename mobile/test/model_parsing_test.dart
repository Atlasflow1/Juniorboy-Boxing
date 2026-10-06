import 'package:flutter_test/flutter_test.dart';
import 'package:junior_boy_boxing/features/booking/data/booking_model.dart';
import 'package:junior_boy_boxing/features/booking/domain/booking_eligibility.dart';
import 'package:junior_boy_boxing/features/membership/data/membership_plan_model.dart';
import 'package:junior_boy_boxing/features/home/data/home_repository_impl.dart';
import 'package:junior_boy_boxing/features/home/data/home_ad_model.dart';
import 'package:junior_boy_boxing/core/utils/address_utils.dart';
import 'package:junior_boy_boxing/features/profile/data/member_model.dart';
import 'package:junior_boy_boxing/features/schedule/data/session_model.dart';
import 'package:junior_boy_boxing/features/schedule/data/program_model.dart';
import 'package:junior_boy_boxing/features/store/data/product_model.dart';
import 'package:junior_boy_boxing/features/reviews/data/review_model.dart';
import 'package:junior_boy_boxing/features/profile/data/gym_settings_model.dart';

void main() {
  test('blank optional presentation fields normalize to null', () {
    final program = ProgramModel.fromMap({
      'className': ' ',
      'ageGroup': '',
      'address': '  ',
    });
    expect(program.className, isNull);
    expect(program.ageGroup, isNull);
    expect(program.address, isNull);
    expect(MemberModel.fromMap({'fullName': '  '}).fullName, isNull);
    expect(ProductModel.fromMap({'name': ' ', 'description': ''}).name, isNull);
    expect(GymSettingsModel.fromMap({'aboutText': ' '}).aboutText, isNull);
    expect(ReviewModel.fromMap({'userName': ' '}).userName, 'Member');
  });
  test('booking parses dates and missing fields', () {
    final date = DateTime.utc(2026, 10, 5, 12);
    final booking = BookingModel.fromMap({
      'id': 'b1',
      'date': date.toIso8601String(),
      'className': 'Junior Boxing',
      'status': 'confirmed',
    });
    expect(booking.id, 'b1');
    expect(booking.date, date);
    expect(booking.endAt.millisecondsSinceEpoch, 0);
    expect(BookingModel.fromMap({}).status, '');
  });

  test('schedule parses counters and defaults', () {
    final session = SessionModel.fromMap({
      'id': 's1',
      'maxSpots': 12,
      'bookedSpots': 3,
    });
    expect(session.maxSpots - session.bookedSpots, 9);
    expect(session.isCancelled, false);
    expect(session.date.millisecondsSinceEpoch, 0);
    expect(SessionModel.fromMap({}).maxSpots, 0);
  });

  test('one-off session slot keeps date, times, and capacity', () {
    final slot = SessionModel.fromMap({
      'id': 'slot-1',
      'classId': 'boxing',
      'date': '2026-10-10T17:00:00.000Z',
      'endAt': '2026-10-10T18:00:00.000Z',
      'startTime': '10:00',
      'endTime': '11:00',
      'maxSpots': 2,
      'bookedSpots': 1,
    });
    expect(slot.classId, 'boxing');
    expect(slot.startTime, '10:00');
    expect(slot.endTime, '11:00');
    expect(slot.maxSpots - slot.bookedSpots, 1);
  });

  test('program and ad parse admin fields', () {
    final program = ProgramModel.fromMap({
      'id': 'p',
      'trainingType': 'duo',
      'category': 'Team',
      'price': 6000,
      'adImages': ['one', '', 'two'],
      'discountActive': true,
      'discountPercent': 15,
    });
    final ad = HomeAdModel.fromMap({
      'id': 'a',
      'title': 'Special',
      'price': 3000,
      'linkHref': '/pricing',
      'sortOrder': 2,
      'isActive': false,
    });
    expect(program.trainingType, 'duo');
    expect(program.adImages, ['one', 'two']);
    expect(program.discountPercent, 15);
    expect(ad.linkHref, '/pricing');
    expect(ad.sortOrder, 2);
    expect(ad.isActive, false);
  });

  test('structured address parses and composes the Firestore string', () {
    final address = StructuredAddress.parse('3200 Naglee Rd, Tracy, CA');
    expect(address.houseNumber, '3200');
    expect(address.streetName, 'Naglee Rd');
    expect(address.city, 'Tracy');
    expect(address.country, 'CA');
    expect(address.formatted, '3200 Naglee Rd, Tracy, CA');
    expect(StructuredAddress.parse('3200 Naglee Rd, Tracy, 95376, USA').country, 'USA');
  });

  test('membership plan parses nullable count and defaults', () {
    final plan = MembershipPlanModel.fromMap({
      'id': 'hourly',
      'sortOrder': 2,
      'isRecommended': true,
    });
    expect(plan.sessionCount, isNull);
    expect(plan.category, isNull);
    expect(plan.isRecommended, true);
    expect(plan.sortOrder, 2);
    expect(MembershipPlanModel.fromMap({}).perSessionLabel, '');
  });

  test('member parses counters and missing fields', () {
    final member = MemberModel.fromMap({
      'id': 'u1',
      'sessionsRemaining': 5,
      'sessionsReserved': 1,
    });
    expect(member.sessionsRemaining - member.sessionsReserved, 4);
    expect(member.childName, '');
    expect(MemberModel.fromMap({}).sessionsRemaining, 0);
  });

  test('booking eligibility respects the policy boundary', () {
    final now = DateTime.utc(2026, 10, 4, 12);
    final booking = BookingModel.fromMap({
      'date': now.add(const Duration(hours: 24)).toIso8601String(),
      'status': 'confirmed',
    });
    expect(isUpcomingBooking(booking, now), true);
    expect(canCancelBooking(booking, now, 24), true);
    expect(
      canCancelBooking(booking, now.add(const Duration(seconds: 1)), 24),
      false,
    );
    expect(canCancelBooking(booking, now, 25), false);
  });
  test('home selects the nearest confirmed future booking', () {
    final now = DateTime.utc(2026, 10, 4, 12);
    final rows = [
      BookingModel.fromMap({
        'date': now.add(const Duration(days: 3)).toIso8601String(),
        'status': 'confirmed',
      }),
      BookingModel.fromMap({
        'date': now.add(const Duration(days: 1)).toIso8601String(),
        'status': 'confirmed',
      }),
      BookingModel.fromMap({
        'date': now.add(const Duration(hours: 2)).toIso8601String(),
        'status': 'cancelled',
      }),
    ];
    expect(
      HomeRepositoryImpl().nextBooking(rows, now)?.date,
      now.add(const Duration(days: 1)),
    );
  });
}
