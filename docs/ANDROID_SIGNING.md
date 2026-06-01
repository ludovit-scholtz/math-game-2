# Android Production Signing & Release

This guide explains how to create an upload signing key for **Math Master**, store
it securely in GitHub repository secrets, and produce a Google Play–signed
Android App Bundle (`.aab`) via the CI/CD pipeline.

The Android application ID used for Play Console uploads is
`io.biatec.math_master`.

> **Why this is needed:** Google Play rejects bundles signed with the Android
> *debug* key ("the app was not signed for production release"). The release
> build must be signed with your own *upload key*. The
> [`.github/workflows/release.yml`](../.github/workflows/release.yml) workflow
> does this automatically once the secrets below are configured.

---

## 1. Create an upload keystore

You only do this **once**. Keep the resulting file and passwords safe — if you
lose them you cannot publish updates with the same key (unless you enrolled in
Play App Signing key reset).

Run locally (requires a JDK, which ships with Flutter/Android Studio):

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

You will be prompted for:

- **Keystore password** → this becomes `ANDROID_KEYSTORE_PASSWORD`.
- **Key password** → this becomes `ANDROID_KEY_PASSWORD` (you can press Enter to
  reuse the keystore password).
- Name / organization details (any reasonable values).

The `-alias upload` value becomes `ANDROID_KEY_ALIAS`.

> Store `upload-keystore.jks` and both passwords in a password manager. **Never
> commit the keystore or passwords to git** — they are already covered by
> [`.gitignore`](../.gitignore).

---

## 2. Base64-encode the keystore

GitHub secrets store text, so the binary keystore must be base64-encoded.

**Windows (PowerShell):**

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```

The encoded string is now on your clipboard.

**macOS / Linux:**

```bash
base64 -w0 upload-keystore.jks    # Linux
base64 -b0 upload-keystore.jks    # macOS
```

Copy the entire single-line output.

---

## 3. Add the secrets to GitHub

In the repository, go to **Settings → Secrets and variables → Actions → New
repository secret** and create the following four secrets:

| Secret name                 | Value                                              |
| --------------------------- | -------------------------------------------------- |
| `ANDROID_KEYSTORE_BASE64`   | The base64 string from step 2                      |
| `ANDROID_KEYSTORE_PASSWORD` | The keystore (store) password from step 1          |
| `ANDROID_KEY_PASSWORD`      | The key password from step 1                       |
| `ANDROID_KEY_ALIAS`         | The alias from step 1 (`upload` in the example)    |

---

## 4. Build a signed bundle via CI

The release workflow runs when you push a version tag or trigger it manually.

**Option A — push a tag (recommended):**

```bash
git tag v1.0.0
git push origin v1.0.0
```

**Option B — manual run:** open the **Actions** tab → **Release (Signed AAB)** →
**Run workflow**.

When the run finishes, download the **`math-masters-signed-aab`** artifact. It
contains `app-release.aab`, signed with your upload key and ready to upload to
the Google Play Console.

The workflow also patches the generated Android Gradle file so the regenerated
`android/` folder reads `android/key.properties` and uses your upload keystore
for the release build. It then runs a verification step that **fails the
build** if the bundle is still signed with the debug key, so a mis-configured
secret cannot silently produce an unpublishable bundle.

---

## 5. Build a signed bundle locally (optional)

To reproduce the signed build on your machine:

1. Place `upload-keystore.jks` in `android/app/`.
2. Create `android/key.properties` (already git-ignored):

   ```properties
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```

3. Build:

   ```bash
   flutter build appbundle --release
   ```

If you regenerated `android/` with `flutter create .`, make sure
`android/app/build.gradle.kts` has a release signing config that reads
`android/key.properties`. The stock Flutter template signs release builds with
the debug key until you replace that block.

The output is at `build/app/outputs/bundle/release/app-release.aab`.

> If `key.properties` is **absent**, the release build falls back to the debug
> key so `flutter run --release` still works for local testing. Such a bundle
> **cannot** be published to Google Play.

---

## 6. Play App Signing (Google-managed key)

When you first upload to the Play Console, enroll in **Play App Signing**.
Google then re-signs your app with a key it manages, while your *upload key*
(created above) is only used to authenticate uploads. This means:

- If your upload key is ever compromised, you can request a reset.
- Keep using the same upload key for every release to the same app.

---

## Troubleshooting

| Symptom                                              | Fix                                                                                   |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------- |
| "App was not signed for production release"          | A debug-signed bundle was uploaded. Use the CI artifact or a local `key.properties`.  |
| CI fails at "Decode keystore"                        | `ANDROID_KEYSTORE_BASE64` secret is missing or malformed. Re-do steps 2–3.            |
| CI verify step says "signed with the debug key"      | One of the four secrets is wrong; confirm alias and passwords match the keystore.     |
| `keytool: command not found`                         | Use the JDK bundled with Android Studio, or install a JDK 17.                          |
