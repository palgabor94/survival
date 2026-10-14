/// A sent signal starts the final storm on the next dawn.
enum RescueStage { searching, signalSent, storm }

const beaconComponents = {
  'battery': 'Battery',
  'wire': 'Wire',
  'metal_parts': 'Metal Parts',
  'radio_module': 'Radio Module',
  'beacon_core': 'Beacon Core',
};

const rescueEventIds = [
  'rescue_rising_water',
  'rescue_falling_branches',
  'rescue_last_signal',
];
