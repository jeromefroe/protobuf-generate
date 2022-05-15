# Protobuf Generator

This repo contains examples of how to generate code from a Protobuf file using three different
tools: Earthly, Dagger, and Bazel. The repo also looks at how each tool supports caching to speed
up repeated invocations when the input files don't change.

## Earthly

To generate the protobuf code using `earthly` running the following command:

```bash
earthly +proto
```

### Shared Cache

Earthly has the ability to share cache between different isolated CI runs and even with developers
([documentation][1]). It supports two different kinds of caching: inline and explicit. The two are
similiar but the key difference between them is that inline caching relies on image uploads that
are already being made. For this example, since we're just creating a local artifact. we need to
use explicit caching.

#### Explicit Caching Example

Earthly provides a [Compatibility matrix for major registry providers][2]. In order to use GCP,
we need to use Google Artifact Registry instead of Google Container Registry, since only the former
can be used for explicit caching (there is [an issue tracking support for GCR][3]).

Before we can use Google Artifact Registry as the explicit cache, we need to first configure our
Docker credentials:

```bash
gcloud auth configure-docker us-docker.pkg.dev

export REGISTRY=us-docker.pkg.dev/<GCP project>/<artifact registry>
```

To use the remote cache in read-only mode (typically used in PR builds or on a developer's
computer):

```bash
earthly --remote-cache=$REGISTRY/my-repo:proto +proto
```

To use the remote cache in read-write mode (typically in master/main branch builds):

```bash
earthly --remote-cache=$REGISTRY/my-repo:proto --push +proto
```

## Dagger

Before we can generate the protobuf code using `dagger` we need to first initialize a project:

```bash
dagger project init
dagger project update
```

Once the project has been set up, we can use `dagger` to generate the protobuf code:

```bash
dagger do proto
```

### Persistent Cache

[Dagger supports importing and exporting its cache to a registry][4]. Dagger, like Earthly, uses
Buildkit under Buildkit under the hood and is therefore able to leverage Buildkit's caching
functionality.

#### Example

One can use the `--cache-to` and `--cache-from` flags to write and read from a persistent cache
respectively:

```bash
dagger do proto \
  --cache-to type=registry,mode=max,ref=<registry target>/<image>
  --cache-from type=registry,ref=<registry target>/<image>
```

## Bazel

To generate protobuf code using Bazel, run the following command:

```bash
bazel build api_go_proto
```

Note that the generated code will be placed in the `bazel-out` directory as [Bazel doesnt let you
modify the state of your workspace (by design)][5]. This appears to make it difficult to integrate
Bazel into a Go project just to generate Protobuf Go code. It's more of an all-or-nothing approach
with Bazel it seems.

I used the documentation from the `rules-proto-grpc` repository to set up the [WORKSPACE][6] and
[BUILD][7] files.

### Remote Cache

Bazel also [has support for using a remote cache][8]. One can use the following flag to read from
and write to the remote cache:

```bash
build --remote_cache=http://your.host:port
```

[1]: https://docs.earthly.dev/docs/guides/shared-cache
[2]: https://docs.earthly.dev/docs/guides/shared-cache#compatibility-with-major-registry-providers
[3]: https://github.com/earthly/earthly/issues/1291
[4]: https://docs.dagger.io/1237/persistent-cache-with-dagger
[5]: https://stackoverflow.com/a/47872013/17163550
[6]: https://rules-proto-grpc.com/en/latest/index.html#installation
[7]: https://rules-proto-grpc.com/en/latest/lang/go.html#go-proto-compile
[8]: https://bazel.build/docs/remote-caching
