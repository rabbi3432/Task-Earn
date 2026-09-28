# Task Earn

Flutter Android MVP for the Bangladesh-focused Task Earn app.

## Current authentication flow

- New user enters name, Bangladesh mobile number and email.
- App sends a 6-digit email OTP.
- User enters the OTP inside the app.
- Successful OTP verification creates the authenticated session and saves the profile.
- No password is required.
- Login also uses email OTP.

## Supabase email OTP setup

Supabase email OTP uses the Magic Link email template. In the Supabase Dashboard, open **Authentication → Email Templates → Magic Link** and make the template contain the OTP token variable:

```html
<h2>Task Earn verification code</h2>
<p>Your one-time verification code is: {{ .Token }}</p>
<p>This code expires according to your Supabase Auth OTP expiration setting.</p>
```

Do not use `{{ .ConfirmationURL }}` as the primary verification method for this app.

## Backend

Supabase project: `task-earn`

Existing protected tables:

- `profiles`
- `verification_requests`

RLS is enabled for both tables and users can only access their own rows.

## Android build

GitHub Actions builds a debug APK on every push to `main`.

Artifact name:

`task-earn-debug-apk`
