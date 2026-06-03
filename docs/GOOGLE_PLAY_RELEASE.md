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

Important details:

- The service account email in Play Console must match the `client_email` value
  from the JSON key stored in `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`.
- Prefer granting access from **Setup > API access** after the Cloud project is
  linked. Inviting the same service account from **Users and permissions** can
  also work, but the API access page is the easiest place to verify that Play
  Console recognizes the account as an API user.
- Scope access to this app only: `io.biatec.math_master`.
- The built-in **Release manager** role is usually enough. **Admin** also works,
   but is broader than needed.

The exact permission labels in Play Console can change, but the account must be
able to upload Android App Bundles and release them to the internal testing
track.

For a custom role, grant permissions equivalent to:

- View app information.
- Create and edit releases.
- Release to testing tracks.
- Manage testing tracks, if Play Console shows this as a separate permission.

If Google Play shows app-level permissions, apply those permissions to
`io.biatec.math_master`, not only at account level.

You do not need to give this service account special Google Cloud IAM roles such
as Owner, Editor, or Service Account Admin just for Play uploads. On the Cloud
Console side, the required setup is:

- The linked Cloud project exists.
- The **Google Play Android Developer API** is enabled in that project.
- The service account exists in that project.
- The JSON key used in GitHub belongs to that same service account.

The permission to create Play releases is controlled by **Play Console**, not by
Google Cloud IAM.

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
| `The caller does not have permission`                  | Check the permission checklist below.                                                 |
| `Package not found` or wrong package name              | Confirm the app exists in Play Console with package `io.biatec.math_master`.          |
| Upload succeeds but testers do not see the app         | Check the internal tester list and make sure testers accepted the opt-in invitation.  |
| Play Console says setup or declarations are incomplete | Finish the required Play Console app setup forms and rerun the release workflow.      |

For `The caller does not have permission`, check these in order:

1. Open the GitHub secret value locally or in your password manager and confirm
   the JSON `client_email` is the same service account email you granted in Play
   Console.
2. In **Play Console > Setup > API access**, confirm the linked Cloud project is
   the project where that service account was created.
3. In **Play Console > Setup > API access**, confirm the service account shows
   as granted access. If it only exists in Cloud Console, grant access in Play
   Console too.
4. In **Play Console > Users and permissions**, open the service account user
   and confirm it has access to app `io.biatec.math_master`.
5. Confirm the app permission includes release creation for internal testing,
   or temporarily use **Admin** to prove the permission issue is solved.
6. Wait a few minutes after changing Play Console permissions, then rerun the
   workflow. Play API permissions can take a short time to propagate.