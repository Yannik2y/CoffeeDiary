# Fastlane for Coffee Diary

See [docs/release.md](../docs/release.md) for the full Xcode Cloud + Fastlane release flow.

```bash
cp .env.example .env   # fill ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH
bundle install
bundle exec fastlane metadata   # metadata only
bundle exec fastlane release    # metadata + submit for review
```
