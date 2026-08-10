/// Pure helper to compute age from a [dateOfBirth].
///
/// This is the single source of truth for age calculation throughout the
/// app.  When Supabase integration is added, `date_of_birth` will be the
/// canonical stored field and this function will be the only place that
/// derives age from it.
int calculateAge(DateTime dateOfBirth) {
  final now = DateTime.now();
  int age = now.year - dateOfBirth.year;
  if (now.month < dateOfBirth.month ||
      (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
    age--;
  }
  return age;
}
