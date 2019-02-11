# MISP Integration test image

Let's say you make a lovely project that you're very proud of, that makes
use of MISP's API. And then you think to yourself "hm now I should probably
set up automated tests to make sure I don't break it".

Great idea. But there's a problem. You can't test against any MISP instance without
leaking API credentials, or setting up a deliberately insecure instance. Oh no.

That's where this image comes in. It's an all-in-one docker container meant to
act as a sidecar to your test environment.

## Credentials

The API key for an admin user is `testmispapikeytestmispapikeytestmispapik`

I apologise for it being so long but it has to be 40 alphanumeric for MISP to pick
it up as valid

## Usage

### Gitlab

```yaml
test:
  services:
  - floatingghost/misp-testable 
```

### Travis

```yaml
services:
- floatingghost/misp-testable
```

## Disclaimer

I shouldn't even need to include one, but let's be safe

This is a deliberately insecure image for use within CI/CD pipelines and other
integration-test environments ONLY, do *not* use it for anything permanent.
