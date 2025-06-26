After cloning, run the following to get the (~300 MiB) `mc-data` submodule:

```sh
git submodule update --init --progress
```

To build, run `dub build` or `dub build --release-debug --compiler=ldc`.
Finally, run `./mc`.

Currently supports only the mc 1.21.4 client.
