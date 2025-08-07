class PitchResult {
  final String note;

  final int midiNote;

  ///The expected frequency of the closest note.
  final double expectedFrequency;

  /// The difference of the frequency found in the analised pitch compared to the expected pitch of the closest note.
  final double diffFrequency;

  /// The interval difference in cents to the expected closest tuned note.
  final double diffCents;

  PitchResult(
      this.note,
      this.midiNote,
      this.expectedFrequency,
      this.diffFrequency,
      this.diffCents,
      );
}
