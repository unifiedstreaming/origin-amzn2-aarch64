# Repo for testing amzn2-aarch64 container build

http://issue.unified-streaming.com/issues/8785
 
## Standard Practice

```bash
docker build . -t amzn2-aarch64 --no-cache && \
docker run --rm -it \
 --name origin-amzn2-aarch64 \
 -e USP_LICENSE_KEY \
 -e REMOTE_STORAGE_URL=https://usp-s3-storage.s3.eu-central-1.amazonaws.com/ \
 -e LOG_LEVEL=debug \
 amzn2-aarch64
```
