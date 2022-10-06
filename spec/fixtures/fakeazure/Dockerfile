FROM golang:1.19-alpine3.16 as builder

WORKDIR /data
COPY . .
RUN CGO_ENABLED=0 go build -o fakeazure

FROM alpine:3.16

RUN addgroup -S fakeazure && adduser -S fakeazure -G fakeazure && \
    apk update && apk --no-cache add curl
COPY --from=builder /data/fakeazure /usr/local/bin/fakeazure

ENTRYPOINT [ "/usr/local/bin/fakeazure" ]
