import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/avatar_widget.dart';

class AvatarSelectionScreen extends StatefulWidget {
  final bool isEditMode;

  const AvatarSelectionScreen({
    super.key,
    this.isEditMode = false,
  });

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  String _selectedAvatar = 'avatar_developer';

  @override
  void initState() {
    super.initState();
    // Pre-fill with current profile image if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.profileImageUrl.isNotEmpty) {
        setState(() {
          _selectedAvatar = authProvider.profileImageUrl;
        });
      }
    });
  }



  void _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfileImage(_selectedAvatar);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditMode 
                ? 'Profile picture updated successfully!' 
                : 'Welcome to TaskFlow!'),
            backgroundColor: AppTheme.primarySeedColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        if (widget.isEditMode) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, AppRouter.dashboard);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to update profile picture.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isEditMode
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: widget.isEditMode
            ? Text(
                'Change Avatar',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.isEditMode) ...[
                Text(
                  'Select Profile Picture',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose an avatar to personalize your account.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
                const SizedBox(height: 32),
              ],

              // Big Preview Container
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primarySeedColor.withValues(alpha: 0.4),
                      width: 4,
                    ),
                  ),
                  child: AvatarWidget(
                    avatarString: _selectedAvatar,
                    radius: 60,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              Text(
                'Preset Avatars',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primarySeedColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Preset Avatars Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: AvatarWidget.presets.length,
                itemBuilder: (context, index) {
                  final preset = AvatarWidget.presets[index];
                  final isSelected = _selectedAvatar == preset.id;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = preset.id;
                      });
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.primarySeedColor 
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: AvatarWidget(
                        avatarString: preset.id,
                        radius: 24,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Save button
              ElevatedButton(
                onPressed: authProvider.isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.isEditMode ? 'Update Profile Picture' : 'Save and Continue',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
