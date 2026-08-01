import 'package:flutter_riverpod/legacy.dart';
import '../../../models/user_profile.dart';
import '../../../models/mock_data.dart';

final userProfileProvider = StateProvider<UserProfile>((ref) => demoProfile);
