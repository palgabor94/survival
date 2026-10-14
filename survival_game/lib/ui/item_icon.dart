/// Small item silhouettes have alpha backgrounds; card scenes remain separate.
const itemIconSubjects = <String>[
  'machete',
  'emergency_beacon',
  'battery',
  'wire',
  'metal_parts',
  'radio_module',
  'beacon_core',
];

String? itemIconFor(String subject) => itemIconSubjects.contains(subject)
    ? 'assets/art/icon_${subject}_v1.png'
    : null;
