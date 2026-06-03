# Google Play Internal Testing Release

This guide explains how to let GitHub Actions upload the signed Android App
Bundle to Google Play and create a release on the **Internal testing** track.

The Android package name used by the release workflow is
`io.biatec.math_master`.

The release workflow is [`.github/workflows/release.yml`](../.github/workflows/release.yml).
It builds the signed `.aab`, verifies the package/version metadata, verifies the
bundle is not signed with the Android debug key, and uploads it to Google Play.

---

## 1. Prerequisites in Play Console

Before the GitHub workflow can upload releases, the app must exist in the
Google Play Console:

1. Open the **Google Play Console**.
2. Create or open the app with package name `io.biatec.math_master`.
3. Complete the required app setup items that Google requires before releases
   can be rolled out, such as app access, ads, content rating, target audience,
   data safety, store listing, and app category.
4. Open **Testing > Internal testing**.
5. Create or select an internal tester list and add the tester email addresses
   or Google Group that should receive internal builds.

GitHub Actions can create the internal testing release, but it cannot complete
the Play Console policy declarations for you.

---

## 2. Create Play Console API access

You need a Google service account that has permission to upload releases for
this app.

1. In the **Google Play Console**, open **Setup > API access**.
2. Link a Google Cloud project if one is not linked yet.
3. Make sure the **Google Play Android Developer API** is enabled for the linked
   Google Cloud project.
4. In **Service accounts**, choose **Create new service account**.
5. Follow the link to Google Cloud IAM and create the service account.
6. After it is created, return to **Play Console > Setup > API access** and
   grant the service account access to the Play Console.

Recommended access:

- Scope access to this app only: `io.biatec.math_master`.
- Use the built-in **Release manager** role, or a custom role that can view app
  information and create releases on testing tracks.

The exact permission labels in Play Console can change, but the account must be
able to upload Android App Bundles and release them to the internal testing
track.

---

## 3. Create the service account JSON key

In the linked Google Cloud project:

1. Open **IAM & Admin > Service Accounts**.
2. Select the service account used for Play Console uploads.
3. Open **Keys > Add key > Create new key**.
4. Choose **JSON** and create the key.
5. Download the `.json` file.

Treat this JSON file like a password. Do not commit it to git and do not share
it outside the release setup.

---

## 4. Add the GitHub secret

Open the GitHub repository and go to **Settings > Secrets and variables >
Actions > New repository secret**.

Create this secret:

| Secret name                        | Value                                      |
| ---------------------------------- | ------------------------------------------ |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | The entire contents of the JSON key file   |

Paste the full JSON document, including the opening `{` and closing `}`.

The release workflow also needs the Android signing secrets documented in
[Android Production Signing & Release](ANDROID_SIGNING.md):

| Secret name                 | Purpose                                  |
| --------------------------- | ---------------------------------------- |
| `ANDROID_KEYSTORE_BASE64`   | Base64-encoded upload keystore           |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password                        |
| `ANDROID_KEY_PASSWORD`      | Key password                             |
| `ANDROID_KEY_ALIAS`         | Keystore alias                           |

---

## 5. Run a release

Push a semantic version tag:

```bash
git tag v1.0.15
git push origin v1.0.15
```

The workflow derives:

- version name: `1.0.15`
- version code: `10015`

When the workflow succeeds, the release is uploaded to **Internal testing** in
the Google Play Console. The workflow also stores the signed `.aab` as a GitHub
Actions artifact named like `math-masters-1.0.15-signed-aab`.

You can also start the workflow manually from **GitHub > Actions > Release
(Google Play Internal Testing) > Run workflow**. Manual runs use the latest git
tag available in the repository.

---

## Troubleshooting

| Symptom                                                | Fix                                                                                  |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------ |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON secret is not set`   | Add the repository secret from step 4.                                                |
| `The caller does not have permission`                  | Grant the service account app access in Play Console API access.                      |
| `Package not found` or wrong package name              | Confirm the app exists in Play Console with package `io.biatec.math_master`.          |
| Upload succeeds but testers do not see the app         | Check the internal tester list and make sure testers accepted the opt-in invitation.  |
| Play Console says setup or declarations are incomplete | Finish the required Play Console app setup forms and rerun the release workflow.      |