FROM golang:1.16
WORKDIR /go/src
COPY ./*.go ./
RUN go env -w GO111MODULE=auto
RUN go build *.go
EXPOSE 8080
CMD ["./main"]