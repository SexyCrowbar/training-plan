enum DayTheme { iron, body, recovery, rest }

class Exercise {
  final String name;
  final int sets;
  final String target;
  final int restSeconds;
  final String note;

  const Exercise({
    required this.name,
    required this.sets,
    required this.target,
    required this.restSeconds,
    required this.note,
  });
}

class Block {
  final String id;
  final String icon;
  final String name;
  final List<Exercise> exercises;

  const Block({
    required this.id,
    required this.icon,
    required this.name,
    required this.exercises,
  });
}

class Day {
  final int id;
  final DayTheme theme;
  final String name;
  final String tag;
  final int gtgTarget;
  final String gtgEx;
  final List<Block> blocks;

  const Day({
    required this.id,
    required this.theme,
    required this.name,
    required this.tag,
    required this.gtgTarget,
    required this.gtgEx,
    required this.blocks,
  });

  bool get isRestDay => theme == DayTheme.rest;
}

const List<String> kBlockIds = ['warmup', 'power', 'hypertrophy', 'endurance'];
const Map<String, String> kBlockIcons = {
  'warmup': '🌅',
  'power': '⚡',
  'hypertrophy': '💪',
  'endurance': '🔥',
};
const Map<String, String> kBlockNames = {
  'warmup': 'Morning Prep',
  'power': 'Morning Power',
  'hypertrophy': 'Afternoon Hypertrophy',
  'endurance': 'Evening Endurance',
};
