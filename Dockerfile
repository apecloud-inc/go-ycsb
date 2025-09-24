FROM golang:1.18.4-alpine3.16 as builder

ARG TARGETARCH
ARG TARGETOS

ENV GOPATH /go

RUN apk update && apk upgrade && \
    apk add --no-cache git build-base wget

RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_${TARGETARCH} \
 && chmod +x /usr/local/bin/dumb-init

RUN mkdir -p /go/src/github.com/pingcap/go-ycsb
WORKDIR /go/src/github.com/pingcap/go-ycsb

COPY go.mod .
COPY go.sum .

RUN GO111MODULE=on go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} GO111MODULE=on go build -o /go-ycsb ./cmd/*

FROM alpine:3.8 as runtime

COPY --from=builder /go-ycsb /go-ycsb
COPY --from=builder /usr/local/bin/dumb-init /usr/local/bin/dumb-init

ADD workloads /workloads

EXPOSE 6060

ENTRYPOINT [ "/usr/local/bin/dumb-init", "/go-ycsb" ]
