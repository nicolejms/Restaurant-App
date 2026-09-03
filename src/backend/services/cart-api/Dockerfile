#build stage
FROM --platform=$BUILDPLATFORM golang:1.22-alpine AS builder

ARG TARGETARCH
ARG TARGETOS

RUN apk add --no-cache git

WORKDIR /src
COPY ./go.mod ./go.sum ./

ENV GOPROXY=https://proxy.golang.org
ENV GOSUMDB=sum.golang.org
ENV GO111MODULE=on
RUN go mod download

COPY ./ ./

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -installsuffix 'static' -o cart-api cmd/api/main.go
RUN CGO_ENABLED=0 go test -c ./internal/handlers -o handlers.test -cover

FROM --platform=$BUILDPLATFORM alpine:3.20 AS certificates
RUN apk --no-cache add ca-certificates

#final stage
FROM alpine:3.20

COPY --from=certificates /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /src/cart-api ./
CMD ["./cart-api"] 
LABEL Name=cart-api Version=0.0.1
EXPOSE 5200
ENV PORT 5200
