import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null || !mounted) {
        return;
      }

      final AuthProvider authProvider = context.read<AuthProvider>();
      final bool success = await authProvider.updateProfileImage(image.path);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile photo updated successfully.'
                : authProvider.errorMessage ??
                    'Unable to update your profile photo.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final FavoritesProvider favoritesProvider =
        context.watch<FavoritesProvider>();
    final RestaurantProvider restaurantProvider =
        context.watch<RestaurantProvider>();
    final user = authProvider.currentUser;
    final bool hasProfileImage =
        user != null && user.profileImagePath.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: const Color(0xFFDDF4E8),
                      backgroundImage: hasProfileImage
                          ? FileImage(File(user.profileImagePath))
                          : null,
                      child: hasProfileImage
                          ? null
                          : Text(
                              user?.name.substring(0, 1).toUpperCase() ?? 'U',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: const Color(0xFF14532D),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: authProvider.isLoading ? null : _pickProfileImage,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF97316),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: authProvider.isLoading ? null : _pickProfileImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Change Profile Photo'),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.name ?? 'Guest',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _ProfileStatCard(
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFDC2626),
          title: 'Saved favorites',
          value: '${favoritesProvider.favoriteRestaurants.length}',
        ),
        const SizedBox(height: 14),
        _ProfileStatCard(
          icon: Icons.add_business_rounded,
          iconColor: const Color(0xFF14532D),
          title: 'Places you shared',
          value: '${restaurantProvider.myPlaces.length}',
        ),
        const SizedBox(height: 24),
        Text(
          'Your shared places',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        if (restaurantProvider.myPlaces.isEmpty)
          const Text(
            'You have not shared any community picks yet.',
          )
        else
          ...restaurantProvider.myPlaces.map(
            (restaurant) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('- ${restaurant.name}'),
            ),
          ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Logout',
          icon: Icons.logout_rounded,
          isLoading: authProvider.isLoading,
          onPressed: () async {
            await context.read<AuthProvider>().logout();
            if (!context.mounted) {
              return;
            }
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ],
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: <Widget>[
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF14532D),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
