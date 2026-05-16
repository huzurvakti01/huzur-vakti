# Huzur Vakti Logo Integration

## Mobile Assets

```text
mobile_app/assets/images/logo_main.png
mobile_app/assets/images/logo_white.png
mobile_app/assets/images/app_icon.png
mobile_app/assets/images/splash_logo.png
```

## Admin Assets

```text
admin_panel/assets/images/logo_main.png
admin_panel/assets/images/logo_white.png
admin_panel/assets/images/app_icon.png
admin_panel/assets/images/splash_logo.png
```

## Mobile pubspec.yaml

Configured:

- `flutter_native_splash`
- `flutter_launcher_icons`
- `assets/images/`

Splash:

- Dark navy background: `#06111F`
- Image: `assets/images/splash_logo.png`

Launcher icon:

- Image: `assets/images/app_icon.png`
- Adaptive background: `#052F26`

## Placement

Mobile:

- `smart_setup_screen.dart`
- `auth_screen.dart`

Admin:

- `app_shell.dart` NavigationRail leading
- `login_screen.dart`
