package ci

import (
    "dagger.io/dagger"
    "dagger.io/dagger/core"
)

dagger.#Plan & {
  // Retrieve source from current directory
  // Input
  client: filesystem: ".": read: {
    contents: dagger.#FS
    // Include only content we need to generate our protobuf code
    include: ["api.proto"]
  }

  // Output
  client: filesystem: "./dagger": write: contents: actions.proto.data.output

  actions: {
    // Alias on source
    _source: client.filesystem.".".read.contents

    image: core.#Pull & {
      source: "namely/protoc-all:1.29_4"
    }

    // Generate protobuf code
    proto: {
      exec: core.#Exec & {
    	input: image.output
        mounts: secret: {
    		dest:     "/defs/protos"
    		contents: _source
    	}
    	args: ["entrypoint.sh", "-f", "protos/api.proto", "-l", "go"]
        workdir: "/defs"
      }

      data: core.#Copy & {
        input:    dagger.#Scratch
        contents: exec.output
        source:   "/defs/gen/pb-go"
      }
    }
  }
}
