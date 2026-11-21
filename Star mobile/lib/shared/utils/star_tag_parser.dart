class StarTagParseResult {
  const StarTagParseResult({
    required this.username,
    required this.discriminator,
  });

  final String username;
  final String discriminator;
}

final RegExp _zeroDiscriminatorInput = RegExp(r'^0{1,4}$');

StarTagParseResult parseStarTagInput(
  String input, {
  bool uniqueUsernames = false,
}) {
  final parts = input.split('#');
  if (parts.length > 1) {
    final String discriminator = parts.sublist(1).join('#');
    return StarTagParseResult(
      username: parts.first,
      discriminator:
          uniqueUsernames && _zeroDiscriminatorInput.hasMatch(discriminator)
          ? '0000'
          : discriminator,
    );
  }
  return StarTagParseResult(username: input, discriminator: '0000');
}

bool isValidStarTagDiscriminator(String discriminator) {
  return RegExp(r'^\d{4}$').hasMatch(discriminator);
}

bool isValidStarTagSubmission(String username, String discriminator) {
  return username.trim().isNotEmpty &&
      isValidStarTagDiscriminator(discriminator);
}
