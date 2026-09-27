/// The gym's fixed set of training programs. Keys match the `category`
/// field on `membershipPlans` docs and the `/programs/:id` route slug.
abstract final class Programs {
  static const categories = {
    'boxing': 'Boxing Training',
    'fitness': 'Fitness Training',
    'strength': 'Strength & Conditioning',
    'weight-loss': 'Weight Loss Training',
    'self-defense': 'Self Defense Training',
  };
}
