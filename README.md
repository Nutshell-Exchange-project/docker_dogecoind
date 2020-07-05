# docker_doged
Doge Coin [DOGE] docker image source with Docker Composer file attached

If you need other than 1.14.2 linux x64 version, you need to replace version number in build command:


```
docker build --build-arg VERSION=2.7.2 -t realnuts/docker_dogecoind:tagname .
```

###
**IMPORTANT**
You need to replace SHA256 archive checksum if you replace version number in `checksum.sha256` file or your build will be failed.

You can obtain actual checksum by linux command on downloaded wallet archive:
```
sha256sum dogecoin-1.14.2-x86_64-linux-gnu.tar.gz
```

Result of this command will looks like this:
```
10c400c8f2039b1f804b8a533266201a9e4e3b32a8854501e8a43792e1ee78e6  dogecoin-1.14.2-x86_64-linux-gnu.tar.gz
```
Replace first block of this string in `checksum.sha256` file and save it.
