# MISP Integration test image

Let's say you make a lovely project that you're very proud of, that makes
use of MISP's API. And then you think to yourself "hm now I should probably
set up automated tests to make sure I don't break it".

Great idea. But there's a problem. You can't test against any MISP instance without
leaking API credentials, or setting up a deliberately insecure instance. Oh no.

That's where this image comes in. It's an all-in-one docker container meant to
act as a sidecar to your test environment.

## Usage

### Gitlab

```yaml
test:
  services:
  - koroshitekure/misp-testable 
```

### Travis
