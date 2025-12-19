class Player {
  final String name;
  final String number;
  final String role; // e.g., Forward, Midfielder
  final String age;
  final String country;
  final String position; // e.g., RW, CAM
  final String imagePath; // Path to the asset image

  // --- Attack Stats ---
  final int totalShots;
  final int shotsOnTarget;
  final int goalsScored;
  final int leftFootGoals;
  final int rightFootGoals;
  final int headedGoals;
  final int otherGoals;
  final int goalsInsideBox;
  final int goalsOutsideBox;
  final int directFreeKickGoals;

  Player({
    required this.name,
    required this.number,
    required this.role,
    required this.age,
    required this.country,
    required this.position,
    required this.imagePath,
    required this.totalShots,
    required this.shotsOnTarget,
    required this.goalsScored,
    required this.leftFootGoals,
    required this.rightFootGoals,
    required this.headedGoals,
    required this.otherGoals,
    required this.goalsInsideBox,
    required this.goalsOutsideBox,
    required this.directFreeKickGoals,
  });
}