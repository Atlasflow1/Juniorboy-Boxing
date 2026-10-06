abstract final class AppRoutes {
  static const welcome = '/welcome';
  static const home = '/home';
  static const schedulePath = '/schedule';
  static const book = '/book';
  static const membership = '/membership';
  static const more = '/more';
  static const store = '/store';
  static const bookingPath = '/booking/:id';
  static const bookingConfirmed = '/booking-confirmed';
  static const bookings = '/bookings';
  static const profile = '/profile';
  static const completeProfile = '/complete-profile';
  static const notifications = '/notifications';
  static const payments = '/payments';
  static const reviews = '/reviews';
  static const admin = '/admin';
  static const adminAdEditor = '/admin/ad-editor';
  static const adminSessionEditor = '/admin/session-editor';
  static const sessionMembers = '/session-members';
  static const blog = '/blog';
  static const contact = '/contact';
  static const about = '/about';
  static const privacy = '/privacy';
  static const terms = '/terms';
  static const waiver = '/waiver';
  static const programPath = '/programs/:id';

  static String booking(String id) => '/booking/${Uri.encodeComponent(id)}';
  static String program(String id) => '/programs/${Uri.encodeComponent(id)}';
  static String schedule({String? programId}) => programId == null
      ? schedulePath
      : Uri(
          path: schedulePath,
          queryParameters: {'program': programId},
        ).toString();
}
