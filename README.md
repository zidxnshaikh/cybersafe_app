# CyberSafe

CyberSafe is a Flutter mobile app for cyber-security awareness and scam detection. It helps users:

- paste suspicious SMS or chat messages to run a local scam-risk assessment
- test password strength
- practice spotting scam scenarios
- access emergency guidance for suspected cyber fraud
- optionally verify a suspicious message or URL using Google Gemini
- check links against Google Safe Browsing and a small built-in official-domain list
- copy a report containing the submitted content, local risk score, detected indicators, recommendations, and AI assessment

## Configure AI verification for local development

Use your own API keys; never share them or commit them to Git. If you do not already have a local config file, copy the example with `Copy-Item local_secrets.example.json local_secrets.json`. Replace the Gemini placeholder in your local `local_secrets.json`. For threat reputation checks, create a Google Cloud API key with the [Safe Browsing API](https://developers.google.com/safe-browsing/v4/get-started) enabled, then set its value under `SAFE_BROWSING_API_KEY` in the same local file. Restrict the key to the Safe Browsing API where Google Cloud permits it. Run:

```powershell
flutter run -d emulator-5554 --dart-define-from-file=local_secrets.json
```

`local_secrets.json` is ignored by Git; never commit it. The key is compiled into the app binary and can be extracted from it, so this direct-client setup is for a private demo only—not a production or publicly distributed app. A production app should call a backend that keeps the key server-side.

The app currently calls the `gemini-3.8-flash` model. Check your Google AI Studio account for available models and free-tier limits. Without the Gemini key, the local pattern scan and report still work; the Gemini verification button is disabled.

The **Check link reputation** button compares hosts against a small, editable list of known official domains and, when `SAFE_BROWSING_API_KEY` is set, checks URLs against Google Safe Browsing's threat lists. Add only domains you have independently verified to `LinkVerificationService`. An official-domain match describes the hostname only; it does not certify a page, and a Safe Browsing no-match is not proof of safety. Unknown hosts are reported as **Not verified**.

Gemini's confidence value is the model's own confidence in its chosen label, not a calibrated probability that a URL is safe or genuine. The app does not browse to a URL or independently verify domain ownership. Treat uncertain or unverified URLs as suspicious and confirm them through an official channel.

## Run the app

```bash
flutter pub get
flutter run -d emulator-5554 --dart-define-from-file=local_secrets.json
```
