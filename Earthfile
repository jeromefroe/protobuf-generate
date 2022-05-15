# https://github.com/earthly/earthly/tree/main/examples/readme/proto
VERSION 0.6

proto:
  FROM namely/protoc-all:1.29_4
  COPY api.proto /defs
  RUN --entrypoint -- -f api.proto -l go
  SAVE ARTIFACT ./gen/pb-go /pb AS LOCAL earthly
