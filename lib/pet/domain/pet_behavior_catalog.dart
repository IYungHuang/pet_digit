import 'pet_world.dart';

/// Stable phase used to group pet behaviors.
///
/// Categories describe intent, not runtime execution. Runtime sequences remain
/// owned by [PetWorldController] and [PetActionType].
enum PetBehaviorCategory {
  approach,
  investigate,
  evaluate,
  caution,
  avoid,
  engage,
  locomotion,
  social,
  emotion,
  care,
  environment,
}

/// External event that can cause a behavior sequence to start.
enum PetStimulusType {
  newMessageBubble,
  emoji,
  gif,
  loudSound,
  nearbyPet,
  roomChange,
}

/// Animation-ready behavior names. Adding a value does not change runtime
/// behavior until a definition and trigger are added.
enum PetBehaviorAction {
  walkTrot,
  runChase,
  greetingSniff,
  playBow,
  alertEarsUp,
  appeasementLick,
  scratchBody,
  pantRest,
  sniffInvestigate,
  markTerritory,

  walkStalk,
  pounce,
  headBuntRub,
  playChase,
  alertOrient,
  startleArch,
  selfGroom,
  stretchKnead,
  scratch,
  forageBat,

  walkClimb,
  flyFlap,
  contactCall,
  beakTouch,
  alertCrest,
  relaxedFluff,
  preen,
  batheShake,
  foragePick,
  chewManipulate,

  approachArc,
  approachStopStart,
  sniffBubble,
  circleSniff,
  headTiltFocus,
  freezeWeightShift,
  retreatLookback,
  nosePawBump,

  approachLowSilent,
  approachPauseRetreat,
  sniffWhiskerScan,
  pawTest,
  orientEarsTail,
  stareCrouch,
  hidePeek,
  batPounce,

  approachSideways,
  leanForwardPause,
  headTiltEyeFocus,
  beakProbe,
  crestBodyScan,
  freezeGrip,
  flyBack,
  beakManipulate,
}

class PetActionDefinition {
  const PetActionDefinition({
    required this.action,
    required this.category,
    required this.animationKey,
  });

  final PetBehaviorAction action;
  final PetBehaviorCategory category;
  final String animationKey;
}

class PetBehaviorTrigger {
  const PetBehaviorTrigger({
    required this.stimulus,
    required this.action,
    this.petType,
    this.priority = 0,
  });

  final PetStimulusType stimulus;
  final PetBehaviorAction action;
  final PetType? petType;
  final int priority;
}

class PetBehaviorProfile {
  const PetBehaviorProfile({
    required this.petType,
    required this.actions,
    required this.novelObjectActions,
  });

  final PetType petType;
  final List<PetBehaviorAction> actions;
  final List<PetBehaviorAction> novelObjectActions;
}

/// Data-only catalog for future behavior selection and animation playback.
///
/// This catalog is intentionally separate from [PetActionType]. The latter is
/// the current runtime flow; this catalog describes the full behavior space.
class PetBehaviorCatalog {
  const PetBehaviorCatalog._();

  static const profiles = <PetType, PetBehaviorProfile>{
    PetType.corgi: PetBehaviorProfile(
      petType: PetType.corgi,
      actions: <PetBehaviorAction>[
        PetBehaviorAction.walkTrot,
        PetBehaviorAction.runChase,
        PetBehaviorAction.greetingSniff,
        PetBehaviorAction.playBow,
        PetBehaviorAction.alertEarsUp,
        PetBehaviorAction.appeasementLick,
        PetBehaviorAction.scratchBody,
        PetBehaviorAction.pantRest,
        PetBehaviorAction.sniffInvestigate,
        PetBehaviorAction.markTerritory,
      ],
      novelObjectActions: <PetBehaviorAction>[
        PetBehaviorAction.approachArc,
        PetBehaviorAction.approachStopStart,
        PetBehaviorAction.sniffBubble,
        PetBehaviorAction.circleSniff,
        PetBehaviorAction.headTiltFocus,
        PetBehaviorAction.freezeWeightShift,
        PetBehaviorAction.retreatLookback,
        PetBehaviorAction.nosePawBump,
      ],
    ),
    PetType.cat: PetBehaviorProfile(
      petType: PetType.cat,
      actions: <PetBehaviorAction>[
        PetBehaviorAction.walkStalk,
        PetBehaviorAction.pounce,
        PetBehaviorAction.headBuntRub,
        PetBehaviorAction.playChase,
        PetBehaviorAction.alertOrient,
        PetBehaviorAction.startleArch,
        PetBehaviorAction.selfGroom,
        PetBehaviorAction.stretchKnead,
        PetBehaviorAction.scratch,
        PetBehaviorAction.forageBat,
      ],
      novelObjectActions: <PetBehaviorAction>[
        PetBehaviorAction.approachLowSilent,
        PetBehaviorAction.approachPauseRetreat,
        PetBehaviorAction.sniffWhiskerScan,
        PetBehaviorAction.pawTest,
        PetBehaviorAction.orientEarsTail,
        PetBehaviorAction.stareCrouch,
        PetBehaviorAction.hidePeek,
        PetBehaviorAction.batPounce,
      ],
    ),
    PetType.parrot: PetBehaviorProfile(
      petType: PetType.parrot,
      actions: <PetBehaviorAction>[
        PetBehaviorAction.walkClimb,
        PetBehaviorAction.flyFlap,
        PetBehaviorAction.contactCall,
        PetBehaviorAction.beakTouch,
        PetBehaviorAction.alertCrest,
        PetBehaviorAction.relaxedFluff,
        PetBehaviorAction.preen,
        PetBehaviorAction.batheShake,
        PetBehaviorAction.foragePick,
        PetBehaviorAction.chewManipulate,
      ],
      novelObjectActions: <PetBehaviorAction>[
        PetBehaviorAction.approachSideways,
        PetBehaviorAction.leanForwardPause,
        PetBehaviorAction.headTiltEyeFocus,
        PetBehaviorAction.beakProbe,
        PetBehaviorAction.crestBodyScan,
        PetBehaviorAction.freezeGrip,
        PetBehaviorAction.flyBack,
        PetBehaviorAction.beakManipulate,
      ],
    ),
  };

  static const actionDefinitions = <PetBehaviorAction, PetActionDefinition>{
    PetBehaviorAction.walkTrot: PetActionDefinition(
      action: PetBehaviorAction.walkTrot,
      category: PetBehaviorCategory.locomotion,
      animationKey: 'walk_trot',
    ),
    PetBehaviorAction.runChase: PetActionDefinition(
      action: PetBehaviorAction.runChase,
      category: PetBehaviorCategory.locomotion,
      animationKey: 'run_chase',
    ),
    PetBehaviorAction.greetingSniff: PetActionDefinition(
      action: PetBehaviorAction.greetingSniff,
      category: PetBehaviorCategory.social,
      animationKey: 'greeting_sniff',
    ),
    PetBehaviorAction.playBow: PetActionDefinition(
      action: PetBehaviorAction.playBow,
      category: PetBehaviorCategory.social,
      animationKey: 'play_bow',
    ),
    PetBehaviorAction.alertEarsUp: PetActionDefinition(
      action: PetBehaviorAction.alertEarsUp,
      category: PetBehaviorCategory.emotion,
      animationKey: 'alert_ears_up',
    ),
    PetBehaviorAction.appeasementLick: PetActionDefinition(
      action: PetBehaviorAction.appeasementLick,
      category: PetBehaviorCategory.emotion,
      animationKey: 'appeasement_lick',
    ),
    PetBehaviorAction.scratchBody: PetActionDefinition(
      action: PetBehaviorAction.scratchBody,
      category: PetBehaviorCategory.care,
      animationKey: 'scratch_body',
    ),
    PetBehaviorAction.pantRest: PetActionDefinition(
      action: PetBehaviorAction.pantRest,
      category: PetBehaviorCategory.care,
      animationKey: 'pant_rest',
    ),
    PetBehaviorAction.sniffInvestigate: PetActionDefinition(
      action: PetBehaviorAction.sniffInvestigate,
      category: PetBehaviorCategory.environment,
      animationKey: 'sniff_investigate',
    ),
    PetBehaviorAction.markTerritory: PetActionDefinition(
      action: PetBehaviorAction.markTerritory,
      category: PetBehaviorCategory.environment,
      animationKey: 'mark_territory',
    ),
    PetBehaviorAction.walkStalk: PetActionDefinition(
      action: PetBehaviorAction.walkStalk,
      category: PetBehaviorCategory.locomotion,
      animationKey: 'walk_stalk',
    ),
    PetBehaviorAction.pounce: PetActionDefinition(
      action: PetBehaviorAction.pounce,
      category: PetBehaviorCategory.engage,
      animationKey: 'pounce',
    ),
    PetBehaviorAction.headBuntRub: PetActionDefinition(
      action: PetBehaviorAction.headBuntRub,
      category: PetBehaviorCategory.social,
      animationKey: 'head_bunt_rub',
    ),
    PetBehaviorAction.playChase: PetActionDefinition(
      action: PetBehaviorAction.playChase,
      category: PetBehaviorCategory.engage,
      animationKey: 'play_chase',
    ),
    PetBehaviorAction.alertOrient: PetActionDefinition(
      action: PetBehaviorAction.alertOrient,
      category: PetBehaviorCategory.emotion,
      animationKey: 'alert_orient',
    ),
    PetBehaviorAction.startleArch: PetActionDefinition(
      action: PetBehaviorAction.startleArch,
      category: PetBehaviorCategory.caution,
      animationKey: 'startle_arch',
    ),
    PetBehaviorAction.selfGroom: PetActionDefinition(
      action: PetBehaviorAction.selfGroom,
      category: PetBehaviorCategory.care,
      animationKey: 'self_groom',
    ),
    PetBehaviorAction.stretchKnead: PetActionDefinition(
      action: PetBehaviorAction.stretchKnead,
      category: PetBehaviorCategory.care,
      animationKey: 'stretch_knead',
    ),
    PetBehaviorAction.scratch: PetActionDefinition(
      action: PetBehaviorAction.scratch,
      category: PetBehaviorCategory.environment,
      animationKey: 'scratch',
    ),
    PetBehaviorAction.forageBat: PetActionDefinition(
      action: PetBehaviorAction.forageBat,
      category: PetBehaviorCategory.engage,
      animationKey: 'forage_bat',
    ),
    PetBehaviorAction.walkClimb: PetActionDefinition(
      action: PetBehaviorAction.walkClimb,
      category: PetBehaviorCategory.locomotion,
      animationKey: 'walk_climb',
    ),
    PetBehaviorAction.flyFlap: PetActionDefinition(
      action: PetBehaviorAction.flyFlap,
      category: PetBehaviorCategory.locomotion,
      animationKey: 'fly_flap',
    ),
    PetBehaviorAction.contactCall: PetActionDefinition(
      action: PetBehaviorAction.contactCall,
      category: PetBehaviorCategory.social,
      animationKey: 'contact_call',
    ),
    PetBehaviorAction.beakTouch: PetActionDefinition(
      action: PetBehaviorAction.beakTouch,
      category: PetBehaviorCategory.social,
      animationKey: 'beak_touch',
    ),
    PetBehaviorAction.alertCrest: PetActionDefinition(
      action: PetBehaviorAction.alertCrest,
      category: PetBehaviorCategory.emotion,
      animationKey: 'alert_crest',
    ),
    PetBehaviorAction.relaxedFluff: PetActionDefinition(
      action: PetBehaviorAction.relaxedFluff,
      category: PetBehaviorCategory.emotion,
      animationKey: 'relaxed_fluff',
    ),
    PetBehaviorAction.preen: PetActionDefinition(
      action: PetBehaviorAction.preen,
      category: PetBehaviorCategory.care,
      animationKey: 'preen',
    ),
    PetBehaviorAction.batheShake: PetActionDefinition(
      action: PetBehaviorAction.batheShake,
      category: PetBehaviorCategory.care,
      animationKey: 'bathe_shake',
    ),
    PetBehaviorAction.foragePick: PetActionDefinition(
      action: PetBehaviorAction.foragePick,
      category: PetBehaviorCategory.environment,
      animationKey: 'forage_pick',
    ),
    PetBehaviorAction.chewManipulate: PetActionDefinition(
      action: PetBehaviorAction.chewManipulate,
      category: PetBehaviorCategory.engage,
      animationKey: 'chew_manipulate',
    ),
    PetBehaviorAction.approachArc: PetActionDefinition(
      action: PetBehaviorAction.approachArc,
      category: PetBehaviorCategory.approach,
      animationKey: 'approach_arc',
    ),
    PetBehaviorAction.approachStopStart: PetActionDefinition(
      action: PetBehaviorAction.approachStopStart,
      category: PetBehaviorCategory.approach,
      animationKey: 'approach_stop_start',
    ),
    PetBehaviorAction.sniffBubble: PetActionDefinition(
      action: PetBehaviorAction.sniffBubble,
      category: PetBehaviorCategory.investigate,
      animationKey: 'sniff_bubble',
    ),
    PetBehaviorAction.circleSniff: PetActionDefinition(
      action: PetBehaviorAction.circleSniff,
      category: PetBehaviorCategory.investigate,
      animationKey: 'circle_sniff',
    ),
    PetBehaviorAction.headTiltFocus: PetActionDefinition(
      action: PetBehaviorAction.headTiltFocus,
      category: PetBehaviorCategory.evaluate,
      animationKey: 'head_tilt_focus',
    ),
    PetBehaviorAction.freezeWeightShift: PetActionDefinition(
      action: PetBehaviorAction.freezeWeightShift,
      category: PetBehaviorCategory.caution,
      animationKey: 'freeze_weight_shift',
    ),
    PetBehaviorAction.retreatLookback: PetActionDefinition(
      action: PetBehaviorAction.retreatLookback,
      category: PetBehaviorCategory.avoid,
      animationKey: 'retreat_lookback',
    ),
    PetBehaviorAction.nosePawBump: PetActionDefinition(
      action: PetBehaviorAction.nosePawBump,
      category: PetBehaviorCategory.engage,
      animationKey: 'nose_paw_bump',
    ),
    PetBehaviorAction.approachLowSilent: PetActionDefinition(
      action: PetBehaviorAction.approachLowSilent,
      category: PetBehaviorCategory.approach,
      animationKey: 'approach_low_silent',
    ),
    PetBehaviorAction.approachPauseRetreat: PetActionDefinition(
      action: PetBehaviorAction.approachPauseRetreat,
      category: PetBehaviorCategory.approach,
      animationKey: 'approach_pause_retreat',
    ),
    PetBehaviorAction.sniffWhiskerScan: PetActionDefinition(
      action: PetBehaviorAction.sniffWhiskerScan,
      category: PetBehaviorCategory.investigate,
      animationKey: 'sniff_whisker_scan',
    ),
    PetBehaviorAction.pawTest: PetActionDefinition(
      action: PetBehaviorAction.pawTest,
      category: PetBehaviorCategory.investigate,
      animationKey: 'paw_test',
    ),
    PetBehaviorAction.orientEarsTail: PetActionDefinition(
      action: PetBehaviorAction.orientEarsTail,
      category: PetBehaviorCategory.evaluate,
      animationKey: 'orient_ears_tail',
    ),
    PetBehaviorAction.stareCrouch: PetActionDefinition(
      action: PetBehaviorAction.stareCrouch,
      category: PetBehaviorCategory.caution,
      animationKey: 'stare_crouch',
    ),
    PetBehaviorAction.hidePeek: PetActionDefinition(
      action: PetBehaviorAction.hidePeek,
      category: PetBehaviorCategory.avoid,
      animationKey: 'hide_peek',
    ),
    PetBehaviorAction.batPounce: PetActionDefinition(
      action: PetBehaviorAction.batPounce,
      category: PetBehaviorCategory.engage,
      animationKey: 'bat_pounce',
    ),
    PetBehaviorAction.approachSideways: PetActionDefinition(
      action: PetBehaviorAction.approachSideways,
      category: PetBehaviorCategory.approach,
      animationKey: 'approach_sideways',
    ),
    PetBehaviorAction.leanForwardPause: PetActionDefinition(
      action: PetBehaviorAction.leanForwardPause,
      category: PetBehaviorCategory.approach,
      animationKey: 'lean_forward_pause',
    ),
    PetBehaviorAction.headTiltEyeFocus: PetActionDefinition(
      action: PetBehaviorAction.headTiltEyeFocus,
      category: PetBehaviorCategory.investigate,
      animationKey: 'head_tilt_eye_focus',
    ),
    PetBehaviorAction.beakProbe: PetActionDefinition(
      action: PetBehaviorAction.beakProbe,
      category: PetBehaviorCategory.investigate,
      animationKey: 'beak_probe',
    ),
    PetBehaviorAction.crestBodyScan: PetActionDefinition(
      action: PetBehaviorAction.crestBodyScan,
      category: PetBehaviorCategory.evaluate,
      animationKey: 'crest_body_scan',
    ),
    PetBehaviorAction.freezeGrip: PetActionDefinition(
      action: PetBehaviorAction.freezeGrip,
      category: PetBehaviorCategory.caution,
      animationKey: 'freeze_grip',
    ),
    PetBehaviorAction.flyBack: PetActionDefinition(
      action: PetBehaviorAction.flyBack,
      category: PetBehaviorCategory.avoid,
      animationKey: 'fly_back',
    ),
    PetBehaviorAction.beakManipulate: PetActionDefinition(
      action: PetBehaviorAction.beakManipulate,
      category: PetBehaviorCategory.engage,
      animationKey: 'beak_manipulate',
    ),
  };

  static const novelObjectTriggers = <PetBehaviorTrigger>[
    PetBehaviorTrigger(
      stimulus: PetStimulusType.newMessageBubble,
      action: PetBehaviorAction.approachArc,
      petType: PetType.corgi,
      priority: 10,
    ),
    PetBehaviorTrigger(
      stimulus: PetStimulusType.newMessageBubble,
      action: PetBehaviorAction.approachLowSilent,
      petType: PetType.cat,
      priority: 10,
    ),
    PetBehaviorTrigger(
      stimulus: PetStimulusType.newMessageBubble,
      action: PetBehaviorAction.approachSideways,
      petType: PetType.parrot,
      priority: 10,
    ),
  ];
}
