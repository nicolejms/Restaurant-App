FROM --platform=$BUILDPLATFORM golang:1.22-alpine AS build

ARG TARGETARCH
ARG TARGETOS

WORKDIR /src
COPY go.mod main.go ./
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /realm-init ./main.go

FROM alpine:3.20

COPY --from=build /realm-init /usr/local/bin/realm-init
COPY realm.json /template/realm.json

ENTRYPOINT ["/usr/local/bin/realm-init"]
