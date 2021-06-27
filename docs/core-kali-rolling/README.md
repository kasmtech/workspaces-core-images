# About This Image

This image contains a browser-accessible version of Kali Linux. It comes pre-installed with the kali-linux-default Metapage

Because many kali tools require root privileges, users may desire to run this image as root by passing the `--user root` flag to `docker run`.
When using the image within Kasm Workspaces, configure the **Docker Run Config Override** setting within the Image definition to add the following JSON:

```
{"user":"root"}
```

![Screenshot][Image_Screenshot]

[Image_Screenshot]: https://f.hubspotusercontent30.net/hubfs/5856039/dockerhub/image-screenshots/core-kali-rolling.png "Image Screenshot"